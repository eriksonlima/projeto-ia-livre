#!/usr/bin/env bash
# Gate Etapa 59 — evidência de otimização + desfecho A (passo no gate) ou B (ADR 0020).
# Não exige COMPROVA; não inventa TOKENS_PER_S; host ≠ guest.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

test -f docs/runtime-native-perf-especie.md
test -f docs/adr/0016-veredito-limpo-harness-a-b.md
grep -q 'Passo intermediário' docs/runtime-native-perf-especie.md
grep -q 'dot_block_q4_k\|fused' docs/runtime-native-perf-especie.md

# Desfecho A: espécie guest intermediária no contrato kernel — ainda não.
# Desfecho B (E59): ADR 0020 inviável pós-otimização.
test -f docs/adr/0020-runtime-native-passo-intermediario-inviavel.md
grep -q 'inviável' docs/adr/0020-runtime-native-passo-intermediario-inviavel.md
grep -q 'IA_LIVRE_NATIVE_PERF_HOST' runtime-native/src/lib.rs
grep -q 'dot_block_q4_k' runtime-native/src/lib.rs

# Teto guest permanece subset (honestidade).
grep -q 'PREFILL_LAYERS_GUEST: usize = 2' runtime-native/src/kv.rs
grep -q 'N_PREDICT_GUEST: usize = 1' runtime-native/src/decode.rs

# Microbench host (requer GGUF).
if [[ ! -f models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf ]]; then
  echo "IA_LIVRE_NATIVE_PERF_SKIP=need_gguf"
  echo "IA_LIVRE_NATIVE_PERF_OK"
  echo "GATE_OK: runtime-native-perf — ADR 0020 + docs (GGUF ausente; skip microbench)"
  exit 0
fi

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT
cargo test -p ia-livre-runtime-native e59_host_perf_step_layers --release -- --nocapture >"$LOG" 2>&1
grep -q 'IA_LIVRE_NATIVE_PERF_HOST_OK=1' "$LOG"
grep -q 'IA_LIVRE_NATIVE_PERF_HOST_MS_2L1=' "$LOG"
grep -q 'IA_LIVRE_NATIVE_PERF_HOST_MS_8L1=' "$LOG"

echo "IA_LIVRE_NATIVE_PERF_OUTCOME=adr_0020_inviable_guest_step"
echo "IA_LIVRE_NATIVE_PERF_OK"
echo "GATE_OK: runtime-native-perf — otimização + ADR 0020 (passo guest inviável; sem COMPROVA)"
