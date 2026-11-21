#!/usr/bin/env bash
# Stub host do GPU manager (Etapa 25 / B19) — NÃO é manager nativo / Linha B.
# Emite enum + placement hint + shard documentado. Sem offload; sem fingir multi-GPU.
set -euo pipefail

count_devices() {
  if command -v nvidia-smi >/dev/null 2>&1; then
    # Conta linhas "GPU N:" — 0 se falhar
    local n
    n="$(nvidia-smi -L 2>/dev/null | grep -c '^GPU ' || true)"
    echo "${n:-0}"
    return
  fi
  echo "0"
}

DEVICES="$(count_devices)"

echo "IA_LIVRE_GPU_MGR=host_stub"
echo "IA_LIVRE_GPU_DEVICES=${DEVICES}"
# Hint estável de afinidade/placement (contrato ADR 0006); não implica offload.
echo "IA_LIVRE_GPU_PLACE_HINT=device0|weights"
# Estratégia preferida documentada — não executa shard.
echo "IA_LIVRE_GPU_SHARD_DOC=pipeline_layer"
echo "IA_LIVRE_GPU_MGR_OK"
exit 0
