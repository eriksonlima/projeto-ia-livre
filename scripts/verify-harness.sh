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
  'IA_LIVRE_HARNESS_LOAD_KIND=proxy' \
  'IA_LIVRE_HARNESS_PROXY_MS=' \
  'IA_LIVRE_HARNESS_PROXY_OPS=' \
  'IA_LIVRE_HARNESS_MODEL=proxy-post-exit-v1' \
  'IA_LIVRE_HARNESS_N_PREDICT=0' \
  'IA_LIVRE_HARNESS_CONTRACT_BACKEND=native_qemu' \
  'IA_LIVRE_HARNESS_CONTRACT_MEM_SCHED=OK' \
  'IA_LIVRE_HARNESS_CONTRACT_TYPED_WEIGHTS=OK' \
  'IA_LIVRE_HARNESS_CONTRACT_TYPED_KVCACHE=OK' \
  'IA_LIVRE_HARNESS_CONTRACT_PHASE_PREFILL=OK' \
  'IA_LIVRE_HARNESS_CONTRACT_PHASE_DECODE=OK' \
  'IA_LIVRE_HARNESS_CONTRACT_READY=1' \
  'IA_LIVRE_HARNESS_GGUF_TARGET_MODEL=' \
  'IA_LIVRE_HARNESS_GGUF_TARGET_N_PREDICT=32' \
  'IA_LIVRE_HARNESS_GGUF_NATIVE_LOADER=blockio_full' \
  'IA_LIVRE_HARNESS_GGUF_STATUS=layout_ok' \
  'IA_LIVRE_HARNESS_RUNTIME_NATIVE_LAYOUT=OK' \
  'IA_LIVRE_HARNESS_RUNTIME_NATIVE_TENSOR_MAP=OK' \
  'IA_LIVRE_HARNESS_RUNTIME_NATIVE_Q4K_DEQUANT=OK' \
  'IA_LIVRE_HARNESS_RUNTIME_NATIVE_FORWARD_OP=OK' \
  'IA_LIVRE_HARNESS_RUNTIME_NATIVE_TOKENIZE=OK' \
  'IA_LIVRE_HARNESS_RUNTIME_NATIVE_EMBED=OK' \
  'IA_LIVRE_HARNESS_RUNTIME_NATIVE_LAYER_PARTIAL=OK' \
  'IA_LIVRE_HARNESS_RUNTIME_NATIVE_ATTN_LAYER=OK' \
  'IA_LIVRE_HARNESS_RUNTIME_NATIVE_FFN_LAYER=OK' \
  'IA_LIVRE_HARNESS_RUNTIME_NATIVE_PREFILL=OK' \
  'IA_LIVRE_HARNESS_RUNTIME_NATIVE_KV_CACHE=OK' \
  'IA_LIVRE_HARNESS_RUNTIME_NATIVE_PREFILL_PARTIAL=OK' \
  'IA_LIVRE_HARNESS_RUNTIME_NATIVE_FORWARD_FAIL=no_decode'; do
  if ! grep -q "$marker" "$LOG_B"; then
    echo "GATE_FAIL: marcador ausente na Linha B: $marker"
    fail=1
  fi
done
if ! grep -qE 'IA_LIVRE_HARNESS_RUNTIME_NATIVE_PREFILL_LAYERS=[0-9]+' "$LOG_B"; then
  echo "GATE_FAIL: PREFILL_LAYERS ausente na Linha B"
  fail=1
fi
if ! grep -q 'IA_LIVRE_HARNESS_GGUF_NATIVE_LOADER=blockio_full' "$LOG_B"; then
  echo "GATE_FAIL: exige GGUF_NATIVE_LOADER=blockio_full"
  fail=1
fi

# Fraudes / legado (sem inventar GGUF)
if grep -q 'IA_LIVRE_HARNESS_B_SKIP' "$LOG_B"; then
  echo "GATE_FAIL: B não deve emitir HARNESS_B_SKIP no sucesso"
  fail=1
fi
if grep -qE 'IA_LIVRE_HARNESS_TOKENS_PER_S=' "$LOG_B"; then
  echo "GATE_FAIL: B não deve emitir TOKENS_PER_S sem carga GGUF real (fraude / proxy)"
  fail=1
fi
if grep -qE 'IA_LIVRE_HARNESS_LOAD_S=' "$LOG_B"; then
  echo "GATE_FAIL: B não deve emitir LOAD_S (load GGUF falso)"
  fail=1
fi
# HARNESS_MODEL= (não TARGET) não pode fingir TinyLlama/GGUF
if grep -qiE 'IA_LIVRE_HARNESS_MODEL=.*tinyllama|IA_LIVRE_HARNESS_MODEL=.*\.gguf' "$LOG_B"; then
  echo "GATE_FAIL: B não deve fingir modelo GGUF TinyLlama em HARNESS_MODEL="
  fail=1
fi
if grep -qE 'IA_LIVRE_HARNESS_LOAD_KIND=gguf' "$LOG_B"; then
  echo "GATE_FAIL: B emitiu LOAD_KIND=gguf sem caminho GGUF real implementado"
  fail=1
fi
# Bloqueio residual E43: prefill multi/KV subset; 22L pleno ainda não (ADR 0014)
if ! grep -q 'IA_LIVRE_HARNESS_B_BLOCK=' "$LOG_B"; then
  echo "GATE_FAIL: B deve declarar B_BLOCK= (estado honesto)"
  fail=1
fi
if grep -qE 'IA_LIVRE_HARNESS_B_BLOCK=(no_gguf_path|awaiting_b13_b14|no_gguf_infer|no_gguf_infer_engine|no_gguf_forward|no_gguf_generate|no_gguf_full_prefill)$' "$LOG_B"; then
  echo "GATE_FAIL: B_BLOCK legado — Etapa 43 exige no_gguf_prefill_22l (ou no_gguf_decode se 22L)"
  fail=1
fi
if ! grep -qE 'IA_LIVRE_HARNESS_B_BLOCK=(no_gguf_prefill_22l|no_gguf_decode)$' "$LOG_B"; then
  echo "GATE_FAIL: B_BLOCK deve ser no_gguf_prefill_22l (subset) ou no_gguf_decode (22L)"
  fail=1
fi

if (( fail )); then
  cat "$LOG_B" || true
  exit 1
fi

echo "GATE_OK: harness — A (GGUF) ok + B (proxy + prefill multi/KV + no_gguf_prefill_22l) ok — hipótese NÃO comprovada"
exit 0
