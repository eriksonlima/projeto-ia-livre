#!/usr/bin/env bash
# Grava artefato Linux IA Livre em um device — exige --confirm e --yes.
# --mode iso: dd da ISO híbrida (E85/E86). --mode tar: copia tarball (E81 legado).
# ≠ write-usb-esp.sh (UEFI). Não inventa METAL_OK.
#
# Sob sudo: PATH do usuário real (SUDO_USER) é restaurado; --mode iso NÃO
# rebuilda se a ISO já existir (evita `cargo: comando não encontrado`).
set -euo pipefail
cd "$(dirname "$0")/.."

# sudo reseta PATH — repor cargo/local do usuário que invocou
if [[ -n "${SUDO_USER:-}" ]]; then
  SUDO_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
  export PATH="${SUDO_HOME}/.local/bin:${SUDO_HOME}/.cargo/bin:/usr/local/bin:/usr/bin:${PATH}"
  export HOME="${SUDO_HOME}"
else
  export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"
fi

usage() {
  cat <<EOF
Uso:
  $0 --list
  $0 --mode iso --device /dev/sdX --confirm /dev/sdX --yes
  $0 --mode tar --device /dev/sdX --confirm /dev/sdX --yes

  iso  — dd da ISO live (reusa build/distro-debian/ia-livre-linux.iso se existir)
  tar  — copia tarball+README para partição montável (legado E81)

Recomendado: gerar a ISO sem sudo, gravar com sudo:
  ./scripts/build-distro-debian-iso.sh
  sudo ./scripts/write-linux-usb.sh --mode iso --device /dev/sdX --confirm /dev/sdX --yes
EOF
}

find_iso() {
  local c
  for c in \
    build/linux-usb/ia-livre-linux.iso \
    build/distro-debian/ia-livre-linux.iso \
    build/release-linux/ia-livre-linux.iso
  do
    if [[ -f "$c" ]]; then
      echo "$c"
      return 0
    fi
  done
  return 1
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

case "$MODE" in
  iso)
    ISO=""
    if ISO="$(find_iso)"; then
      echo "IA_LIVRE_WRITE_LINUX_USB_ISO_SRC=$ISO"
    else
      echo "ISO ausente — preparando artefato (precisa cargo no PATH)…"
      ./scripts/prepare-linux-usb-artifact.sh
      ISO=build/linux-usb/ia-livre-linux.iso
      if [[ ! -f "$ISO" ]]; then
        echo "erro: ISO ausente. Rode sem sudo: ./scripts/build-distro-debian-iso.sh" >&2
        exit 1
      fi
    fi
    echo "IA_LIVRE_WRITE_LINUX_USB_MODE=iso"
    dd if="$ISO" of="$DEVICE" bs=4M status=progress conv=fsync
    sync
    echo "IA_LIVRE_LINUX_USB_DEVICE=$DEVICE"
    echo "IA_LIVRE_WRITE_LINUX_USB_OK"
    ;;
  tar)
    ./scripts/prepare-linux-usb-artifact.sh
    SRC=build/linux-usb
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
