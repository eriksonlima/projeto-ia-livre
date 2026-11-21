#!/usr/bin/env bash
# Monta árvore ESP empacotável para USB/hardware UEFI (Etapas 30/36 / ADR 0011).
# Não grava dispositivo USB automaticamente. QEMU ≠ bare-metal.
# Opt-in GGUF completo: IA_LIVRE_BAREMETAL_FULL_GGUF=1 (docs/gguf-baremetal-midia.md).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$(pwd)/target}"

PROFILE="${IA_LIVRE_KERNEL_PROFILE:-debug}"
KERNEL_EFI="${CARGO_TARGET_DIR}/x86_64-unknown-uefi/${PROFILE}/ia-livre-kernel.efi"
OUT_DIR="${IA_LIVRE_BAREMETAL_ESP:-build/baremetal-esp}"
TAR_OUT="${IA_LIVRE_BAREMETAL_TAR:-build/ia-livre-esp.tar.gz}"
IMG_OUT="${IA_LIVRE_BAREMETAL_IMG:-build/ia-livre-esp.img}"
FULL_GGUF="${IA_LIVRE_BAREMETAL_FULL_GGUF:-0}"
GGUF_SRC="${IA_LIVRE_MODEL:-models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf}"
# Default 64 MiB; com FULL_GGUF precisa ~700+
if [[ "$FULL_GGUF" == "1" ]]; then
  IMG_MB="${IA_LIVRE_BAREMETAL_IMG_MB:-720}"
else
  IMG_MB="${IA_LIVRE_BAREMETAL_IMG_MB:-64}"
fi

make build

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR/EFI/BOOT" "$OUT_DIR/IA_LIVRE"
cp "$KERNEL_EFI" "$OUT_DIR/EFI/BOOT/BOOTX64.EFI"

# Prefixo GGUF opcional (4 KiB) — sempre que o modelo existir no host
if [[ -f "$GGUF_SRC" ]]; then
  dd if="$GGUF_SRC" of="$OUT_DIR/IA_LIVRE/gguf.hdr" bs=4096 count=1 status=none 2>/dev/null || true
fi

GGUF_DST="$OUT_DIR/IA_LIVRE/model.gguf"
if [[ "$FULL_GGUF" == "1" ]]; then
  if [[ ! -f "$GGUF_SRC" ]]; then
    echo "erro: IA_LIVRE_BAREMETAL_FULL_GGUF=1 mas modelo ausente: $GGUF_SRC" >&2
    echo "Rode: ./scripts/fetch-model.sh" >&2
    exit 1
  fi
  echo "nota: copiando GGUF completo (~638 MiB) para $GGUF_DST …" >&2
  cp "$GGUF_SRC" "$GGUF_DST"
  GGUF_BYTES="$(wc -c <"$GGUF_DST" | tr -d ' ')"
  GGUF_SHA="$(sha256sum "$GGUF_DST" | awk '{print $1}')"
  echo "IA_LIVRE_BAREMETAL_GGUF_SIZE=$GGUF_BYTES"
  echo "IA_LIVRE_BAREMETAL_GGUF_SHA256=$GGUF_SHA"
fi

if [[ -f "$GGUF_DST" ]]; then
  cat > "$OUT_DIR/IA_LIVRE/README.txt" << 'EOF'
Projeto IA Livre — ESP com GGUF completo (Etapa 36)

- EFI/BOOT/BOOTX64.EFI — kernel UEFI
- IA_LIVRE/gguf.hdr — prefixo 4 KiB
- IA_LIVRE/model.gguf — TinyLlama Q4_K_M canônico (~638 MiB)
- Serial: UART COM1 (115200 8N1)
- Secure Boot: desligar ou modo setup
- Ver docs/gguf-baremetal-midia.md — QEMU ≠ metal; sem TOKENS_PER_S
EOF
else
  cat > "$OUT_DIR/IA_LIVRE/README.txt" << 'EOF'
Projeto IA Livre — ESP mínima (Etapa 30/36)

- EFI/BOOT/BOOTX64.EFI — kernel UEFI
- gguf.hdr (opcional) — só prefixo 4 KiB
- GGUF completo: IA_LIVRE_BAREMETAL_FULL_GGUF=1 (docs/gguf-baremetal-midia.md)
- Serial pós-ExitBoot: UART COM1 (115200 8N1 típico)
- Secure Boot: desligar ou modo setup (EFI não assinado)
- QEMU ≠ prova de hardware real — ver docs/boot-hardware-real.md
EOF
fi

mkdir -p "$(dirname "$TAR_OUT")"
tar -C "$(dirname "$OUT_DIR")" -czf "$TAR_OUT" "$(basename "$OUT_DIR")"

SHA="$(sha256sum "$OUT_DIR/EFI/BOOT/BOOTX64.EFI" | awk '{print $1}')"
SIZE="$(wc -c <"$OUT_DIR/EFI/BOOT/BOOTX64.EFI" | tr -d ' ')"

echo "IA_LIVRE_BAREMETAL_ESP_DIR=$OUT_DIR"
echo "IA_LIVRE_BAREMETAL_TAR=$TAR_OUT"
echo "IA_LIVRE_BAREMETAL_EFI_SHA256=$SHA"
echo "IA_LIVRE_BAREMETAL_EFI_BYTES=$SIZE"

# Imagem FAT opcional (requer mtools)
if command -v mkfs.vfat >/dev/null && command -v mcopy >/dev/null && command -v mmd >/dev/null; then
  truncate -s "${IMG_MB}M" "$IMG_OUT"
  mkfs.vfat -F 32 -n IALIVRE "$IMG_OUT" >/dev/null
  mmd -i "$IMG_OUT" ::/EFI || true
  mmd -i "$IMG_OUT" ::/EFI/BOOT
  mmd -i "$IMG_OUT" ::/IA_LIVRE
  mcopy -i "$IMG_OUT" "$OUT_DIR/EFI/BOOT/BOOTX64.EFI" ::/EFI/BOOT/BOOTX64.EFI
  mcopy -i "$IMG_OUT" "$OUT_DIR/IA_LIVRE/README.txt" ::/IA_LIVRE/README.txt
  if [[ -f "$OUT_DIR/IA_LIVRE/gguf.hdr" ]]; then
    mcopy -i "$IMG_OUT" "$OUT_DIR/IA_LIVRE/gguf.hdr" ::/IA_LIVRE/gguf.hdr
  fi
  if [[ -f "$GGUF_DST" ]]; then
    mcopy -i "$IMG_OUT" "$GGUF_DST" ::/IA_LIVRE/model.gguf
  fi
  echo "IA_LIVRE_BAREMETAL_IMG=$IMG_OUT"
else
  echo "IA_LIVRE_BAREMETAL_IMG=skipped_no_mtools"
  echo "nota: instale mtools+dosfstools para gerar $IMG_OUT; árvore+tar bastam para o gate."
fi
