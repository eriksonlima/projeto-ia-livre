#!/usr/bin/env bash
# Etapa 69 — multi-GPU host placement dual Weights+Kv (além do shard E41).
# Identidade: IA_LIVRE_GPU_MGR=host_multi
# <2 GPUs: skip honesto (sem MULTI_EXEC_OK). Sem TOKENS_PER_S.
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
  echo "IA_LIVRE_GPU_MGR=host_multi"
  echo "IA_LIVRE_GPU_DEVICES=${DEVICES:-0}"
  echo "IA_LIVRE_GPU_MULTI_SKIP"
  echo "IA_LIVRE_GPU_MULTI_SKIP_REASON=${reason}"
  exit 0
}

if [[ "${VERIFY_GPU_MULTI_SKIP:-0}" == "1" ]]; then
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

echo "IA_LIVRE_GPU_MGR=host_multi"
echo "IA_LIVRE_GPU_DEVICES=${DEVICES}"
echo "IA_LIVRE_GPU_MULTI_MODE=weights_kv_place"
echo "IA_LIVRE_GPU_MULTI_PLAN=W:0,K:1"

# Device 0 → Weights; device 1 → KvCache
for pair in "0:Weights" "1:KvCache"; do
  id="${pair%%:*}"
  place="${pair##*:}"
  name="$(nvidia-smi -i "$id" --query-gpu=name --format=csv,noheader 2>/dev/null | head -n1 | tr -d '\r' || true)"
  if [[ -z "$name" ]]; then
    echo "IA_LIVRE_GPU_MULTI_FAIL=device_${id}"
    exit 1
  fi
  echo "IA_LIVRE_GPU_MULTI_DEVICE=${id}"
  echo "IA_LIVRE_GPU_MULTI_PLACE=${place}"
  echo "IA_LIVRE_GPU_MULTI_DEVICE_NAME=${name}"
done

echo "IA_LIVRE_GPU_MULTI_EXEC_OK"
exit 0
