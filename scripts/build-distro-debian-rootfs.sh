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

INCLUDES="linux-image-amd64,systemd-sysv,util-linux,udev,dbus,login,iproute2,ca-certificates,initramfs-tools"

# Script de pós-instalação (rodado via chroot no container ou host)
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
  "$R/etc/systemd/system/serial-getty@ttyS0.service.d"

if [[ -x "$R/opt/ia-livre/bin/ia-livre" ]]; then
  ln -sfn /opt/ia-livre/bin/ia-livre "$R/usr/local/bin/ia-livre"
  ln -sfn /opt/ia-livre/bin/ia-livre-native-tune "$R/usr/local/bin/ia-livre-native-tune" 2>/dev/null || true
fi

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

cat >"$R/etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf" <<'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I $TERM
EOF
CUST
  chmod +x "$dest"
}

CUST_HOST="$OUT/customize-ia-livre.sh"
write_customize "$CUST_HOST"

run_mmdebstrap_host() {
  echo "build: mmdebstrap host → $ROOTFS (suite=$SUITE)"
  mmdebstrap --variant=minbase --include="$INCLUDES" "$SUITE" "$ROOTFS" || return 1
  cp -a "$OVERLAY_ABS"/. "$ROOTFS"/
  # customize sem chroot completo se não root: só files; initramfs via docker se disponível
  bash "$CUST_HOST" "$ROOTFS" || true
  if have_docker; then
    docker run --rm --privileged \
      -v "$ROOTFS:/rootfs" \
      debian:bookworm bash -c '
        mount --bind /proc /rootfs/proc 2>/dev/null || true
        mount --bind /sys /rootfs/sys 2>/dev/null || true
        mount --bind /dev /rootfs/dev 2>/dev/null || true
        chroot /rootfs /bin/bash -c "update-initramfs -u || /usr/sbin/update-initramfs -u || true"
      ' || true
  fi
}

run_mmdebstrap_docker() {
  echo "build: mmdebstrap via Docker → $ROOTFS (suite=$SUITE)"
  docker run --rm --privileged \
    -v "$OUT:/out" \
    -v "$OVERLAY_ABS:/overlay:ro" \
    -v "$CUST_HOST:/customize.sh:ro" \
    -e SUITE="$SUITE" \
    -e INCLUDES="$INCLUDES" \
    debian:bookworm bash -c '
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq mmdebstrap ca-certificates >/dev/null
rm -rf /out/rootfs
mkdir -p /out/rootfs
mmdebstrap --variant=minbase --include="$INCLUDES" "$SUITE" /out/rootfs
cp -a /overlay/. /out/rootfs/
bash /customize.sh /out/rootfs
# rebuild initrd dentro do rootfs
mount --bind /proc /out/rootfs/proc || true
mount --bind /sys /out/rootfs/sys || true
mount --bind /dev /out/rootfs/dev || true
chroot /out/rootfs update-initramfs -u || chroot /out/rootfs /usr/sbin/update-initramfs -u || true
' || return 1
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

echo "IA_LIVRE_DISTRO_DEBIAN_KERNEL=$K"
echo "IA_LIVRE_DISTRO_DEBIAN_INITRD=$I"
echo "IA_LIVRE_DISTRO_DEBIAN_ROOTFS=$ROOTFS"
echo "$MARKER_OK"
