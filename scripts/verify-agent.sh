#!/usr/bin/env bash
# Gate Etapa 7: ambiente de autonomia — TOOL_OK + MEMORY_OK + AGENT_OK.
# Não exige QEMU/UEFI nem o nó P2P. Requer GGUF canônico (como verify-runtime).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$(pwd)/target}"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
if [[ -z "${BINDGEN_EXTRA_CLANG_ARGS:-}" ]]; then
  export BINDGEN_EXTRA_CLANG_ARGS="-I/usr/lib/gcc/x86_64-linux-gnu/13/include -I/usr/include"
fi

MODEL="${IA_LIVRE_MODEL:-models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf}"
N_PREDICT="${IA_LIVRE_N_PREDICT:-16}"
TIMEOUT_SEC="${VERIFY_AGENT_TIMEOUT:-300}"
MEMORY_DIR="${VERIFY_AGENT_MEMORY_DIR:-build/agent-memory-verify}"
MEMORY_FILE="${MEMORY_DIR}/memory.jsonl"

if [[ ! -f "$MODEL" ]]; then
  echo "GATE_FAIL: modelo ausente: $MODEL"
  echo "Rode: ./scripts/fetch-model.sh"
  exit 1
fi

echo "Building ia-livre-runtime + ia-livre-agent…"
cargo build -p ia-livre-runtime -p ia-livre-agent

RUNTIME_BIN="${CARGO_TARGET_DIR}/debug/ia-livre-runtime"
AGENT_BIN="${CARGO_TARGET_DIR}/debug/ia-livre-agent"
if [[ ! -x "$RUNTIME_BIN" ]]; then
  echo "GATE_FAIL: binário ausente: $RUNTIME_BIN"
  exit 1
fi
if [[ ! -x "$AGENT_BIN" ]]; then
  echo "GATE_FAIL: binário ausente: $AGENT_BIN"
  exit 1
fi

rm -rf "$MEMORY_DIR"
mkdir -p "$MEMORY_DIR"

LOG="$(mktemp)"
trap 'rm -f "$LOG" "$LOG.err"' EXIT

echo "Running agent proof scenario (timeout ${TIMEOUT_SEC}s)…"
set +e
timeout "${TIMEOUT_SEC}s" "$AGENT_BIN" \
  --model "$MODEL" \
  --memory "$MEMORY_FILE" \
  --n-predict "$N_PREDICT" \
  --runtime-bin "$RUNTIME_BIN" \
  >"$LOG" 2>"$LOG.err"
rc=$?
set -e

if (( rc == 124 )); then
  echo "GATE_FAIL: timeout após ${TIMEOUT_SEC}s"
  tail -n 40 "$LOG.err" || true
  exit 1
fi
if (( rc != 0 )); then
  echo "GATE_FAIL: agent exit $rc"
  tail -n 80 "$LOG.err" || true
  cat "$LOG" || true
  exit 1
fi

COMBINED="$(mktemp)"
trap 'rm -f "$LOG" "$LOG.err" "$COMBINED"' EXIT
cat "$LOG" "$LOG.err" >"$COMBINED"

fail=0
for marker in IA_LIVRE_TOOL_OK IA_LIVRE_MEMORY_OK IA_LIVRE_AGENT_OK; do
  if ! grep -q "$marker" "$COMBINED"; then
    echo "GATE_FAIL: marcador ausente: $marker"
    fail=1
  fi
done

if [[ ! -f "$MEMORY_FILE" ]] || ! grep -q 'prova-autonomia-ia-livre' "$MEMORY_FILE"; then
  echo "GATE_FAIL: memória de prova ausente ou sem nota canônica"
  fail=1
fi

if (( fail )); then
  echo "---- saída (últimas 60 linhas) ----"
  tail -n 60 "$COMBINED" || true
  exit 1
fi

echo "GATE_OK: autonomia — $(grep -E 'IA_LIVRE_(TOOL_OK|MEMORY_OK|AGENT_OK|RUNTIME_USED=)' "$COMBINED" | tr '\n' ' ')"
exit 0
