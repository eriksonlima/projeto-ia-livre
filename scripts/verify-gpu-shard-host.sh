#!/usr/bin/env bash
# Gate Etapa 41: shard multi-GPU host — EXEC_OK (≥2 GPUs) ou SKIP honesto.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

./scripts/run-gpu-shard-host.sh >"$LOG" 2>&1 || {
  echo "GATE_FAIL: run-gpu-shard-host exit $?"
  cat "$LOG" || true
  exit 1
}

if ! grep -q 'IA_LIVRE_GPU_MGR=host_shard_exec' "$LOG"; then
  echo "GATE_FAIL: identidade host_shard_exec ausente"
  cat "$LOG" || true
  exit 1
fi

if grep -q 'IA_LIVRE_GPU_SHARD_SKIP' "$LOG"; then
  if grep -q 'IA_LIVRE_GPU_SHARD_EXEC_OK' "$LOG"; then
    echo "GATE_FAIL: SKIP e EXEC_OK juntos (fraude)"
    cat "$LOG" || true
    exit 1
  fi
  if ! grep -q 'IA_LIVRE_GPU_SHARD_SKIP_REASON=' "$LOG"; then
    echo "GATE_FAIL: SKIP sem motivo"
    cat "$LOG" || true
    exit 1
  fi
  echo "IA_LIVRE_GPU_SHARD_SKIP"
  echo "GATE_OK: shard host — skip honesto ($(grep -oE 'IA_LIVRE_GPU_SHARD_SKIP_REASON=[^[:space:]]+' "$LOG" | head -n1))"
  exit 0
fi

fail=0
for m in \
  'IA_LIVRE_GPU_SHARD_MODE=pipeline_layer' \
  'IA_LIVRE_GPU_SHARD_PLAN=0:0-10,1:11-21' \
  'IA_LIVRE_GPU_SHARD_DEVICE=0' \
  'IA_LIVRE_GPU_SHARD_DEVICE=1' \
  'IA_LIVRE_GPU_SHARD_RANGE=0-10' \
  'IA_LIVRE_GPU_SHARD_RANGE=11-21' \
  'IA_LIVRE_GPU_SHARD_EXEC_OK'
do
  if ! grep -q "$m" "$LOG"; then
    echo "GATE_FAIL: marcador ausente: $m"
    fail=1
  fi
done

if ! grep -qE 'IA_LIVRE_GPU_DEVICES=[2-9]|IA_LIVRE_GPU_DEVICES=[1-9][0-9]+' "$LOG"; then
  echo "GATE_FAIL: DEVICES≥2 ausente no caminho EXEC"
  fail=1
fi

if (( fail )); then
  cat "$LOG" || true
  exit 1
fi

echo "GATE_OK: shard host — EXEC_OK (pipeline_layer 2 devices)"
exit 0
