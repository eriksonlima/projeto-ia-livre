#!/usr/bin/env bash
# Harness Linha B (Etapas 12 / 20 / 21): QEMU/IA Livre — proxy pós-ExitBoot + contrato E19/E20
# + preparação honesta da carga canônica GGUF (Etapa 21). NÃO é TinyLlama rodando.
# Proibido: TOKENS_PER_S / LOAD_S inventados / declarar hipótese comprovada.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

TIMEOUT_SEC="${VERIFY_HARNESS_B_TIMEOUT:-${VERIFY_TIMEOUT:-300}}"
# Alvo canônico (igual Linha A) — só como TARGET; não implica carga real.
GGUF_TARGET_MODEL="${IA_LIVRE_HARNESS_GGUF_TARGET_MODEL:-tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf}"
GGUF_TARGET_N_PREDICT="${IA_LIVRE_HARNESS_GGUF_TARGET_N_PREDICT:-32}"
GGUF_HOST_PATH="${IA_LIVRE_MODEL:-models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf}"
LOG="$(mktemp)"
trap 'rm -f "$LOG"; [[ -n "${QEMU_PID:-}" ]] && kill -KILL "$QEMU_PID" 2>/dev/null || true' EXIT

make esp >/dev/null

make run >"$LOG" 2>&1 &
QEMU_PID=$!

have_ready() {
  grep -q 'IA_LIVRE_EXIT_BOOT_OK' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_GGUF_MAGIC_OK' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_GGUF_HEADER_OK' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_GGUF_NATIVE_LOADER=blockio_full' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_GGUF_TENSORS_STUB_OK' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_NATIVE_INFER_BEGIN' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_RUNTIME_NATIVE_LAYOUT_OK' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_GGUF_STATUS=layout_ok' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_RUNTIME_NATIVE_FORWARD_FAIL=no_impl' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_TYPED_WEIGHTS_OK' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_TYPED_KVCACHE_OK' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_PHASE=prefill' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_PHASE=decode' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_MEM_SCHED_OK' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_NATIVE_BENCH_OK' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_NATIVE_BENCH_OPS=' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_NATIVE_BENCH_MS=' "$LOG" 2>/dev/null
}

deadline=$((SECONDS + TIMEOUT_SEC))
while (( SECONDS < deadline )); do
  if have_ready; then
    break
  fi
  if ! kill -0 "$QEMU_PID" 2>/dev/null; then
    break
  fi
  sleep 0.5
done

kill -KILL "$QEMU_PID" 2>/dev/null || true
wait "$QEMU_PID" 2>/dev/null || true
QEMU_PID=

if ! have_ready; then
  echo "HARNESS_FAIL: Linha B — serial sem EXIT_BOOT_OK + blockio_full + LAYOUT_OK + MEM_SCHED_* + NATIVE_BENCH_*" >&2
  echo "---- serial (últimas 40 linhas) ----" >&2
  tail -n 40 "$LOG" >&2 || true
  exit 1
fi

OPS="$(grep -oE 'IA_LIVRE_NATIVE_BENCH_OPS=[0-9]+' "$LOG" | head -1 | cut -d= -f2)"
MS="$(grep -oE 'IA_LIVRE_NATIVE_BENCH_MS=[0-9]+' "$LOG" | head -1 | cut -d= -f2)"
QW="$(grep -oE 'IA_LIVRE_TYPED_WEIGHTS_BYTES=[0-9]+' "$LOG" | head -1 | cut -d= -f2)"
QK="$(grep -oE 'IA_LIVRE_TYPED_KVCACHE_BYTES=[0-9]+' "$LOG" | head -1 | cut -d= -f2)"

if [[ -z "$OPS" || -z "$MS" ]]; then
  echo "HARNESS_FAIL: não parseou OPS/MS do bench" >&2
  exit 1
fi

# Proxy E12 (preservado — ainda não é GGUF canônico em B)
echo "IA_LIVRE_HARNESS_LINE=B"
echo "IA_LIVRE_HARNESS_PROXY=post_exit_microbench"
echo "IA_LIVRE_HARNESS_LOAD_KIND=proxy"
echo "IA_LIVRE_HARNESS_PROXY_MS=${MS}"
echo "IA_LIVRE_HARNESS_PROXY_OPS=${OPS}"
echo "IA_LIVRE_HARNESS_MODEL=proxy-post-exit-v1"
echo "IA_LIVRE_HARNESS_N_PREDICT=0"
echo "IA_LIVRE_HARNESS_ACCEL=cpu"

