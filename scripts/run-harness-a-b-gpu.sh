#!/usr/bin/env bash
# Agregação A_gpu + B (Etapa 56). B sem ACCEL GPU fingido; veredito INCONCLUSIVO.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

A_OUT="$(./scripts/run-harness-line-a-gpu.sh 2>&1)" || {
  echo "$A_OUT"
  echo "HARNESS_FAIL: A_gpu exit ≠ 0" >&2
  exit 1
}
echo "$A_OUT"

if grep -q 'IA_LIVRE_HARNESS_GPU_SKIP=' <<<"$A_OUT"; then
  echo "IA_LIVRE_HARNESS_GPU_SKIP=$(grep -oE 'IA_LIVRE_HARNESS_GPU_SKIP=[^[:space:]]+' <<<"$A_OUT" | head -1 | cut -d= -f2)"
  echo "IA_LIVRE_HARNESS_GPU_PROFILE=A_gpu"
  exit 0
fi

# B: reusa harness B existente (subset / proxy — sem inventar ACCEL)
B_OUT="$(./scripts/run-harness-line-b.sh 2>&1)" || {
  echo "$B_OUT"
  echo "HARNESS_FAIL: line B exit ≠ 0" >&2
  exit 1
}
echo "$B_OUT"

# Anti-fraude: B não deve afirmar ACCEL GPU
if grep -qE 'IA_LIVRE_HARNESS_ACCEL=(cuda|vulkan)' <<<"$B_OUT"; then
  echo "HARNESS_FAIL: B não pode emitir ACCEL GPU" >&2
  exit 1
fi

echo "IA_LIVRE_HARNESS_GPU_PROFILE=A_gpu+B"
echo "IA_LIVRE_HARNESS_VERDICT=INCONCLUSIVO"
echo "IA_LIVRE_HARNESS_VERDICT_REASON=E56_A_gpu_B_subset_accel_asymmetric"
echo "IA_LIVRE_HARNESS_GPU_OK"
exit 0
