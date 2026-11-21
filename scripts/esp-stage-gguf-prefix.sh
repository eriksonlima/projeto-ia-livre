#!/usr/bin/env bash
# Empacota artefatos leves no ESP (FAT16 fat:rw do QEMU ~516 MiB — GGUF completo NÃO cabe).
# Etapa 26: gguf.hdr (4 KiB). Etapa 27: + model.gguf.sz (tamanho do canônico no host).
# O arquivo completo fica no host e é anexado ao QEMU como disco raw (BlockIO) — ver Makefile/ADR 0009.
set -euo pipefail
cd "$(dirname "$0")/.."

MODEL="${IA_LIVRE_MODEL:-models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf}"
ESP_DIR="${ESP_DIR:-build/esp}"
PREFIX_BYTES="${IA_LIVRE_GGUF_PREFIX_BYTES:-4096}"
OUT_DIR="${ESP_DIR}/IA_LIVRE"
HDR_FILE="${OUT_DIR}/gguf.hdr"
SIZE_FILE="${OUT_DIR}/model.gguf.sz"

if [[ ! -f "$MODEL" ]]; then
  echo "esp-stage-gguf: modelo ausente: $MODEL (rode ./scripts/fetch-model.sh)" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
head -c "$PREFIX_BYTES" "$MODEL" >"$HDR_FILE"
HDR_N=$(wc -c <"$HDR_FILE" | tr -d ' ')
MODEL_N=$(wc -c <"$MODEL" | tr -d ' ')
printf '%s' "$MODEL_N" >"$SIZE_FILE"
# Remove tentativa antiga de model.gguf no ESP (estoura FAT16).
rm -f "${OUT_DIR}/model.gguf"
echo "esp-stage-gguf: ${HDR_FILE} (${HDR_N} B) + ${SIZE_FILE} (${MODEL_N} B canônico no host; QEMU raw BlockIO)"
