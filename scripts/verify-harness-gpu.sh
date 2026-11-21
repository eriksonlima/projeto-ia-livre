#!/usr/bin/env bash
# Gate Etapa 56: perfil A_gpu + B honesto, ou skip. Não substitui verify-harness.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

test -f docs/harness-perfis-a-otimizada-gpu.md
test -f scripts/run-harness-line-a-gpu.sh
test -f scripts/run-harness-a-b-gpu.sh
chmod +x scripts/run-harness-line-a-gpu.sh scripts/run-harness-a-b-gpu.sh

# Skip forçado
if [[ "${VERIFY_HARNESS_GPU_SKIP:-}" == "1" ]]; then
  out="$(VERIFY_HARNESS_GPU_SKIP=1 ./scripts/run-harness-line-a-gpu.sh 2>&1)" || true
  echo "$out"
  grep -q 'IA_LIVRE_HARNESS_GPU_SKIP' <<<"$out" || { echo "GATE_FAIL: SKIP=1 sem marcador"; exit 1; }
  echo "GATE_OK: harness-gpu — SKIP forçado (Etapa 56)"
  exit 0
fi

out="$(./scripts/run-harness-a-b-gpu.sh 2>&1)" || {
  echo "GATE_FAIL: run-harness-a-b-gpu exit ≠ 0"
  echo "$out"
  exit 1
}
echo "$out"

if grep -q 'IA_LIVRE_HARNESS_GPU_SKIP=' <<<"$out"; then
  echo "GATE_OK: harness-gpu — skip honesto (Etapa 56)"
  exit 0
fi

fail=0
grep -q 'IA_LIVRE_HARNESS_PROFILE=A_gpu' <<<"$out" || fail=1
grep -qE 'IA_LIVRE_HARNESS_ACCEL=(cuda|vulkan)' <<<"$out" || fail=1
grep -q 'IA_LIVRE_HARNESS_OK' <<<"$out" || fail=1
grep -q 'IA_LIVRE_HARNESS_LINE=B' <<<"$out" || fail=1
grep -q 'IA_LIVRE_HARNESS_VERDICT=INCONCLUSIVO' <<<"$out" || fail=1
grep -q 'IA_LIVRE_HARNESS_GPU_OK' <<<"$out" || fail=1

# Anti-fraude
grep -qE 'IA_LIVRE_HARNESS_VERDICT=(COMPROVA|REFUTA)' <<<"$out" && {
  echo "GATE_FAIL: perfil GPU não pode COMPROVA/REFUTA"
  fail=1
}
# B não com ACCEL GPU (já no runner; recheck)
b_accel="$(grep 'IA_LIVRE_HARNESS_LINE=B' -A20 <<<"$out" | grep -oE 'IA_LIVRE_HARNESS_ACCEL=[a-z]+' | head -1 || true)"
if [[ "$b_accel" == *=cuda || "$b_accel" == *=vulkan ]]; then
  echo "GATE_FAIL: B com ACCEL GPU"
  fail=1
fi

if (( fail )); then
  exit 1
fi

echo "GATE_OK: harness-gpu — A_gpu + B INCONCLUSIVO (Etapa 56)"
exit 0
