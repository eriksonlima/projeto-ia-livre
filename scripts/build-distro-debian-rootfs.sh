#!/usr/bin/env bash
# Etapa 82 / B77 — rootfs Debian mínimo + overlay distro/ (≠ Alpine).
# Prefer mmdebstrap no host; senão Docker+mmdebstrap; senão skip need_*.
set -euo pipefail
cd "$(dirname "$0")/.."

REPO="$(pwd)"
OUT="$REPO/build/distro-debian"
ROOTFS="$OUT/rootfs"
SUITE="${IA_LIVRE_DEBIAN_SUITE:-bookworm}"
MARKER_OK="IA_LIVRE_DISTRO_DEBIAN_ROOTFS_OK"

mkdir -p "$OUT"

have_mmdebstrap() { command -v mmdebstrap >/dev/null 2>&1; }
have_docker() { command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; }

if ! have_mmdebstrap && ! have_docker; then
  echo "IA_LIVRE_DISTRO_DEBIAN_SKIP=need_mmdebstrap"
  exit 0
fi

echo "stage: overlay (binários)…"
./scripts/stage-distro-overlay.sh

OVERLAY_ABS="$(cd distro/overlay && pwd)"
rm -rf "$ROOTFS"
mkdir -p "$ROOTFS"

# libgomp1: runtime llama.cpp; nano/vim-tiny: editar conf no TTY;
# iw/wpasupplicant/rfkill/isc-dhcp-client: Wi-Fi mínimo; firmware-* : chips comuns
INCLUDES="linux-image-amd64,systemd-sysv,util-linux,udev,dbus,login,iproute2,ca-certificates,initramfs-tools,sudo,passwd,adduser,curl,libgomp1,nano,vim-tiny,iw,wpasupplicant,rfkill,isc-dhcp-client,wireless-regdb,firmware-linux-free,firmware-iwlwifi,firmware-realtek,firmware-atheros,firmware-brcm80211,firmware-misc-nonfree"

# Credenciais live (TTY físico) — root Debian minbase vem bloqueado
IA_USER="${IA_LIVRE_LIVE_USER:-ialivre}"
IA_PASS="${IA_LIVRE_LIVE_PASS:-ialivre}"

