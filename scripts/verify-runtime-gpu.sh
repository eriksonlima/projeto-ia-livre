#!/usr/bin/env bash
# Gate Etapa 8: runtime com offload GPU (IA_LIVRE_ACCEL ≠ cpu).
# Política de skip (CI / host sem GPU): VERIFY_RUNTIME_GPU_SKIP=1 ou GPU
# indetectável → imprime IA_LIVRE_GPU_SKIP e exit 0 (não finge aceleração).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
if [[ -z "${BINDGEN_EXTRA_CLANG_ARGS:-}" ]]; then
  export BINDGEN_EXTRA_CLANG_ARGS="-I/usr/lib/gcc/x86_64-linux-gnu/13/include -I/usr/include"
fi

MODEL="${IA_LIVRE_MODEL:-models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf}"
N_PREDICT="${IA_LIVRE_N_PREDICT:-32}"
N_GPU_LAYERS="${IA_LIVRE_N_GPU_LAYERS:-99}"
TIMEOUT_SEC="${VERIFY_RUNTIME_GPU_TIMEOUT:-300}"

gpu_detectable() {
  if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
    return 0
  fi
  # Force explícito (ex.: só Vulkan sem nvidia-smi)
  if [[ "${VERIFY_RUNTIME_GPU_FORCE:-}" == "1" ]]; then
    return 0
  fi
  return 1
}

choose_feature() {
  if [[ -n "${IA_LIVRE_GPU_FEATURE:-}" ]]; then
    echo "$IA_LIVRE_GPU_FEATURE"
    return
  fi
  # CUDA canônico se toolkit presente; senão Vulkan (ADR 0002)
  if command -v nvcc >/dev/null 2>&1; then
    echo "cuda"
  else
    echo "vulkan"
  fi
}

if [[ "${VERIFY_RUNTIME_GPU_SKIP:-}" == "1" ]]; then
  echo "IA_LIVRE_GPU_SKIP"
  echo "GATE_SKIP: VERIFY_RUNTIME_GPU_SKIP=1 (CI / host sem prova GPU)"
  exit 0
fi

if ! gpu_detectable; then
  echo "IA_LIVRE_GPU_SKIP"
  echo "GATE_SKIP: GPU indetectável (nvidia-smi falhou; defina VERIFY_RUNTIME_GPU_FORCE=1 se Vulkan-only)"
  exit 0
fi

FEATURE="$(choose_feature)"
echo "GPU feature: ${FEATURE} (override: IA_LIVRE_GPU_FEATURE=cuda|vulkan)"

# Vulkan user-space SDK (host de referência)
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
    echo "VULKAN_SDK=${VULKAN_SDK}"
  else
    echo "GATE_FAIL: feature vulkan sem VULKAN_SDK (glslc). Instale LunarG SDK ou defina VULKAN_SDK=…"
    exit 1
  fi
fi

if [[ ! -f "$MODEL" ]]; then
  echo "GATE_FAIL: modelo ausente: $MODEL"
  echo "Rode: ./scripts/fetch-model.sh"
  exit 1
fi

echo "Building ia-livre-runtime --features ${FEATURE}…"
cargo build -p ia-livre-runtime --features "$FEATURE"

LOG="$(mktemp)"
ERR="$(mktemp)"
COMBINED="$(mktemp)"
trap 'rm -f "$LOG" "$ERR" "$COMBINED"' EXIT

echo "Running GPU inference (n-gpu-layers=${N_GPU_LAYERS}, timeout ${TIMEOUT_SEC}s)…"
set +e
timeout "${TIMEOUT_SEC}s" cargo run -q -p ia-livre-runtime --features "$FEATURE" -- \
  --model "$MODEL" --n-predict "$N_PREDICT" --n-gpu-layers "$N_GPU_LAYERS" \
  >"$LOG" 2>"$ERR"
rc=$?
set -e

cat "$LOG" "$ERR" >"$COMBINED"

if (( rc == 124 )); then
  echo "GATE_FAIL: timeout após ${TIMEOUT_SEC}s"
  tail -n 40 "$COMBINED" || true
  exit 1
fi
if (( rc != 0 )); then
  echo "GATE_FAIL: runtime exit $rc"
  tail -n 80 "$COMBINED" || true
  exit 1
fi

fail=0
for marker in IA_LIVRE_INFER_OK IA_LIVRE_LOAD_S= IA_LIVRE_TOKENS_PER_S= IA_LIVRE_ACCEL= IA_LIVRE_N_GPU_LAYERS=; do
  if ! grep -q "$marker" "$COMBINED"; then
    echo "GATE_FAIL: marcador ausente: $marker"
    fail=1
  fi
done

accel="$(grep -E '^IA_LIVRE_ACCEL=' "$COMBINED" | tail -n1 | cut -d= -f2- || true)"
if [[ -z "$accel" || "$accel" == "cpu" ]]; then
  echo "GATE_FAIL: esperava IA_LIVRE_ACCEL ≠ cpu (obtido: '${accel:-<vazio>}')"
  fail=1
fi

# Coerência leve com a feature pedida
if [[ "$FEATURE" == "cuda" && "$accel" != "cuda" ]]; then
  echo "GATE_FAIL: feature cuda mas IA_LIVRE_ACCEL=${accel}"
  fail=1
fi
if [[ "$FEATURE" == "vulkan" && "$accel" != "vulkan" ]]; then
  echo "GATE_FAIL: feature vulkan mas IA_LIVRE_ACCEL=${accel}"
  fail=1
fi

if (( fail )); then
  echo "---- saída (últimas 80 linhas) ----"
  tail -n 80 "$COMBINED" || true
  exit 1
fi

echo "GATE_OK: runtime GPU — $(grep -E 'IA_LIVRE_(INFER_OK|ACCEL=|LOAD_S=|TOKENS_PER_S=|N_GPU_LAYERS=)' "$COMBINED" | tr '\n' ' ')"
exit 0
