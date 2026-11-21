#!/usr/bin/env bash
# Perfil sym_cpu (Etapa 64): A+B com HARNESS_ACCEL=cpu (mesmo perfil).
# ≠ A_gpu assimétrico (E56). ≠ COMPROVA. ADR 0023: simetria GPU inviável até B60.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

TIMEOUT_SEC="${VERIFY_HARNESS_SYM_CPU_TIMEOUT:-${VERIFY_HARNESS_TIMEOUT:-300}}"

echo "IA_LIVRE_HARNESS_PROFILE=sym_cpu"

A_OUT="$(timeout "${TIMEOUT_SEC}s" ./scripts/run-harness-line-a.sh 2>&1)" || {
  echo "$A_OUT"
  echo "HARNESS_FAIL: line A (sym_cpu) exit ≠ 0" >&2
  exit 1
}
echo "$A_OUT"

B_OUT="$(timeout "${TIMEOUT_SEC}s" ./scripts/run-harness-line-b.sh 2>&1)" || {
  echo "$B_OUT"
  echo "HARNESS_FAIL: line B (sym_cpu) exit ≠ 0" >&2
  exit 1
}
echo "$B_OUT"

fail=0
grep -q 'IA_LIVRE_HARNESS_LINE=A' <<<"$A_OUT" || fail=1
grep -q 'IA_LIVRE_HARNESS_OK' <<<"$A_OUT" || fail=1
grep -q 'IA_LIVRE_HARNESS_ACCEL=cpu' <<<"$A_OUT" || fail=1
grep -q 'IA_LIVRE_HARNESS_LINE=B' <<<"$B_OUT" || fail=1
grep -q 'IA_LIVRE_HARNESS_OK' <<<"$B_OUT" || fail=1
grep -q 'IA_LIVRE_HARNESS_ACCEL=cpu' <<<"$B_OUT" || fail=1

# Anti-fraude: ninguém emite ACCEL GPU neste perfil
if grep -qE 'IA_LIVRE_HARNESS_ACCEL=(cuda|vulkan)' <<<"$A_OUT$B_OUT"; then
  echo "HARNESS_FAIL: sym_cpu não admite ACCEL GPU" >&2
  fail=1
fi

if (( fail )); then
  echo "IA_LIVRE_HARNESS_VERDICT=INCONCLUSIVO"
  echo "IA_LIVRE_HARNESS_VERDICT_REASON=sym_cpu_marcadores_ausentes"
  exit 1
fi

echo "IA_LIVRE_HARNESS_PROFILE=sym_cpu"
echo "IA_LIVRE_HARNESS_ACCEL_PAIR=cpu+cpu"
echo "IA_LIVRE_HARNESS_VERDICT=INCONCLUSIVO"
echo "IA_LIVRE_HARNESS_VERDICT_REASON=E64_sym_cpu_subset_species_bloqueio_final"
echo "IA_LIVRE_HARNESS_SYM_CPU_OK"
exit 0
