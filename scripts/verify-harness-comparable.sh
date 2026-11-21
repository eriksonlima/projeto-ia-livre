#!/usr/bin/env bash
# Gate Etapa 22: corrida A vs B + veredito honesto.
# Passa com INCONCLUSIVO se B=proxy. Falha se COMPROVA sem comparabilidade ou tokens em proxy.
# Não substitui make verify-harness (v1).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
if [[ -z "${BINDGEN_EXTRA_CLANG_ARGS:-}" ]]; then
  export BINDGEN_EXTRA_CLANG_ARGS="-I/usr/lib/gcc/x86_64-linux-gnu/13/include -I/usr/include"
fi

MODEL="${IA_LIVRE_MODEL:-models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf}"
TIMEOUT_SEC="${VERIFY_HARNESS_COMPARABLE_TIMEOUT:-${VERIFY_HARNESS_TIMEOUT:-600}}"

if [[ ! -f "$MODEL" ]]; then
  echo "GATE_FAIL: modelo ausente: $MODEL"
  echo "Rode: ./scripts/fetch-model.sh"
  exit 1
fi

test -f docs/harness-a-b-comparavel.md
test -f scripts/run-harness-a-b-comparable.sh
test -f scripts/run-harness-line-a.sh
test -f scripts/run-harness-line-b.sh

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

RUNTIME_BIN="${IA_LIVRE_RUNTIME_BIN:-target/debug/ia-livre-runtime}"
if [[ -x "$RUNTIME_BIN" && "${IA_LIVRE_SKIP_RUNTIME_BUILD:-}" == "1" ]]; then
  echo "Skipping cargo build (IA_LIVRE_SKIP_RUNTIME_BUILD=1; bin=$RUNTIME_BIN)"
else
  echo "Building ia-livre-runtime (Linha A)…"
  cargo build -p ia-livre-runtime
fi

echo "Harness comparável (timeout ${TIMEOUT_SEC}s)…"
set +e
timeout "${TIMEOUT_SEC}s" ./scripts/run-harness-a-b-comparable.sh >"$LOG" 2>&1
rc=$?
set -e

if (( rc == 124 )); then
  echo "GATE_FAIL: timeout após ${TIMEOUT_SEC}s"
  tail -n 40 "$LOG" || true
  exit 1
fi

# Script pode exit 1 em falha de corrida A/B ou fraude — isso é GATE_FAIL
if (( rc != 0 )); then
  echo "GATE_FAIL: run-harness-a-b-comparable exit $rc"
  tail -n 80 "$LOG" || true
  exit 1
fi

cat "$LOG"

fail=0
if ! grep -qE 'IA_LIVRE_HARNESS_VERDICT=(COMPROVA|REFUTA|INCONCLUSIVO)' "$LOG"; then
  echo "GATE_FAIL: VERDICT ausente ou inválido"
  fail=1
fi
if ! grep -q 'IA_LIVRE_HARNESS_VERDICT_REASON=' "$LOG"; then
  echo "GATE_FAIL: VERDICT_REASON ausente"
  fail=1
fi

verdict="$(grep -oE 'IA_LIVRE_HARNESS_VERDICT=(COMPROVA|REFUTA|INCONCLUSIVO)' "$LOG" | tail -1 | cut -d= -f2)"

# COMPROVA/REFUTA ilegais se B não tem LOAD_KIND=gguf (só proxy/microbench)
if ! grep -q 'IA_LIVRE_HARNESS_LOAD_KIND=gguf' "$LOG"; then
  if [[ "$verdict" == "COMPROVA" || "$verdict" == "REFUTA" ]]; then
    echo "GATE_FAIL: VERDICT=$verdict ilegal sem LOAD_KIND=gguf em B (exige INCONCLUSIVO)"
    fail=1
  fi
fi
# Subset generate: COMPROVA/REFUTA ilegais (espécie ≠ A)
if grep -q 'E44_subset_generate_not_canonical_species' "$LOG"; then
  if [[ "$verdict" == "COMPROVA" || "$verdict" == "REFUTA" ]]; then
    echo "GATE_FAIL: VERDICT=$verdict ilegal com geração subset (exige INCONCLUSIVO)"
    fail=1
  fi
fi
if grep -qE 'fraude_tokens' "$LOG"; then
  echo "GATE_FAIL: fraude de tokens detectada no runner"
  fail=1
fi

if (( fail )); then
  exit 1
fi

echo "GATE_OK: harness comparável — VERDICT=${verdict} (hipótese só 'comprovada' se VERDICT=COMPROVA com B GGUF canônico)"
exit 0
