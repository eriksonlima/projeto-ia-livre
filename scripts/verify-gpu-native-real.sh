#!/usr/bin/env bash
# Gate Etapa 55: GPU real (host) ou skip need_gpu. ≠ E25 stub; ≠ synthetic-as-OK.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

test -f docs/gpu-real-nativo.md
test -f scripts/run-gpu-native-real.sh
test -f docs/evidence/gpu/serial-native-synthetic-fixture.txt
chmod +x scripts/run-gpu-native-real.sh

fail=0
out="$(./scripts/run-gpu-native-real.sh 2>&1)" || {
  echo "GATE_FAIL: run-gpu-native-real exit ≠ 0"
  echo "$out"
  exit 1
}
echo "$out"

if grep -q 'IA_LIVRE_GPU_NEED_GPU=' <<<"$out"; then
  if grep -q 'IA_LIVRE_GPU_REAL_OK' <<<"$out"; then
    echo "GATE_FAIL: NEED_GPU não pode coexistem com REAL_OK"
    fail=1
  fi
  # Skip honesto OK
  if (( fail == 0 )); then
    echo "GATE_OK: gpu-native-real — NEED_GPU skip (Etapa 55)"
    exit 0
  fi
fi

grep -q 'IA_LIVRE_GPU_REAL_SRC=host' <<<"$out" \
  || grep -q 'IA_LIVRE_GPU_REAL_SRC=pci_passthrough' <<<"$out" \
  || { echo "GATE_FAIL: SRC ausente"; fail=1; }
grep -q 'IA_LIVRE_GPU_REAL_OK' <<<"$out" || { echo "GATE_FAIL: REAL_OK ausente"; fail=1; }
grep -qE 'IA_LIVRE_GPU_REAL_DEVICES=[1-9]' <<<"$out" || { echo "GATE_FAIL: DEVICES≥1 ausente"; fail=1; }

# Anti-fraude: não emitir host_stub neste path
if grep -q 'IA_LIVRE_GPU_MGR=host_stub' <<<"$out"; then
  echo "GATE_FAIL: path E55 não deve emitir host_stub"
  fail=1
fi
# Anti-fraude: REAL_OK não pode vir só de synthetic no mesmo stream de sucesso
if grep -q 'IA_LIVRE_GPU_DEV0_KIND=synthetic' <<<"$out" && grep -q 'IA_LIVRE_GPU_REAL_OK' <<<"$out"; then
  echo "GATE_FAIL: REAL_OK com KIND=synthetic no mesmo output"
  fail=1
fi
# Sem multi-GPU fingido se DEVICES=1 com claim ≥2 — apenas checa coerência
devs="$(grep -oE 'IA_LIVRE_GPU_REAL_DEVICES=[0-9]+' <<<"$out" | head -1 | cut -d= -f2 || echo 0)"
if [[ "${devs:-0}" -ge 2 ]]; then
  # Permitido se nvidia-smi realmente reportar ≥2; não inventamos
  true
fi

# Forçar skip deve emitir NEED_GPU sem REAL_OK
skip_out="$(VERIFY_GPU_REAL_SKIP=1 ./scripts/run-gpu-native-real.sh 2>&1)" || true
grep -q 'IA_LIVRE_GPU_NEED_GPU=' <<<"$skip_out" || { echo "GATE_FAIL: SKIP=1 sem NEED_GPU"; fail=1; }
grep -q 'IA_LIVRE_GPU_REAL_OK' <<<"$skip_out" && { echo "GATE_FAIL: SKIP=1 emitiu REAL_OK"; fail=1; }

if (( fail )); then
  exit 1
fi

echo "GATE_OK: gpu-native-real — SRC + REAL_OK (Etapa 55; ≠ synthetic; ≠ host_stub)"
exit 0
