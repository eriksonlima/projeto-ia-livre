#!/usr/bin/env bash
# Gate Etapa 91 / B86 — GPU opcional na imagem (docs + skip honesto).
set -euo pipefail
cd "$(dirname "$0")/.."

test -f docs/linux-ia-nativo-gpu.md
grep -q 'GPU\|cuda\|vulkan\|skip' docs/linux-ia-nativo-gpu.md
grep -q 'linux-ia-nativo-gpu\|GPU opcional' docs/linux-ia-nativo.md

if [[ "${VERIFY_DISTRO_GPU_SKIP:-0}" == "1" ]]; then
  echo "IA_LIVRE_DISTRO_GPU_SKIP=forced"
  echo "IA_LIVRE_DISTRO_GPU_OK"
  exit 0
fi

if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
  echo "IA_LIVRE_DISTRO_GPU_DETECT=nvidia"
  echo "IA_LIVRE_DISTRO_GPU_NOTE=host_detect_only_image_docs"
else
  echo "IA_LIVRE_DISTRO_GPU_SKIP=need_gpu"
fi
echo "IA_LIVRE_DISTRO_GPU_OK"
echo "GATE_OK: distro-gpu-optional — docs + skip honesto"
exit 0
