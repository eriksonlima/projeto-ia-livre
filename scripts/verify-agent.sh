#!/usr/bin/env bash
# Gate Etapa 7 + Etapa 24 (autonomia v1):
#   E7: TOOL_OK + MEMORY_OK + AGENT_OK + nota canônica
#   v1: MEMORY_POLICY_OK + ≥2 ferramentas (TOOLS_USED≥2 / TOOL=note + TOOL=recall|help)
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

echo "Running agent proof scenario v1 (timeout ${TIMEOUT_SEC}s)…"
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
# Regressão E7
for marker in IA_LIVRE_TOOL_OK IA_LIVRE_MEMORY_OK IA_LIVRE_AGENT_OK; do
  if ! grep -q "$marker" "$COMBINED"; then
    echo "GATE_FAIL: marcador ausente: $marker"
    fail=1
  fi
done

# Extensão v1 (Etapa 24)
if ! grep -q 'IA_LIVRE_MEMORY_POLICY_OK' "$COMBINED"; then
  echo "GATE_FAIL: marcador ausente: IA_LIVRE_MEMORY_POLICY_OK"
  fail=1
fi

if ! grep -qE 'IA_LIVRE_TOOLS_USED=[2-9]|IA_LIVRE_TOOLS_USED=[1-9][0-9]+' "$COMBINED"; then
  echo "GATE_FAIL: evidência ≥2 ferramentas ausente (IA_LIVRE_TOOLS_USED≥2)"
  fail=1
fi

if ! grep -q 'IA_LIVRE_TOOL=note' "$COMBINED"; then
  echo "GATE_FAIL: marcador ausente: IA_LIVRE_TOOL=note"
  fail=1
fi

if ! grep -qE 'IA_LIVRE_TOOL=(recall|help)' "$COMBINED"; then
  echo "GATE_FAIL: segunda ferramenta ausente (IA_LIVRE_TOOL=recall|help)"
  fail=1
fi

# Extensão Etapa 40 — calc sandboxed
if ! grep -q 'IA_LIVRE_TOOL=calc' "$COMBINED"; then
  echo "GATE_FAIL: marcador ausente: IA_LIVRE_TOOL=calc"
  fail=1
fi
if ! grep -q 'IA_LIVRE_TOOL_SANDBOX_OK' "$COMBINED"; then
  echo "GATE_FAIL: marcador ausente: IA_LIVRE_TOOL_SANDBOX_OK"
  fail=1
fi
if ! grep -qE 'IA_LIVRE_CALC_RESULT=7(\.0)?' "$COMBINED"; then
  echo "GATE_FAIL: IA_LIVRE_CALC_RESULT=7 ausente (prova 1+2*3)"
  fail=1
fi

if [[ ! -f "$MEMORY_FILE" ]] || ! grep -q 'prova-autonomia-ia-livre' "$MEMORY_FILE"; then
  echo "GATE_FAIL: memória de prova ausente ou sem nota canônica"
  fail=1
fi

if (( fail )); then
  echo "---- saída (últimas 60 linhas) ----"
  tail -n 60 "$COMBINED" || true
  exit 1
fi

echo "GATE_OK: autonomia v1+calc — $(grep -E 'IA_LIVRE_(TOOL_OK|MEMORY_OK|AGENT_OK|MEMORY_POLICY_OK|TOOLS_USED=|RUNTIME_USED=|TOOL_SANDBOX_OK|TOOL=calc)' "$COMBINED" | tr '\n' ' ')"
exit 0
