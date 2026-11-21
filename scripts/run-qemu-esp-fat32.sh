#!/usr/bin/env bash
# QEMU path metal com imagem FAT32 + GGUF completo (Etapa 63).
# ≠ fat:rw: directory (FAT16 ~516 MiB). ≠ BlockIO raw. ≠ METAL_OK.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export IA_LIVRE_KERNEL_PROFILE="${IA_LIVRE_KERNEL_PROFILE:-release}"

QEMU="${QEMU:-qemu-system-x86_64}"
IMG="${IA_LIVRE_BAREMETAL_IMG:-build/ia-livre-esp.img}"
QEMU_MEM="${QEMU_MEM:-1536M}"

# Garante mtools no PATH (user-local extract ok)
if ! command -v mcopy >/dev/null || ! command -v mmd >/dev/null; then
  echo "erro: mcopy/mmd ausentes — instale mtools ou extraia .deb em ~/.local/bin" >&2
  exit 1
fi

export IA_LIVRE_BAREMETAL_FULL_GGUF=1
export IA_LIVRE_BAREMETAL_IMG_MB="${IA_LIVRE_BAREMETAL_IMG_MB:-720}"
SKIP_REBUILD="${IA_LIVRE_BAREMETAL_SKIP_REBUILD:-0}"
if [[ "$SKIP_REBUILD" == "1" && -f "$IMG" && -f build/baremetal-esp/IA_LIVRE/model.gguf ]]; then
  echo "nota: reusando $IMG (IA_LIVRE_BAREMETAL_SKIP_REBUILD=1)"
else
  ./scripts/make-baremetal-esp.sh
fi

test -f "$IMG" || {
  echo "erro: imagem FAT32 ausente: $IMG (mtools/mkfs.vfat requeridos)" >&2
  exit 1
}
test -f build/baremetal-esp/IA_LIVRE/model.gguf || {
  echo "erro: model.gguf ausente na ESP — rode ./scripts/fetch-model.sh" >&2
  exit 1
}

OVMF_BIOS="$(ls /usr/share/ovmf/OVMF.fd /usr/share/qemu/OVMF.fd 2>/dev/null | head -1 || true)"
OVMF_CODE="$(ls /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd 2>/dev/null | head -1 || true)"
OVMF_VARS_T="$(ls /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/OVMF/OVMF_VARS.fd 2>/dev/null | head -1 || true)"

echo "IA_LIVRE_ESP_MEDIA=fat32_img"
echo "IA_LIVRE_ESP_IMG=$IMG"
echo "IA_LIVRE_QEMU_MEM=$QEMU_MEM"

# USB-storage: espelha pendrive (FAT32 whole-disk) — OVMF encontra EFI/BOOT.
QEMU_COMMON=(
  -machine q35 -m "$QEMU_MEM"
  -device qemu-xhci,id=xhci
  -device usb-storage,bus=xhci.0,drive=espfat,bootindex=0
  -drive if=none,id=espfat,format=raw,file="$IMG"
  -serial stdio -display none -net none
)

if [[ -n "$OVMF_BIOS" && -f "$OVMF_BIOS" ]]; then
  exec "$QEMU" -bios "$OVMF_BIOS" "${QEMU_COMMON[@]}"
elif [[ -n "$OVMF_CODE" && -f "$OVMF_CODE" && -n "$OVMF_VARS_T" && -f "$OVMF_VARS_T" ]]; then
  mkdir -p build
  cp "$OVMF_VARS_T" build/OVMF_VARS_esp_fat32.fd
  exec "$QEMU" \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
    -drive if=pflash,format=raw,file=build/OVMF_VARS_esp_fat32.fd \
    "${QEMU_COMMON[@]}"
else
  echo "erro: OVMF não encontrado" >&2
  exit 1
fi
