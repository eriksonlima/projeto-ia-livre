#!/usr/bin/env bash
# Harness Linha A (Etapa 9): host Linux + ia-livre-runtime, carga canônica CPU.
# Reemite métricas sob namespace IA_LIVRE_HARNESS_* (não confundir com protótipo E5/E8).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
if [[ -z "${BINDGEN_EXTRA_CLANG_ARGS:-}" ]]; then
  export BINDGEN_EXTRA_CLANG_ARGS="-I/usr/lib/gcc/x86_64-linux-gnu/13/include -I/usr/include"
fi

MODEL="${IA_LIVRE_MODEL:-models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf}"
PROMPT="${IA_LIVRE_HARNESS_PROMPT:-Complete em uma frase: O Projeto IA Livre é}"
N_PREDICT="${IA_LIVRE_HARNESS_N_PREDICT:-32}"
N_GPU_LAYERS="${IA_LIVRE_HARNESS_N_GPU_LAYERS:-0}"
RUNTIME_BIN="${IA_LIVRE_RUNTIME_BIN:-target/debug/ia-livre-runtime}"
MODEL_ID="$(basename "$MODEL")"

if [[ ! -f "$MODEL" ]]; then
  echo "HARNESS_FAIL: modelo ausente: $MODEL" >&2
  echo "Rode: ./scripts/fetch-model.sh" >&2
  exit 1
fi

if [[ ! -x "$RUNTIME_BIN" ]]; then
  echo "Building ia-livre-runtime…" >&2
  cargo build -p ia-livre-runtime
fi

LOG="$(mktemp)"
ERR="$(mktemp)"
trap 'rm -f "$LOG" "$ERR"' EXIT

set +e
"$RUNTIME_BIN" \
  --model "$MODEL" \
  --prompt "$PROMPT" \
  --n-predict "$N_PREDICT" \
  --n-gpu-layers "$N_GPU_LAYERS" \
  >"$LOG" 2>"$ERR"
rc=$?
set -e

COMBINED="$(mktemp)"
trap 'rm -f "$LOG" "$ERR" "$COMBINED"' EXIT
cat "$LOG" "$ERR" >"$COMBINED"

# Repassa saída do runtime (útil para debug); marcadores HARNESS_ vão no fim.
cat "$LOG"
if [[ -s "$ERR" ]]; then
  cat "$ERR" >&2
fi

if (( rc != 0 )); then
  echo "HARNESS_FAIL: runtime exit $rc" >&2
  exit "$rc"
fi

if ! grep -q 'IA_LIVRE_INFER_OK' "$COMBINED"; then
  echo "HARNESS_FAIL: runtime sem IA_LIVRE_INFER_OK" >&2
  exit 1
fi

LOAD_S="$(grep -oE 'IA_LIVRE_LOAD_S=[0-9.]+' "$COMBINED" | head -n1 | cut -d= -f2)"
TOKENS_PER_S="$(grep -oE 'IA_LIVRE_TOKENS_PER_S=[0-9.]+' "$COMBINED" | head -n1 | cut -d= -f2)"

if [[ -z "$LOAD_S" || -z "$TOKENS_PER_S" ]]; then
  echo "HARNESS_FAIL: métricas load/tokens ausentes na saída do runtime" >&2
  exit 1
fi

echo "IA_LIVRE_HARNESS_LINE=A"
echo "IA_LIVRE_HARNESS_MODEL=${MODEL_ID}"
echo "IA_LIVRE_HARNESS_N_PREDICT=${N_PREDICT}"
echo "IA_LIVRE_HARNESS_ACCEL=cpu"
echo "IA_LIVRE_HARNESS_LOAD_S=${LOAD_S}"
echo "IA_LIVRE_HARNESS_TOKENS_PER_S=${TOKENS_PER_S}"
echo "IA_LIVRE_HARNESS_OK"
exit 0
