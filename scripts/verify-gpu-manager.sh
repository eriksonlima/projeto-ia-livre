#!/usr/bin/env bash
# Gate Etapa 25: stub host do GPU manager (enum/placement/shard doc).
# Skip honesto (CI / sem GPU): VERIFY_GPU_MANAGER_SKIP=1 ou GPU indetectável
# → IA_LIVRE_GPU_MGR_SKIP e exit 0 (não finge multi-GPU nem aceleração).
# NÃO altera make verify-runtime-gpu / IA_LIVRE_GPU_SKIP (Etapa 8).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

gpu_detectable() {
  if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
    return 0
  fi
  if [[ "${VERIFY_GPU_MANAGER_FORCE:-}" == "1" ]]; then
    return 0
  fi
  return 1
}

if [[ "${VERIFY_GPU_MANAGER_SKIP:-}" == "1" ]]; then
  echo "IA_LIVRE_GPU_MGR_SKIP"
  echo "GATE_SKIP: VERIFY_GPU_MANAGER_SKIP=1 (CI / host sem prova do stub GPU manager)"
  exit 0
fi

if ! gpu_detectable; then
  echo "IA_LIVRE_GPU_MGR_SKIP"
  echo "GATE_SKIP: GPU indetectável (nvidia-smi falhou; VERIFY_GPU_MANAGER_FORCE=1 para forçar stub)"
  exit 0
fi

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

./scripts/gpu-manager-stub.sh >"$LOG"

fail=0
for marker in \
  'IA_LIVRE_GPU_MGR=host_stub' \
  'IA_LIVRE_GPU_DEVICES=' \
  'IA_LIVRE_GPU_PLACE_HINT=' \
  'IA_LIVRE_GPU_SHARD_DOC=pipeline_layer' \
  'IA_LIVRE_GPU_MGR_OK'; do
  if ! grep -q "$marker" "$LOG"; then
    echo "GATE_FAIL: marcador ausente: $marker"
    fail=1
  fi
done

mgr="$(grep -E '^IA_LIVRE_GPU_MGR=' "$LOG" | tail -n1 | cut -d= -f2- || true)"
if [[ "$mgr" != "host_stub" ]]; then
  echo "GATE_FAIL: esperava IA_LIVRE_GPU_MGR=host_stub (obtido: '${mgr:-<vazio>}')"
  fail=1
fi

devices="$(grep -E '^IA_LIVRE_GPU_DEVICES=' "$LOG" | tail -n1 | cut -d= -f2- || true)"
if ! [[ "$devices" =~ ^[0-9]+$ ]]; then
  echo "GATE_FAIL: IA_LIVRE_GPU_DEVICES não numérico: '${devices:-<vazio>}'"
  fail=1
fi
# Com GPU detectável, N≥1 é o esperado; N=0 seria inconsistente (não inventar devices).
if (( devices < 1 )) && [[ "${VERIFY_GPU_MANAGER_FORCE:-}" != "1" ]]; then
  echo "GATE_FAIL: GPU detectável mas IA_LIVRE_GPU_DEVICES=${devices} (esperado ≥1)"
  fail=1
fi

if (( fail )); then
  echo "---- saída do stub ----"
  cat "$LOG" || true
  exit 1
fi

echo "GATE_OK: gpu-manager stub — $(tr '\n' ' ' <"$LOG")"
exit 0
