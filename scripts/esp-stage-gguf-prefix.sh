#!/usr/bin/env bash
# Empacota prefixo do GGUF canônico no ESP para o loader nativo (Etapa 26).
# Default: primeiros 4096 bytes → build/esp/IA_LIVRE/gguf.hdr
set -euo pipefail
cd "$(dirname "$0")/.."

MODEL="${IA_LIVRE_MODEL:-models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf}"
ESP_DIR="${ESP_DIR:-build/esp}"
PREFIX_BYTES="${IA_LIVRE_GGUF_PREFIX_BYTES:-4096}"
OUT_DIR="${ESP_DIR}/IA_LIVRE"
OUT_FILE="${OUT_DIR}/gguf.hdr"

if [[ ! -f "$MODEL" ]]; then
  echo "esp-stage-gguf-prefix: modelo ausente: $MODEL (rode ./scripts/fetch-model.sh)" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
# Prefixo estável (cabeçalho GGUF + bytes iniciais) — não o arquivo completo.
head -c "$PREFIX_BYTES" "$MODEL" >"$OUT_FILE"
BYTES=$(wc -c <"$OUT_FILE" | tr -d ' ')
echo "esp-stage-gguf-prefix: wrote ${OUT_FILE} (${BYTES} bytes from ${MODEL})"
