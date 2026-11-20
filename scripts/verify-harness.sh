#!/usr/bin/env bash
# Gate Etapa 9: harness Linha A ok + Linha B skip canônico.
# Não exige QEMU/UEFI nem GPU. Não prova a hipótese A vs B.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
if [[ -z "${BINDGEN_EXTRA_CLANG_ARGS:-}" ]]; then
  export BINDGEN_EXTRA_CLANG_ARGS="-I/usr/lib/gcc/x86_64-linux-gnu/13/include -I/usr/include"
fi

MODEL="${IA_LIVRE_MODEL:-models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf}"
TIMEOUT_SEC="${VERIFY_HARNESS_TIMEOUT:-300}"

if [[ ! -f "$MODEL" ]]; then
  echo "GATE_FAIL: modelo ausente: $MODEL"
  echo "Rode: ./scripts/fetch-model.sh"
  exit 1
fi

echo "Building ia-livre-runtime…"
cargo build -p ia-livre-runtime

LOG_A="$(mktemp)"
LOG_B="$(mktemp)"
trap 'rm -f "$LOG_A" "$LOG_B"' EXIT

echo "Harness Linha A (timeout ${TIMEOUT_SEC}s)…"
set +e
timeout "${TIMEOUT_SEC}s" ./scripts/run-harness-line-a.sh >"$LOG_A" 2>"$LOG_A.err"
rc_a=$?
set -e

if (( rc_a == 124 )); then
  echo "GATE_FAIL: timeout Linha A após ${TIMEOUT_SEC}s"
  tail -n 40 "$LOG_A.err" || true
  exit 1
fi
if (( rc_a != 0 )); then
  echo "GATE_FAIL: Linha A exit $rc_a"
  tail -n 80 "$LOG_A.err" || true
  cat "$LOG_A" || true
  exit 1
fi

COMBINED_A="$(mktemp)"
trap 'rm -f "$LOG_A" "$LOG_A.err" "$LOG_B" "$COMBINED_A"' EXIT
cat "$LOG_A" "$LOG_A.err" >"$COMBINED_A"

fail=0
for marker in \
  'IA_LIVRE_HARNESS_LINE=A' \
  'IA_LIVRE_HARNESS_OK' \
  'IA_LIVRE_HARNESS_LOAD_S=' \
  'IA_LIVRE_HARNESS_TOKENS_PER_S=' \
  'IA_LIVRE_HARNESS_MODEL=' \
  'IA_LIVRE_HARNESS_N_PREDICT='; do
  if ! grep -q "$marker" "$COMBINED_A"; then
    echo "GATE_FAIL: marcador ausente na Linha A: $marker"
    fail=1
  fi
done

if (( fail )); then
  echo "---- saída Linha A (últimas 60 linhas) ----"
  tail -n 60 "$COMBINED_A" || true
  exit 1
fi

echo "Harness Linha B (stub)…"
./scripts/run-harness-line-b.sh >"$LOG_B" 2>&1
if ! grep -q 'IA_LIVRE_HARNESS_B_SKIP' "$LOG_B"; then
  echo "GATE_FAIL: stub B sem IA_LIVRE_HARNESS_B_SKIP"
  cat "$LOG_B" || true
  exit 1
fi
if ! grep -q 'IA_LIVRE_HARNESS_LINE=B' "$LOG_B"; then
  echo "GATE_FAIL: stub B sem IA_LIVRE_HARNESS_LINE=B"
  cat "$LOG_B" || true
  exit 1
fi
# Não aceitar números inventados de B (HARNESS_OK / LOAD / TOKENS na linha B)
if grep -q 'IA_LIVRE_HARNESS_OK' "$LOG_B"; then
  echo "GATE_FAIL: stub B não deve emitir IA_LIVRE_HARNESS_OK"
  exit 1
fi
if grep -qE 'IA_LIVRE_HARNESS_(LOAD_S|TOKENS_PER_S)=' "$LOG_B"; then
  echo "GATE_FAIL: stub B não deve emitir métricas numéricas"
  exit 1
fi

echo "GATE_OK: harness — A ok + B skip — $(grep -E 'IA_LIVRE_HARNESS_(LINE=A|OK|LOAD_S=|TOKENS_PER_S=)' "$COMBINED_A" | tr '\n' ' ')"
exit 0
