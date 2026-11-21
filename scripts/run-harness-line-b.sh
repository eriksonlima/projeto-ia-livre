#!/usr/bin/env bash
# Harness Linha B (Etapas 12 / 20 / 21): QEMU/IA Livre — proxy pós-ExitBoot + evidência do contrato E19.
# NÃO é TinyLlama / Linha A. Reemite IA_LIVRE_HARNESS_* honestos.
# Proibido: TOKENS_PER_S / inventar GGUF / declarar hipótese comprovada.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

TIMEOUT_SEC="${VERIFY_HARNESS_B_TIMEOUT:-${VERIFY_TIMEOUT:-45}}"
LOG="$(mktemp)"
trap 'rm -f "$LOG"; [[ -n "${QEMU_PID:-}" ]] && kill -KILL "$QEMU_PID" 2>/dev/null || true' EXIT

make esp >/dev/null

make run >"$LOG" 2>&1 &
QEMU_PID=$!

have_ready() {
  grep -q 'IA_LIVRE_EXIT_BOOT_OK' "$LOG" 2>/dev/null \
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
  echo "HARNESS_FAIL: Linha B — serial sem EXIT_BOOT_OK + MEM_SCHED_* + NATIVE_BENCH_*" >&2
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

# Evidência honesta do contrato E19 (Etapa 20 Task 4) — namespace harness; ≠ TOKENS_PER_S
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

echo "IA_LIVRE_HARNESS_OK"
# Etapa 21: estado honesto do caminho GGUF (não substitui LOAD_KIND=proxy; não inventa tokens)
# Default pós-E19/E20: deps de contrato ok, mas caminho GGUF no QEMU ainda ausente.
B_BLOCK_REASON="${IA_LIVRE_HARNESS_B_BLOCK:-no_gguf_path}"
echo "IA_LIVRE_HARNESS_B_BLOCK=${B_BLOCK_REASON}"
echo "IA_LIVRE_HARNESS_GGUF_STATUS=blocked"
if [[ "${IA_LIVRE_HARNESS_B_MODE:-}" == "block-status" ]]; then
  # Stanza explícita de bloqueio GGUF (LOAD_KIND=blocked) — informativa; gate mínimo continua no proxy acima.
  echo "IA_LIVRE_HARNESS_LOAD_KIND_GGUF=blocked"
fi
echo "nota: hipótese A vs B NÃO comprovada — B é proxy + evidência MEM_SCHED; GGUF canônico em B bloqueado (${B_BLOCK_REASON})."
exit 0
