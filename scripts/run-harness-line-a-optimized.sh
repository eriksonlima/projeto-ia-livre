#!/usr/bin/env bash
# Harness Linha A — perfil A_otimizada (Etapa 34).
# Mesma carga canônica que run-harness-line-a.sh + checklist de tuning honesto.
# Não prova a hipótese A vs B. A_default permanece em run-harness-line-a.sh.
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
N_GPU_LAYERS="${IA_LIVRE_HARNESS_N_GPU_LAYERS:-0}"
RUNTIME_BIN="${IA_LIVRE_RUNTIME_BIN:-target/debug/ia-livre-runtime}"
MODEL_ID="$(basename "$MODEL")"

NPROC="$(nproc 2>/dev/null || echo 2)"
if (( NPROC > 1 )); then
  DEFAULT_THREADS=$((NPROC - 1))
else
  DEFAULT_THREADS=1
fi
N_THREADS="${IA_LIVRE_HARNESS_N_THREADS:-$DEFAULT_THREADS}"

if [[ ! -f "$MODEL" ]]; then
  echo "HARNESS_FAIL: modelo ausente: $MODEL" >&2
  echo "Rode: ./scripts/fetch-model.sh" >&2
  exit 1
fi

if [[ ! -x "$RUNTIME_BIN" ]]; then
  echo "Building ia-livre-runtime…" >&2
  cargo build -p ia-livre-runtime
fi

# --- Checklist A_otimizada (skip honesto se sem permissão) ---
GOVERNOR_STATUS="SKIP"
if [[ "${IA_LIVRE_HARNESS_GOVERNOR_SKIP:-0}" == "1" ]]; then
  GOVERNOR_STATUS="SKIP"
elif command -v cpupower >/dev/null 2>&1; then
  if cpupower frequency-set -g performance >/dev/null 2>&1; then
    GOVERNOR_STATUS="OK"
  else
    GOVERNOR_STATUS="SKIP"
  fi
elif [[ -d /sys/devices/system/cpu/cpu0/cpufreq ]]; then
  # Tentativa best-effort em todos os CPUs (pode falhar sem root)
  ok=1
  for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    if ! echo performance >"$g" 2>/dev/null; then
      ok=0
      break
    fi
  done
  if (( ok )); then
    GOVERNOR_STATUS="OK"
  else
    GOVERNOR_STATUS="SKIP"
  fi
fi

TASKSET_STATUS="SKIP"
TASKSET_PREFIX=()
if [[ -n "${IA_LIVRE_HARNESS_TASKSET_CPUS:-}" ]] && command -v taskset >/dev/null 2>&1; then
  TASKSET_PREFIX=(taskset -c "${IA_LIVRE_HARNESS_TASKSET_CPUS}")
  TASKSET_STATUS="OK"
fi

THERMAL_STATUS="SKIP"
THERMAL_NOTE=""
if [[ -r /sys/class/thermal/thermal_zone0/temp ]]; then
  millideg="$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || true)"
  if [[ -n "$millideg" ]]; then
    THERMAL_STATUS="OK"
    THERMAL_NOTE="$((millideg / 1000))C"
  fi
fi

LOG="$(mktemp)"
ERR="$(mktemp)"
COMBINED="$(mktemp)"
trap 'rm -f "$LOG" "$ERR" "$COMBINED"' EXIT

set +e
"${TASKSET_PREFIX[@]}" "$RUNTIME_BIN" \
  --model "$MODEL" \
  --prompt "$PROMPT" \
  --n-predict "$N_PREDICT" \
  --n-gpu-layers "$N_GPU_LAYERS" \
  --n-threads "$N_THREADS" \
  >"$LOG" 2>"$ERR"
rc=$?
set -e

cat "$LOG" "$ERR" >"$COMBINED"

cat "$LOG"
if [[ -s "$ERR" ]]; then
  cat "$ERR" >&2
fi

if (( rc != 0 )); then
  echo "HARNESS_FAIL: runtime exit $rc" >&2
  exit "$rc"
fi

if ! grep -q 'IA_LIVRE_INFER_OK' "$COMBINED"; then
  echo "HARNESS_FAIL: runtime sem IA_LIVRE_INFER_OK" >&2
  exit 1
fi

LOAD_S="$(grep -oE 'IA_LIVRE_LOAD_S=[0-9.]+' "$COMBINED" | head -n1 | cut -d= -f2)"
TOKENS_PER_S="$(grep -oE 'IA_LIVRE_TOKENS_PER_S=[0-9.]+' "$COMBINED" | head -n1 | cut -d= -f2)"

if [[ -z "$LOAD_S" || -z "$TOKENS_PER_S" ]]; then
  echo "HARNESS_FAIL: métricas load/tokens ausentes na saída do runtime" >&2
  exit 1
fi

echo "IA_LIVRE_HARNESS_LINE=A"
echo "IA_LIVRE_HARNESS_PROFILE=A_otimizada"
echo "IA_LIVRE_HARNESS_THREADS=${N_THREADS}"
echo "IA_LIVRE_HARNESS_GOVERNOR=${GOVERNOR_STATUS}"
echo "IA_LIVRE_HARNESS_TASKSET=${TASKSET_STATUS}"
echo "IA_LIVRE_HARNESS_THERMAL=${THERMAL_STATUS}${THERMAL_NOTE:+:${THERMAL_NOTE}}"
echo "IA_LIVRE_HARNESS_MODEL=${MODEL_ID}"
echo "IA_LIVRE_HARNESS_N_PREDICT=${N_PREDICT}"
echo "IA_LIVRE_HARNESS_ACCEL=cpu"
echo "IA_LIVRE_HARNESS_LOAD_S=${LOAD_S}"
echo "IA_LIVRE_HARNESS_TOKENS_PER_S=${TOKENS_PER_S}"
echo "IA_LIVRE_HARNESS_OK"
exit 0
