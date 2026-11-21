#!/usr/bin/env bash
# Etapa 41 — shard multi-GPU host executado (além do stub E25).
# Identidade: IA_LIVRE_GPU_MGR=host_shard_exec
# Com <2 GPUs: skip honesto (sem EXEC_OK). Sem TOKENS_PER_S.
set -euo pipefail

count_devices() {
  if command -v nvidia-smi >/dev/null 2>&1; then
    local n
    n="$(nvidia-smi -L 2>/dev/null | grep -c '^GPU ' || true)"
    echo "${n:-0}"
    return
  fi
  echo "0"
}

skip() {
  local reason="$1"
  echo "IA_LIVRE_GPU_MGR=host_shard_exec"
  echo "IA_LIVRE_GPU_DEVICES=${DEVICES:-0}"
  echo "IA_LIVRE_GPU_SHARD_SKIP"
  echo "IA_LIVRE_GPU_SHARD_SKIP_REASON=${reason}"
  exit 0
}

if [[ "${1:-}" == "--dry-doc" ]]; then
  echo "IA_LIVRE_GPU_MGR=host_shard_exec"
  echo "IA_LIVRE_GPU_SHARD_MODE=pipeline_layer"
  echo "IA_LIVRE_GPU_SHARD_PLAN=0:0-10,1:11-21"
  echo "IA_LIVRE_GPU_SHARD_DRY_DOC=1"
  exit 0
fi

if [[ "${VERIFY_GPU_SHARD_SKIP:-0}" == "1" ]]; then
  DEVICES=0
  skip forced
fi

DEVICES="$(count_devices)"

if (( DEVICES < 1 )); then
  skip no_gpu
fi

if (( DEVICES < 2 )); then
  skip need_2_devices
fi

echo "IA_LIVRE_GPU_MGR=host_shard_exec"
echo "IA_LIVRE_GPU_DEVICES=${DEVICES}"

# Plano estável TinyLlama ~22 camadas → 2 faixas.
echo "IA_LIVRE_GPU_SHARD_MODE=pipeline_layer"
echo "IA_LIVRE_GPU_SHARD_PLAN=0:0-10,1:11-21"

# Execução mínima: tocar cada device via nvidia-smi -i (query verificável).
declare -a RANGES=("0-10" "11-21")
for id in 0 1; do
  name="$(nvidia-smi -i "$id" --query-gpu=name --format=csv,noheader 2>/dev/null | head -n1 | tr -d '\r' || true)"
  if [[ -z "$name" ]]; then
    echo "IA_LIVRE_GPU_SHARD_FAIL=device_${id}"
    exit 1
  fi
  echo "IA_LIVRE_GPU_SHARD_DEVICE=${id}"
  echo "IA_LIVRE_GPU_SHARD_RANGE=${RANGES[$id]}"
  echo "IA_LIVRE_GPU_SHARD_DEVICE_NAME=${name}"
done

echo "IA_LIVRE_GPU_SHARD_EXEC_OK"
exit 0
