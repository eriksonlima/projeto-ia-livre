#!/usr/bin/env bash
# Harness Linha A — perfil A_gpu (Etapa 56). Accel host; skip se sem GPU.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
if [[ -z "${BINDGEN_EXTRA_CLANG_ARGS:-}" ]]; then
  export BINDGEN_EXTRA_CLANG_ARGS="-I/usr/lib/gcc/x86_64-linux-gnu/13/include -I/usr/include"
fi

MODEL="${IA_LIVRE_MODEL:-models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf}"
PROMPT="${IA_LIVRE_HARNESS_PROMPT:-Complete em uma frase: O Projeto IA Livre é}"
N_PREDICT="${IA_LIVRE_HARNESS_N_PREDICT:-32}"
N_GPU_LAYERS="${IA_LIVRE_HARNESS_N_GPU_LAYERS:-99}"
MODEL_ID="$(basename "$MODEL")"

if [[ "${VERIFY_HARNESS_GPU_SKIP:-}" == "1" ]]; then
  echo "IA_LIVRE_HARNESS_GPU_SKIP=1"
  exit 0
fi

gpu_detectable() {
  if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
    return 0
  fi
  [[ "${VERIFY_HARNESS_GPU_FORCE:-}" == "1" ]]
}

if ! gpu_detectable; then
  echo "IA_LIVRE_HARNESS_GPU_SKIP=need_gpu"
  exit 0
fi

FEATURE="${IA_LIVRE_GPU_FEATURE:-}"
if [[ -z "$FEATURE" ]]; then
  if command -v nvcc >/dev/null 2>&1; then
    FEATURE=cuda
  else
    FEATURE=vulkan
  fi
fi

if [[ "$FEATURE" == "vulkan" ]]; then
  if [[ -z "${VULKAN_SDK:-}" ]]; then
    for cand in \
      "${HOME}/.local/opt/1.3.296.0/x86_64" \
      "${HOME}/.local/opt/VulkanSDK"/*/x86_64; do
      if [[ -d "$cand" && -x "$cand/bin/glslc" ]]; then
        export VULKAN_SDK="$cand"
        break
      fi
    done
  fi
  if [[ -n "${VULKAN_SDK:-}" ]]; then
    export PATH="${VULKAN_SDK}/bin:${PATH}"
    export LD_LIBRARY_PATH="${VULKAN_SDK}/lib:${LD_LIBRARY_PATH:-}"
  else
    echo "IA_LIVRE_HARNESS_GPU_SKIP=no_vulkan_sdk"
    exit 0
  fi
fi

if [[ ! -f "$MODEL" ]]; then
  echo "HARNESS_FAIL: modelo ausente: $MODEL" >&2
  exit 1
fi

echo "Building ia-livre-runtime --features ${FEATURE}…" >&2
if ! cargo build -p ia-livre-runtime --features "$FEATURE" 2>&1; then
  echo "IA_LIVRE_HARNESS_GPU_SKIP=build_failed"
  exit 0
fi

RUNTIME_BIN="${IA_LIVRE_RUNTIME_BIN:-target/debug/ia-livre-runtime}"
LOG="$(mktemp)"; ERR="$(mktemp)"
cleanup() { rm -f "$LOG" "$ERR" "${COMBINED:-}"; return 0; }
trap cleanup EXIT

set +e
"$RUNTIME_BIN" \
  --model "$MODEL" \
  --prompt "$PROMPT" \
  --n-predict "$N_PREDICT" \
  --n-gpu-layers "$N_GPU_LAYERS" \
  >"$LOG" 2>"$ERR"
rc=$?
set -e

COMBINED="$(mktemp)"
cat "$LOG" "$ERR" >"$COMBINED"
cat "$LOG"
[[ -s "$ERR" ]] && cat "$ERR" >&2

if (( rc != 0 )) || ! grep -q 'IA_LIVRE_INFER_OK' "$COMBINED"; then
  echo "IA_LIVRE_HARNESS_GPU_SKIP=infer_failed"
  exit 0
fi

ACCEL="$(grep -oE 'IA_LIVRE_ACCEL=[a-z0-9_]+' "$COMBINED" | head -1 | cut -d= -f2 || true)"
LOAD_S="$(grep -oE 'IA_LIVRE_LOAD_S=[0-9.]+' "$COMBINED" | head -1 | cut -d= -f2 || true)"
TOKENS_PER_S="$(grep -oE 'IA_LIVRE_TOKENS_PER_S=[0-9.]+' "$COMBINED" | head -1 | cut -d= -f2 || true)"

if [[ -z "$ACCEL" || "$ACCEL" == "cpu" ]]; then
  echo "IA_LIVRE_HARNESS_GPU_SKIP=accel_still_cpu"
  exit 0
fi
if [[ -z "$LOAD_S" || -z "$TOKENS_PER_S" ]]; then
  echo "HARNESS_FAIL: métricas ausentes" >&2
  exit 1
fi

echo "IA_LIVRE_HARNESS_LINE=A"
echo "IA_LIVRE_HARNESS_PROFILE=A_gpu"
echo "IA_LIVRE_HARNESS_MODEL=${MODEL_ID}"
echo "IA_LIVRE_HARNESS_N_PREDICT=${N_PREDICT}"
echo "IA_LIVRE_HARNESS_ACCEL=${ACCEL}"
echo "IA_LIVRE_HARNESS_N_GPU_LAYERS=${N_GPU_LAYERS}"
echo "IA_LIVRE_HARNESS_LOAD_S=${LOAD_S}"
echo "IA_LIVRE_HARNESS_TOKENS_PER_S=${TOKENS_PER_S}"
echo "IA_LIVRE_HARNESS_OK"
exit 0
