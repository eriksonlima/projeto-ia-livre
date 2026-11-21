#!/usr/bin/env bash
# Gate Etapa 20 (host): shim exerce contrato Weights/KvCache + Prefill→Decode.
# Não usa QEMU, GGUF nem kernel E19. Não prova a hipótese. Não é Linha B.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$(pwd)/target}"

TIMEOUT_SEC="${VERIFY_RUNTIME_CONTRACT_TIMEOUT:-30}"

echo "Building ia-livre-runtime-contract…"
cargo build -p ia-livre-runtime-contract

BIN="${CARGO_TARGET_DIR}/debug/ia-livre-runtime-contract"
if [[ ! -x "$BIN" ]]; then
  echo "GATE_FAIL: binário ausente: $BIN"
  exit 1
fi

LOG="$(mktemp)"
cleanup() { rm -f "$LOG"; }
trap cleanup EXIT

echo "Running host shim (timeout=${TIMEOUT_SEC}s)…"
set +e
timeout "${TIMEOUT_SEC}s" "$BIN" >"$LOG" 2>&1
rc=$?
set -e

if [[ $rc -ne 0 ]]; then
  echo "GATE_FAIL: shim exit=$rc"
  cat "$LOG" || true
  exit 1
fi

need=(
  'IA_LIVRE_CONTRACT_BACKEND=host_shim'
  'IA_LIVRE_CONTRACT_ALLOC_WEIGHTS=OK'
  'IA_LIVRE_CONTRACT_ALLOC_KVCACHE=OK'
  'IA_LIVRE_CONTRACT_PHASE=Prefill'
  'IA_LIVRE_CONTRACT_PHASE=Decode'
  'IA_LIVRE_RUNTIME_CONTRACT_OK'
)

for m in "${need[@]}"; do
  if ! grep -qF "$m" "$LOG"; then
    echo "GATE_FAIL: marcador ausente: $m"
    cat "$LOG" || true
    exit 1
  fi
done

# Honestidade: não fingir throughput GGUF neste caminho
if grep -q 'TOKENS_PER_S' "$LOG"; then
  echo "GATE_FAIL: TOKENS_PER_S proibido no caminho de contrato"
  cat "$LOG" || true
  exit 1
fi

echo "---- saída ----"
cat "$LOG"
echo "GATE_OK: verify-runtime-contract (host_shim)"
