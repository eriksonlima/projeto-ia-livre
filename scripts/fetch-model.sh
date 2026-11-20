#!/usr/bin/env bash
# Baixa o GGUF canônico da Etapa 5 para models/ (gitignored).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODELS_DIR="${MODELS_DIR:-$ROOT/models}"
MODEL_NAME="${MODEL_NAME:-tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf}"
# TinyLlama 1.1B Chat Q4_K_M (~638 MiB) — TheBloke / Hugging Face
MODEL_URL="${MODEL_URL:-https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/${MODEL_NAME}}"
DEST="$MODELS_DIR/$MODEL_NAME"

mkdir -p "$MODELS_DIR"

if [[ -f "$DEST" ]]; then
  echo "Modelo já presente: $DEST"
  ls -lh "$DEST"
  exit 0
fi

echo "Baixando $MODEL_NAME → $DEST"
echo "URL: $MODEL_URL"
tmp="$DEST.partial"
curl -fL --progress-bar -o "$tmp" "$MODEL_URL"
mv "$tmp" "$DEST"
ls -lh "$DEST"
echo "OK. Use: cargo run -p ia-livre-runtime -- --model $DEST"
