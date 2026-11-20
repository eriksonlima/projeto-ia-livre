#!/usr/bin/env bash
# Gate Etapa 5: runtime CPU carrega GGUF, gera texto e emite métricas.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
if [[ -z "${BINDGEN_EXTRA_CLANG_ARGS:-}" ]]; then
  export BINDGEN_EXTRA_CLANG_ARGS="-I/usr/lib/gcc/x86_64-linux-gnu/13/include -I/usr/include"
fi

MODEL="${IA_LIVRE_MODEL:-models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf}"
N_PREDICT="${IA_LIVRE_N_PREDICT:-32}"
TIMEOUT_SEC="${VERIFY_RUNTIME_TIMEOUT:-300}"

if [[ ! -f "$MODEL" ]]; then
  echo "GATE_FAIL: modelo ausente: $MODEL"
  echo "Rode: ./scripts/fetch-model.sh"
  exit 1
fi

echo "Building ia-livre-runtime…"
cargo build -p ia-livre-runtime

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

echo "Running inference (timeout ${TIMEOUT_SEC}s)…"
set +e
timeout "${TIMEOUT_SEC}s" cargo run -q -p ia-livre-runtime -- \
  --model "$MODEL" --n-predict "$N_PREDICT" >"$LOG" 2>"$LOG.err"
rc=$?
set -e

if (( rc == 124 )); then
  echo "GATE_FAIL: timeout após ${TIMEOUT_SEC}s"
  tail -n 40 "$LOG.err" || true
  exit 1
fi
if (( rc != 0 )); then
  echo "GATE_FAIL: runtime exit $rc"
  tail -n 80 "$LOG.err" || true
  cat "$LOG" || true
  exit 1
fi

# Junta stdout+stderr para grep (métricas vão na stdout; llama.cpp loga stderr)
COMBINED="$(mktemp)"
trap 'rm -f "$LOG" "$LOG.err" "$COMBINED"' EXIT
cat "$LOG" "$LOG.err" >"$COMBINED"

fail=0
for marker in IA_LIVRE_INFER_OK IA_LIVRE_LOAD_S= IA_LIVRE_TOKENS_PER_S=; do
  if ! grep -q "$marker" "$COMBINED"; then
    echo "GATE_FAIL: marcador ausente: $marker"
    fail=1
  fi
done

if (( fail )); then
  echo "---- saída (últimas 60 linhas) ----"
  tail -n 60 "$COMBINED" || true
  exit 1
fi

echo "GATE_OK: runtime CPU — $(grep -E 'IA_LIVRE_(INFER_OK|LOAD_S=|TOKENS_PER_S=)' "$COMBINED" | tr '\n' ' ')"
exit 0
