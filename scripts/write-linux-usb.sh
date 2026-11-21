#!/usr/bin/env bash
# Grava artefato Linux IA Livre em um device — exige --confirm e --yes.
# ≠ write-usb-esp.sh (UEFI). Não inventa METAL_OK.
set -euo pipefail
cd "$(dirname "$0")/.."

usage() {
  cat <<EOF
Uso:
  $0 --list
  $0 --device /dev/sdX --confirm /dev/sdX --yes

Copia build/linux-usb/* para a 1ª partição montável do device (FAT ou ext*).
EOF
}

LIST=0
DEVICE=""
CONFIRM=""
YES=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --list) LIST=1; shift ;;
    --device) DEVICE="${2:-}"; shift 2 ;;
    --confirm) CONFIRM="${2:-}"; shift 2 ;;
    --yes) YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "arg: $1" >&2; usage; exit 1 ;;
  esac
done

if (( LIST )); then
  lsblk -o NAME,SIZE,TYPE,TRAN,MOUNTPOINT,LABEL,FSTYPE
  exit 0
fi

if [[ -z "$DEVICE" || "$DEVICE" != "$CONFIRM" || "$YES" -ne 1 ]]; then
  echo "erro: exige --device PATH --confirm PATH --yes (path idêntico)" >&2
  exit 1
fi
if [[ ! -b "$DEVICE" ]]; then
  echo "erro: não é block device: $DEVICE" >&2
  exit 1
fi

./scripts/prepare-linux-usb-artifact.sh
SRC=build/linux-usb
test -f "$SRC/ia-livre-distro-rootfs.tar.gz"

# Preferir partição 1
PART="${DEVICE}1"
if [[ ! -b "$PART" ]]; then
  PART="$DEVICE"
fi

MNT="$(mktemp -d)"
cleanup() { umount "$MNT" 2>/dev/null || true; rmdir "$MNT" 2>/dev/null || true; }
trap cleanup EXIT

if ! mount "$PART" "$MNT" 2>/dev/null; then
  echo "erro: não montou $PART (crie filesystem FAT/ext4 antes)" >&2
  exit 1
fi

mkdir -p "$MNT/ia-livre-linux"
cp -f "$SRC"/* "$MNT/ia-livre-linux/"
sync
echo "IA_LIVRE_LINUX_USB_DEVICE=$DEVICE"
echo "IA_LIVRE_LINUX_USB_PART=$PART"
echo "IA_LIVRE_WRITE_LINUX_USB_OK"
