#!/usr/bin/env bash
# Gate Etapa 65: pci_passthrough + REAL_OK OU skip need_gpu/need_vfio.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

test -f docs/gpu-guest-passthrough.md
test -f docs/adr/0023-simetria-gpu-harness-inviavel.md
test -f scripts/run-gpu-guest-passthrough.sh
chmod +x scripts/run-gpu-guest-passthrough.sh

out="$(./scripts/run-gpu-guest-passthrough.sh 2>&1)" || {
  echo "GATE_FAIL: runner exit ≠ 0"
  echo "$out"
  exit 1
}
echo "$out"

# Anti-fraude: REAL_OK exige SRC=pci_passthrough (não host)
if grep -q 'IA_LIVRE_GPU_REAL_OK' <<<"$out"; then
  grep -q 'IA_LIVRE_GPU_REAL_SRC=pci_passthrough' <<<"$out" \
    || { echo "GATE_FAIL: REAL_OK sem SRC=pci_passthrough"; exit 1; }
  if grep -q 'IA_LIVRE_GPU_REAL_SRC=host' <<<"$out"; then
    echo "GATE_FAIL: E65 não aceita SRC=host como sucesso"
    exit 1
  fi
  echo "GATE_OK: gpu-guest-passthrough — pci_passthrough + REAL_OK (E65)"
  exit 0
fi

# Skip honesto
if grep -qE 'IA_LIVRE_GPU_NEED_GPU=(need_gpu|need_vfio)' <<<"$out"; then
  echo "GATE_OK: gpu-guest-passthrough — skip honesto (E65; ≠ REAL_OK fingido)"
  exit 0
fi

echo "GATE_FAIL: nem REAL_OK/pci_passthrough nem NEED_GPU skip"
exit 1
