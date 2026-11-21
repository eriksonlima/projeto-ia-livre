#!/usr/bin/env bash
# Gate harness: Linha A (GGUF host) + Linha B (proxy QEMU). Não prova a hipótese A vs B.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
if [[ -z "${BINDGEN_EXTRA_CLANG_ARGS:-}" ]]; then
  export BINDGEN_EXTRA_CLANG_ARGS="-I/usr/lib/gcc/x86_64-linux-gnu/13/include -I/usr/include"
fi

MODEL="${IA_LIVRE_MODEL:-models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf}"
TIMEOUT_SEC="${VERIFY_HARNESS_TIMEOUT:-600}"

if [[ ! -f "$MODEL" ]]; then
  echo "GATE_FAIL: modelo ausente: $MODEL"
  echo "Rode: ./scripts/fetch-model.sh"
  exit 1
fi

echo "Building ia-livre-runtime…"
cargo build -p ia-livre-runtime

LOG_A="$(mktemp)"
LOG_B="$(mktemp)"
COMBINED_A="$(mktemp)"
trap 'rm -f "$LOG_A" "$LOG_A.err" "$LOG_B" "$LOG_B.err" "$COMBINED_A"' EXIT

echo "Harness Linha A (timeout ${TIMEOUT_SEC}s)…"
set +e
timeout "${TIMEOUT_SEC}s" ./scripts/run-harness-line-a.sh >"$LOG_A" 2>"$LOG_A.err"
rc_a=$?
set -e

if (( rc_a == 124 )); then
  echo "GATE_FAIL: timeout Linha A após ${TIMEOUT_SEC}s"
  tail -n 40 "$LOG_A.err" || true
  exit 1
fi
if (( rc_a != 0 )); then
  echo "GATE_FAIL: Linha A exit $rc_a"
  tail -n 80 "$LOG_A.err" || true
  cat "$LOG_A" || true
  exit 1
fi

cat "$LOG_A" "$LOG_A.err" >"$COMBINED_A"

fail=0
for marker in \
  'IA_LIVRE_HARNESS_LINE=A' \
  'IA_LIVRE_HARNESS_OK' \
  'IA_LIVRE_HARNESS_LOAD_S=' \
  'IA_LIVRE_HARNESS_TOKENS_PER_S=' \
  'IA_LIVRE_HARNESS_MODEL=' \
  'IA_LIVRE_HARNESS_N_PREDICT='; do
  if ! grep -q "$marker" "$COMBINED_A"; then
    echo "GATE_FAIL: marcador ausente na Linha A: $marker"
    fail=1
  fi
done
if (( fail )); then
  tail -n 60 "$COMBINED_A" || true
  exit 1
fi

echo "Harness Linha B (QEMU proxy)…"
set +e
timeout "${TIMEOUT_SEC}s" ./scripts/run-harness-line-b.sh >"$LOG_B" 2>"$LOG_B.err"
rc_b=$?
set -e
cat "$LOG_B.err" >>"$LOG_B" 2>/dev/null || true

if (( rc_b == 124 )); then
  echo "GATE_FAIL: timeout Linha B após ${TIMEOUT_SEC}s"
  exit 1
fi
if (( rc_b != 0 )); then
  echo "GATE_FAIL: Linha B exit $rc_b"
  cat "$LOG_B" || true
  exit 1
fi

fail=0
for marker in \
  'IA_LIVRE_HARNESS_LINE=B' \
  'IA_LIVRE_HARNESS_OK' \
  'IA_LIVRE_HARNESS_PROXY=post_exit_microbench' \
  'IA_LIVRE_HARNESS_PROXY_MS=' \
  'IA_LIVRE_HARNESS_PROXY_OPS=' \
  'IA_LIVRE_HARNESS_CONTRACT_BACKEND=native_qemu' \
  'IA_LIVRE_HARNESS_CONTRACT_MEM_SCHED=OK' \
  'IA_LIVRE_HARNESS_CONTRACT_READY=1' \
  'IA_LIVRE_HARNESS_GGUF_NATIVE_LOADER=blockio_full' \
  'IA_LIVRE_HARNESS_RUNTIME_NATIVE_LAYOUT=OK' \
  'IA_LIVRE_HARNESS_RUNTIME_NATIVE_PREFILL=OK' \
  'IA_LIVRE_HARNESS_RUNTIME_NATIVE_KV_CACHE=OK' \
  'IA_LIVRE_HARNESS_RUNTIME_NATIVE_DECODE=OK' \
  'IA_LIVRE_HARNESS_RUNTIME_NATIVE_SAMPLING=OK' \
  'IA_LIVRE_HARNESS_RUNTIME_NATIVE=OK' \
  'IA_LIVRE_HARNESS_LOAD_KIND=gguf' \
  'IA_LIVRE_HARNESS_TOKENS_PER_S=' \
  'IA_LIVRE_HARNESS_LOAD_S=' \
  'IA_LIVRE_HARNESS_N_PREDICT='; do
  if ! grep -q "$marker" "$LOG_B"; then
    echo "GATE_FAIL: marcador ausente na Linha B: $marker"
    fail=1
  fi
done
if ! grep -qE 'IA_LIVRE_HARNESS_RUNTIME_NATIVE_PREFILL_LAYERS=[0-9]+' "$LOG_B"; then
  echo "GATE_FAIL: PREFILL_LAYERS ausente na Linha B"
  fail=1
fi
# E44: com geração real, B_BLOCK deve estar ausente
if grep -q 'IA_LIVRE_HARNESS_B_BLOCK=' "$LOG_B"; then
  echo "GATE_FAIL: B_BLOCK não deve aparecer com LOAD_KIND=gguf / Decode ok"
  fail=1
fi
if grep -q 'IA_LIVRE_HARNESS_B_SKIP' "$LOG_B"; then
  echo "GATE_FAIL: B não deve emitir HARNESS_B_SKIP no sucesso"
  fail=1
fi
# TOKENS_PER_S deve ser numérico > 0
if ! grep -qE 'IA_LIVRE_HARNESS_TOKENS_PER_S=[0-9]+\.[0-9]+' "$LOG_B"; then
  echo "GATE_FAIL: TOKENS_PER_S malformado"
  fail=1
fi

if (( fail )); then
  cat "$LOG_B" || true
  exit 1
fi

echo "GATE_OK: harness — A (GGUF) ok + B (Decode/sampling + TOKENS_PER_S medidos) ok"
exit 0
