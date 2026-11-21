#!/usr/bin/env bash
# Gate do perfil A_otimizada (Etapa 34) — não substitui verify-harness.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

TIMEOUT_SEC="${VERIFY_HARNESS_A_OPT_TIMEOUT:-${VERIFY_HARNESS_TIMEOUT:-300}}"
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

timeout "${TIMEOUT_SEC}s" ./scripts/run-harness-line-a-optimized.sh >"$LOG" 2>&1 || {
  echo "GATE_FAIL: run-harness-line-a-optimized.sh exit/timeout"
  tail -n 40 "$LOG" || true
  exit 1
}

fail=0
for m in \
  'IA_LIVRE_HARNESS_LINE=A' \
  'IA_LIVRE_HARNESS_PROFILE=A_otimizada' \
  'IA_LIVRE_HARNESS_THREADS=' \
  'IA_LIVRE_HARNESS_OK' \
  'IA_LIVRE_HARNESS_LOAD_S=' \
  'IA_LIVRE_HARNESS_TOKENS_PER_S='; do
  if ! grep -q "$m" "$LOG"; then
    echo "GATE_FAIL: marcador ausente: $m"
    fail=1
  fi
done

if (( fail )); then
  cat "$LOG" || true
  exit 1
fi

echo "GATE_OK: harness A_otimizada — PROFILE=A_otimizada + OK + métricas"
exit 0
