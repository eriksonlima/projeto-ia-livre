#!/usr/bin/env bash
# QEMU só com ESP FAT (path metal/SFS) — sem disco BlockIO raw (Etapa 48 / ADR 0017).
# Prova esp_header + B_BLOCK_METAL; ≠ METAL_OK; ≠ geração BlockIO.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export IA_LIVRE_KERNEL_PROFILE="${IA_LIVRE_KERNEL_PROFILE:-release}"

QEMU="${QEMU:-qemu-system-x86_64}"
ESP_DIR="${IA_LIVRE_ESP_ONLY_DIR:-build/baremetal-esp}"
QEMU_MEM="${QEMU_MEM:-512M}"

make baremetal-esp
test -f "$ESP_DIR/EFI/BOOT/BOOTX64.EFI"

OVMF_BIOS="$(ls /usr/share/ovmf/OVMF.fd /usr/share/qemu/OVMF.fd 2>/dev/null | head -1 || true)"
OVMF_CODE="$(ls /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd 2>/dev/null | head -1 || true)"
OVMF_VARS_T="$(ls /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/OVMF/OVMF_VARS.fd 2>/dev/null | head -1 || true)"

if [[ -n "$OVMF_BIOS" && -f "$OVMF_BIOS" ]]; then
  exec "$QEMU" -machine q35 -m "$QEMU_MEM" -bios "$OVMF_BIOS" \
    -drive format=raw,file=fat:rw:"$ESP_DIR" \
    -serial stdio -display none -net none
elif [[ -n "$OVMF_CODE" && -f "$OVMF_CODE" && -n "$OVMF_VARS_T" && -f "$OVMF_VARS_T" ]]; then
  mkdir -p build
  cp "$OVMF_VARS_T" build/OVMF_VARS_esp_only.fd
  exec "$QEMU" -machine q35 -m "$QEMU_MEM" \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
    -drive if=pflash,format=raw,file=build/OVMF_VARS_esp_only.fd \
    -drive format=raw,file=fat:rw:"$ESP_DIR" \
    -serial stdio -display none -net none
else
  echo "erro: OVMF não encontrado" >&2
  exit 1
fi
