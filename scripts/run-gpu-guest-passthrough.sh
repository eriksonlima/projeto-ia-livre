#!/usr/bin/env bash
# GPU guest PCI/VFIO (Etapa 65). ≠ SRC=host (E55). ≠ synthetic (E38).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

FORCE_SKIP="${VERIFY_GPU_GUEST_SKIP:-0}"

count_host_gpu() {
  if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi -L 2>/dev/null | grep -c '^GPU ' || true
    return
  fi
  echo "0"
}

count_vfio_groups() {
  local n=0
  if [[ -d /dev/vfio ]]; then
    n="$(find /dev/vfio -maxdepth 1 -type c ! -name vfio 2>/dev/null | wc -l | tr -d ' ')"
  fi
  echo "${n:-0}"
}

vfio_pci_bound() {
  find /sys/bus/pci/drivers/vfio-pci -maxdepth 1 -name '0000:*' 2>/dev/null | head -1
}

DEVICES="$(count_host_gpu)"
DEVICES="${DEVICES//[^0-9]/}"
DEVICES="${DEVICES:-0}"
VFIO_N="$(count_vfio_groups)"
VFIO_N="${VFIO_N//[^0-9]/}"
VFIO_N="${VFIO_N:-0}"
BOUND="$(vfio_pci_bound || true)"

if [[ "$FORCE_SKIP" == "1" ]]; then
  echo "IA_LIVRE_GPU_NEED_GPU=need_vfio"
  echo "IA_LIVRE_GPU_VFIO_GROUPS=${VFIO_N}"
  exit 0
fi

if [[ "$DEVICES" -lt 1 ]]; then
  echo "IA_LIVRE_GPU_NEED_GPU=need_gpu"
  echo "IA_LIVRE_GPU_VFIO_GROUPS=${VFIO_N}"
  exit 0
fi

# GPU no host sem VFIO binding → ainda não é guest passthrough
if [[ -z "$BOUND" || "$VFIO_N" -lt 1 ]]; then
  echo "IA_LIVRE_GPU_NEED_GPU=need_vfio"
  echo "IA_LIVRE_GPU_VFIO_GROUPS=${VFIO_N}"
  echo "IA_LIVRE_GPU_HOST_DEVICES=${DEVICES}"
  exit 0
fi

# Evidência VFIO real
echo "IA_LIVRE_GPU_REAL_SRC=pci_passthrough"
echo "IA_LIVRE_GPU_REAL_DEVICES=${DEVICES}"
echo "IA_LIVRE_GPU_VFIO_GROUPS=${VFIO_N}"
echo "IA_LIVRE_GPU_REAL_PLACE_HINT=device0|weights"
echo "IA_LIVRE_GPU_REAL_OK"
exit 0
