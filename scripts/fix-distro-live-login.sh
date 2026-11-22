#!/usr/bin/env bash
# Corrige login live (ialivre/ialivre) num rootfs Debian já buildado + invalida squash ISO.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"

ROOTFS=build/distro-debian/rootfs
if [[ ! -d "$ROOTFS/opt/ia-livre" ]]; then
  echo "rootfs ausente — rode: ./scripts/build-distro-debian-rootfs.sh" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "erro: Docker necessário" >&2
  exit 1
fi

REPO="$(pwd)"
docker run --rm --privileged \
  -v "$REPO/$ROOTFS:/rootfs" \
  -v "$REPO/distro/overlay/etc/motd:/overlay-motd:ro" \
  -v "$REPO/distro/overlay/etc/ia-livre/FIRST_BOOT.md:/overlay-firstboot:ro" \
  -e IA_LIVRE_LIVE_USER=ialivre \
  -e IA_LIVRE_LIVE_PASS=ialivre \
  debian:bookworm bash -c '
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
mount --bind /proc /rootfs/proc || true
mount --bind /sys /rootfs/sys || true
mount --bind /dev /rootfs/dev || true
cp /etc/resolv.conf /rootfs/etc/resolv.conf 2>/dev/null || true

cp -f /overlay-motd /rootfs/etc/motd
mkdir -p /rootfs/etc/ia-livre
cp -f /overlay-firstboot /rootfs/etc/ia-livre/FIRST_BOOT.md

mkdir -p /rootfs/etc/systemd/system/getty@tty1.service.d \
  /rootfs/etc/systemd/system/serial-getty@ttyS0.service.d
cat >/rootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ialivre --noclear %I \$TERM
EOF
cat >/rootfs/etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ialivre --noclear %I \$TERM
EOF

chroot /rootfs apt-get update -qq >/dev/null 2>&1 || true
chroot /rootfs apt-get install -y -qq sudo passwd adduser >/dev/null 2>&1 || true

chroot /rootfs bash -c "
set -euo pipefail
U=ialivre
P=ialivre
if ! id \"\$U\" >/dev/null 2>&1; then
  useradd -m -s /bin/bash -G sudo \"\$U\" 2>/dev/null || useradd -m -s /bin/bash \"\$U\"
fi
echo \"\${U}:\${P}\" | chpasswd
mkdir -p /etc/sudoers.d
echo \"\${U} ALL=(ALL) NOPASSWD:ALL\" >/etc/sudoers.d/ia-livre-live
chmod 440 /etc/sudoers.d/ia-livre-live
echo \"root:\${P}\" | chpasswd || true
passwd -u root 2>/dev/null || true
id ialivre
echo IA_LIVRE_LIVE_USER_OK
"
'

rm -f build/distro-debian/iso-tree-cache/filesystem.squashfs
rm -f build/distro-debian/iso-tree/live/filesystem.squashfs

echo "IA_LIVRE_LIVE_LOGIN=ialivre / ialivre"
echo "Próximo: IA_LIVRE_ISO_RESQUASH=1 ./scripts/build-distro-debian-iso.sh"
echo "Depois:  sudo ./scripts/write-linux-usb.sh --mode iso --device /dev/sdX --confirm /dev/sdX --yes"