# Script de pós-instalação (arquivos; usuários via chroot depois)
write_customize() {
  local dest="$1"
  cat >"$dest" <<'CUST'
#!/bin/bash
set -euo pipefail
R="${1:-/}"
mkdir -p "$R/usr/local/bin" "$R/etc/systemd/system" \
  "$R/etc/systemd/system/multi-user.target.wants" \
  "$R/etc/systemd/system/getty.target.wants" \
  "$R/etc/initramfs-tools" \
  "$R/etc/systemd/system/serial-getty@ttyS0.service.d" \
  "$R/etc/systemd/system/getty@tty1.service.d" \
  "$R/etc/sudoers.d"

if [[ -x "$R/opt/ia-livre/bin/ia-livre" ]]; then
  ln -sfn /opt/ia-livre/bin/ia-livre "$R/usr/local/bin/ia-livre"
  ln -sfn /opt/ia-livre/bin/ia-livre-native-tune "$R/usr/local/bin/ia-livre-native-tune" 2>/dev/null || true
  ln -sfn /opt/ia-livre/bin/ia-livre-runtime "$R/usr/local/bin/ia-livre-runtime" 2>/dev/null || true
  ln -sfn /opt/ia-livre/bin/ia-livre-agent "$R/usr/local/bin/ia-livre-agent" 2>/dev/null || true
  ln -sfn /opt/ia-livre/bin/ia-livre-node "$R/usr/local/bin/ia-livre-node" 2>/dev/null || true
  ln -sfn /opt/ia-livre/bin/ia-livre-wifi "$R/usr/local/bin/ia-livre-wifi" 2>/dev/null || true
fi

# Hostname fixo (evita ID de container Docker / live aleatório)
echo ialivre >"$R/etc/hostname"
cat >"$R/etc/hosts" <<'HOSTS'
127.0.0.1	localhost
127.0.1.1	ialivre
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
HOSTS

touch "$R/etc/initramfs-tools/modules"
for m in 9p 9pnet 9pnet_virtio virtio virtio_pci virtio_ring; do
  grep -qxF "$m" "$R/etc/initramfs-tools/modules" 2>/dev/null || echo "$m" >>"$R/etc/initramfs-tools/modules"
done

ln -sfn /lib/systemd/system/serial-getty@.service \
  "$R/etc/systemd/system/getty.target.wants/serial-getty@ttyS0.service" 2>/dev/null || true

cat >"$R/etc/systemd/system/ia-livre-boot-smoke.service" <<'UNIT'
[Unit]
Description=IA Livre boot smoke (conf)
After=local-fs.target
ConditionPathExists=/opt/ia-livre/bin/ia-livre

[Service]
Type=oneshot
ExecStart=/bin/bash -c '/usr/local/bin/ia-livre conf; echo IA_LIVRE_DISTRO_DEBIAN_GUEST_CONF_OK'
RemainAfterExit=yes
StandardOutput=journal+console
StandardError=journal+console

[Install]
WantedBy=multi-user.target
UNIT
ln -sfn /etc/systemd/system/ia-livre-boot-smoke.service \
  "$R/etc/systemd/system/multi-user.target.wants/ia-livre-boot-smoke.service"

# Autologin usuário live (tty1 físico + serial) — root minbase costuma estar locked
cat >"$R/etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf" <<'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ialivre --noclear %I $TERM
EOF
cat >"$R/etc/systemd/system/getty@tty1.service.d/autologin.conf" <<'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ialivre --noclear %I $TERM
EOF

# Script chroot para criar usuário (rodado pelo builder)
cat >"$R/tmp/ia-livre-setup-users.sh" <<'USERS'
#!/bin/bash
set -euo pipefail
U="${IA_LIVRE_LIVE_USER:-ialivre}"
P="${IA_LIVRE_LIVE_PASS:-ialivre}"
if ! id "$U" >/dev/null 2>&1; then
  useradd -m -s /bin/bash -G sudo,audio,video "$U" 2>/dev/null \
    || useradd -m -s /bin/bash "$U"
fi
echo "${U}:${P}" | chpasswd
# sudo sem senha no lab live (TTY-first)
mkdir -p /etc/sudoers.d
echo "${U} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/ia-livre-live
chmod 440 /etc/sudoers.d/ia-livre-live
# Desbloqueia root com a mesma senha (opcional login manual)
echo "root:${P}" | chpasswd || true
passwd -u root 2>/dev/null || true
echo "IA_LIVRE_LIVE_USER_OK user=${U}"
USERS
chmod +x "$R/tmp/ia-livre-setup-users.sh"
CUST
  chmod +x "$dest"
}

run_setup_users_chroot() {
  local r="$1"
  if ! have_docker; then
    echo "aviso: sem Docker — usuário live pode faltar; use docker para setup-users" >&2
    return 0
  fi
  docker run --rm --privileged \
    -v "$r:/rootfs" \
    -e IA_LIVRE_LIVE_USER="$IA_USER" \
    -e IA_LIVRE_LIVE_PASS="$IA_PASS" \
    debian:bookworm bash -c '
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
mount --bind /proc /rootfs/proc || true
mount --bind /sys /rootfs/sys || true
mount --bind /dev /rootfs/dev || true
cp /etc/resolv.conf /rootfs/etc/resolv.conf 2>/dev/null || true
chroot /rootfs apt-get update -qq >/dev/null 2>&1 || true
chroot /rootfs apt-get install -y -qq sudo passwd adduser >/dev/null 2>&1 || true
if [[ -x /rootfs/tmp/ia-livre-setup-users.sh ]]; then
  chroot /rootfs env IA_LIVRE_LIVE_USER="$IA_LIVRE_LIVE_USER" IA_LIVRE_LIVE_PASS="$IA_LIVRE_LIVE_PASS" \
    /tmp/ia-livre-setup-users.sh
fi
chroot /rootfs update-initramfs -u 2>/dev/null || chroot /rootfs /usr/sbin/update-initramfs -u 2>/dev/null || true
'
  echo "IA_LIVRE_LIVE_LOGIN=${IA_USER} / ${IA_PASS}"
}

CUST_HOST="$OUT/customize-ia-livre.sh"
write_customize "$CUST_HOST"

# firmware-* vive em non-free-firmware (Bookworm+)
MMDEBSTRAP_COMPONENTS="${IA_LIVRE_DEBIAN_COMPONENTS:-main,contrib,non-free-firmware}"