# Evidência honesta do contrato E19 (Etapa 20) — namespace harness; ≠ TOKENS_PER_S
echo "IA_LIVRE_HARNESS_CONTRACT_BACKEND=native_qemu"
echo "IA_LIVRE_HARNESS_CONTRACT_MEM_SCHED=OK"
echo "IA_LIVRE_HARNESS_CONTRACT_TYPED_WEIGHTS=OK"
echo "IA_LIVRE_HARNESS_CONTRACT_TYPED_KVCACHE=OK"
echo "IA_LIVRE_HARNESS_CONTRACT_PHASE_PREFILL=OK"
echo "IA_LIVRE_HARNESS_CONTRACT_PHASE_DECODE=OK"
if [[ -n "$QW" ]]; then
  echo "IA_LIVRE_HARNESS_CONTRACT_WEIGHTS_BYTES=${QW}"
fi
if [[ -n "$QK" ]]; then
  echo "IA_LIVRE_HARNESS_CONTRACT_KVCACHE_BYTES=${QK}"
fi

# Etapa 21 Task 3: integração harness ↔ contrato — deps 19/20 verificáveis no serial.
# CONTRACT_READY=1 = MEM_SCHED + fases + proxy observados; NÃO implica loader GGUF.
echo "IA_LIVRE_HARNESS_CONTRACT_READY=1"
echo "IA_LIVRE_HARNESS_GGUF_TARGET_MODEL=${GGUF_TARGET_MODEL}"
echo "IA_LIVRE_HARNESS_GGUF_TARGET_N_PREDICT=${GGUF_TARGET_N_PREDICT}"
echo "IA_LIVRE_HARNESS_GGUF_TARGET_PROMPT=canonical_v1"
if [[ -f "$GGUF_HOST_PATH" ]]; then
  echo "IA_LIVRE_HARNESS_GGUF_HOST_FILE=present"
else
  echo "IA_LIVRE_HARNESS_GGUF_HOST_FILE=absent"
fi
# Etapa 29: layout via runtime-native; forward ainda ausente → no_gguf_forward.
LOADER="$(grep -oE 'IA_LIVRE_GGUF_NATIVE_LOADER=[a-z0-9_]+' "$LOG" | head -1 | cut -d= -f2)"
LOADER="${LOADER:-blockio_full}"
# Preferir status pós-layout (layout_ok); senão último GGUF_STATUS do serial.
STATUS="$(grep -oE 'IA_LIVRE_GGUF_STATUS=layout_ok' "$LOG" | head -1 | cut -d= -f2)"
if [[ -z "$STATUS" ]]; then
  STATUS="$(grep -oE 'IA_LIVRE_GGUF_STATUS=[a-z0-9_]+' "$LOG" | tail -1 | cut -d= -f2)"
fi
STATUS="${STATUS:-layout_ok}"
echo "IA_LIVRE_HARNESS_GGUF_NATIVE_LOADER=${LOADER}"
if grep -q 'IA_LIVRE_RUNTIME_NATIVE_LAYOUT_OK' "$LOG"; then
  echo "IA_LIVRE_HARNESS_RUNTIME_NATIVE_LAYOUT=OK"
fi
if grep -q 'IA_LIVRE_RUNTIME_NATIVE_FORWARD_FAIL=no_impl' "$LOG"; then
  echo "IA_LIVRE_HARNESS_RUNTIME_NATIVE_FORWARD_FAIL=no_impl"
fi

echo "IA_LIVRE_HARNESS_OK"
B_BLOCK_REASON="${IA_LIVRE_HARNESS_B_BLOCK:-no_gguf_forward}"
echo "IA_LIVRE_HARNESS_B_BLOCK=${B_BLOCK_REASON}"
echo "IA_LIVRE_HARNESS_GGUF_STATUS=${STATUS}"
if [[ "${IA_LIVRE_HARNESS_B_MODE:-}" == "block-status" ]]; then
  echo "IA_LIVRE_HARNESS_LOAD_KIND_GGUF=${STATUS}"
fi
echo "nota: hipótese A vs B NÃO comprovada — loader=${LOADER} status=${STATUS}; sem TOKENS_PER_S (${B_BLOCK_REASON})."
exit 0
