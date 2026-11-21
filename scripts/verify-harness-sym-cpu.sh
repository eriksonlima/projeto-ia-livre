#!/usr/bin/env bash
# Gate Etapa 64: perfil sym_cpu (A+B ACCEL=cpu). Opt-in; ≠ verify-harness-gpu.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

test -f docs/adr/0023-simetria-gpu-harness-inviavel.md
test -f docs/harness-perfis-a-otimizada-gpu.md
test -f scripts/run-harness-a-b-sym-cpu.sh
chmod +x scripts/run-harness-a-b-sym-cpu.sh

out="$(./scripts/run-harness-a-b-sym-cpu.sh 2>&1)" || {
  echo "GATE_FAIL: run-harness-a-b-sym-cpu exit ≠ 0"
  echo "$out"
  exit 1
}
echo "$out"

fail=0
grep -q 'IA_LIVRE_HARNESS_PROFILE=sym_cpu' <<<"$out" || fail=1
grep -q 'IA_LIVRE_HARNESS_ACCEL_PAIR=cpu+cpu' <<<"$out" || fail=1
grep -q 'IA_LIVRE_HARNESS_VERDICT=INCONCLUSIVO' <<<"$out" || fail=1
grep -q 'IA_LIVRE_HARNESS_SYM_CPU_OK' <<<"$out" || fail=1

if grep -qE 'IA_LIVRE_HARNESS_VERDICT=(COMPROVA|REFUTA)' <<<"$out"; then
  echo "GATE_FAIL: sym_cpu não pode COMPROVA/REFUTA"
  fail=1
fi
if grep -qE 'IA_LIVRE_HARNESS_ACCEL=(cuda|vulkan)' <<<"$out"; then
  echo "GATE_FAIL: ACCEL GPU em sym_cpu"
  fail=1
fi

if (( fail )); then
  exit 1
fi

echo "GATE_OK: harness-sym-cpu — A+B ACCEL=cpu (E64; ADR 0023; ≠ A_gpu assimétrico)"
exit 0