run_mmdebstrap_host() {
  echo "build: mmdebstrap host → $ROOTFS (suite=$SUITE components=$MMDEBSTRAP_COMPONENTS)"
  mmdebstrap --variant=minbase --components="$MMDEBSTRAP_COMPONENTS" \
    --include="$INCLUDES" "$SUITE" "$ROOTFS" || return 1
  cp -a "$OVERLAY_ABS"/. "$ROOTFS"/
  # customize sem chroot completo se não root: só files; initramfs via docker se disponível
  bash "$CUST_HOST" "$ROOTFS" || true
  run_setup_users_chroot "$ROOTFS" || true
}

run_mmdebstrap_docker() {
  echo "build: mmdebstrap via Docker → $ROOTFS (suite=$SUITE)"
  docker run --rm --privileged \
    -v "$OUT:/out" \
    -v "$OVERLAY_ABS:/overlay:ro" \
    -v "$CUST_HOST:/customize.sh:ro" \
    -e SUITE="$SUITE" \
    -e INCLUDES="$INCLUDES" \
    -e COMPONENTS="$MMDEBSTRAP_COMPONENTS" \
    debian:bookworm bash -c '
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq mmdebstrap ca-certificates >/dev/null
rm -rf /out/rootfs
mkdir -p /out/rootfs
mmdebstrap --variant=minbase --components="$COMPONENTS" \
  --include="$INCLUDES" "$SUITE" /out/rootfs
cp -a /overlay/. /out/rootfs/
bash /customize.sh /out/rootfs
' || return 1
  run_setup_users_chroot "$ROOTFS" || return 1
}

if have_mmdebstrap; then
  if ! run_mmdebstrap_host; then
    echo "IA_LIVRE_DISTRO_DEBIAN_SKIP=need_net"
    exit 0
  fi
elif have_docker; then
  if ! run_mmdebstrap_docker; then
    echo "IA_LIVRE_DISTRO_DEBIAN_SKIP=need_net"
    exit 0
  fi
fi

K="$(ls -1 "$ROOTFS"/boot/vmlinuz-* 2>/dev/null | head -1 || true)"
I="$(ls -1 "$ROOTFS"/boot/initrd.img-* 2>/dev/null | head -1 || true)"
if [[ -z "$K" || -z "$I" ]]; then
  echo "IA_LIVRE_DISTRO_DEBIAN_SKIP=need_kernel"
  exit 0
fi
basename "$K" >"$OUT/vmlinuz.name"
basename "$I" >"$OUT/initrd.name"

# Sanity: ia-livre presente
if [[ ! -x "$ROOTFS/opt/ia-livre/bin/ia-livre" ]]; then
  echo "erro: overlay ia-livre ausente no rootfs" >&2
  exit 1
fi
test -L "$ROOTFS/usr/local/bin/ia-livre" || test -x "$ROOTFS/usr/local/bin/ia-livre"

# First-boot (E84): artefato default **sem** GGUF (~638 MiB)
if [[ "${IA_LIVRE_DEBIAN_INCLUDE_GGUF:-0}" != "1" ]]; then
  rm -f "$ROOTFS"/var/lib/ia-livre/models/*.gguf 2>/dev/null || true
  echo "IA_LIVRE_DISTRO_DEBIAN_GGUF=stripped"
else
  echo "IA_LIVRE_DISTRO_DEBIAN_GGUF=included"
fi
test -f "$ROOTFS/etc/ia-livre/FIRST_BOOT.md"
test -f "$ROOTFS/etc/profile.d/ia-livre.sh"
test -f "$ROOTFS/etc/motd"
# Hostname nunca deve ficar como ID de container Docker
echo ialivre >"$ROOTFS/etc/hostname"
grep -q 'ialivre' "$ROOTFS/etc/hosts" || echo '127.0.1.1 ialivre' >>"$ROOTFS/etc/hosts"
grep -qx 'ialivre' "$ROOTFS/etc/hostname"
echo "IA_LIVRE_DISTRO_HOSTNAME=ialivre"

echo "IA_LIVRE_DISTRO_DEBIAN_KERNEL=$K"
echo "IA_LIVRE_DISTRO_DEBIAN_INITRD=$I"
echo "IA_LIVRE_DISTRO_DEBIAN_ROOTFS=$ROOTFS"
echo "$MARKER_OK"
