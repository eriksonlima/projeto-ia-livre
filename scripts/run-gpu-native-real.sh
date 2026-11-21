#!/usr/bin/env bash
# GPU real no caminho nativo (Etapa 55). Path B: host + âncora E38.
# ≠ host_stub E25; ≠ synthetic-as-success.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

ANCHOR="${IA_LIVRE_GPU_REAL_ANCHOR:-docs/evidence/gpu/serial-native-synthetic-fixture.txt}"
FORCE_SKIP="${VERIFY_GPU_REAL_SKIP:-0}"

count_devices() {
  if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi -L 2>/dev/null | grep -c '^GPU ' || true
    return
  fi
  echo "0"
}

# Âncora contrato nativo E38 (não prova realidade)
if [[ ! -f "$ANCHOR" ]]; then
  echo "erro: âncora E38 ausente: $ANCHOR" >&2
  exit 1
fi
grep -q 'IA_LIVRE_GPU_MGR=native' "$ANCHOR" \
  || { echo "erro: âncora sem GPU_MGR=native" >&2; exit 1; }

DEVICES="$(count_devices)"
DEVICES="${DEVICES//[^0-9]/}"
DEVICES="${DEVICES:-0}"

if [[ "$FORCE_SKIP" == "1" ]] || [[ "$DEVICES" -lt 1 ]]; then
  echo "IA_LIVRE_GPU_NEED_GPU=need_gpu"
  exit 0
fi

# GPU real no host
echo "IA_LIVRE_GPU_REAL_SRC=host"
echo "IA_LIVRE_GPU_REAL_DEVICES=${DEVICES}"
echo "IA_LIVRE_GPU_REAL_PLACE_HINT=device0|weights"
echo "IA_LIVRE_GPU_REAL_PLACE_HINT=device0|kvcache"
# Nome amigável (opcional)
if command -v nvidia-smi >/dev/null 2>&1; then
  name="$(nvidia-smi -L 2>/dev/null | head -1 | sed 's/^GPU [0-9]*: //;s/ (UUID.*//' || true)"
  [[ -n "$name" ]] && echo "IA_LIVRE_GPU_REAL_DEV0_NAME=${name}"
fi
echo "IA_LIVRE_GPU_REAL_OK"
exit 0
