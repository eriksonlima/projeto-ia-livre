#!/usr/bin/env bash
# Grava artefato Linux IA Livre em um device — exige --confirm e --yes.
# --mode iso: dd da ISO híbrida (E85/E86). --mode tar: copia tarball (E81 legado).
# ≠ write-usb-esp.sh (UEFI). Não inventa METAL_OK.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"

usage() {
  cat <<EOF
Uso:
  $0 --list
  $0 --mode iso --device /dev/sdX --confirm /dev/sdX --yes
  $0 --mode tar --device /dev/sdX --confirm /dev/sdX --yes

  iso  — dd de build/linux-usb/ia-livre-linux.iso (live bootável)
  tar  — copia tarball+README para partição montável (legado E81)
EOF
}

LIST=0
DEVICE=""
CONFIRM=""
YES=0
MODE="iso"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --list) LIST=1; shift ;;
    --device) DEVICE="${2:-}"; shift 2 ;;
    --confirm) CONFIRM="${2:-}"; shift 2 ;;
    --mode) MODE="${2:-}"; shift 2 ;;
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

case "$MODE" in
  iso)
    ISO="$SRC/ia-livre-linux.iso"
    if [[ ! -f "$ISO" ]]; then
      echo "erro: ISO ausente em $ISO (rode build-distro-debian-iso.sh)" >&2
      exit 1
    fi
    echo "IA_LIVRE_WRITE_LINUX_USB_MODE=iso"
    # Destrutivo: requer confirm já validado
    dd if="$ISO" of="$DEVICE" bs=4M status=progress conv=fsync
    sync
    echo "IA_LIVRE_LINUX_USB_DEVICE=$DEVICE"
    echo "IA_LIVRE_WRITE_LINUX_USB_OK"
    ;;
  tar)
    test -f "$SRC/ia-livre-distro-rootfs.tar.gz"
    echo "IA_LIVRE_WRITE_LINUX_USB_MODE=tar"
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
    ;;
  *)
    echo "erro: --mode iso|tar" >&2
    exit 1
    ;;
esac
