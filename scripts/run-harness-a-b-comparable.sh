#!/usr/bin/env bash
# Corrida A vs B + veredito honesto (Etapa 22).
# Com B proxy → INCONCLUSIVO obrigatório. Não inventa TOKENS_PER_S / equivalência PROXY↔tokens.
# Metodologia: docs/harness-a-b-comparavel.md
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
if [[ -z "${BINDGEN_EXTRA_CLANG_ARGS:-}" ]]; then
  export BINDGEN_EXTRA_CLANG_ARGS="-I/usr/lib/gcc/x86_64-linux-gnu/13/include -I/usr/include"
fi

TIMEOUT_SEC="${VERIFY_HARNESS_COMPARABLE_TIMEOUT:-${VERIFY_HARNESS_TIMEOUT:-300}}"
MARGIN="${IA_LIVRE_HARNESS_COMPARABLE_MARGIN:-0.05}"
LOG_A="$(mktemp)"
LOG_B="$(mktemp)"
trap 'rm -f "$LOG_A" "$LOG_A.err" "$LOG_B" "$LOG_B.err"' EXIT

# Preflight quieto (Etapa 28) — docs/harness-corrida-quieta.md
# Detecta só QEMU real + scripts/make verify em execução (evita falso positivo de shells sandbox).
# Default: aviso. Strict (exit 1): IA_LIVRE_HARNESS_QUIET_STRICT=1. Override: IA_LIVRE_HARNESS_QUIET_FORCE=1.
quiet_hits=""
while read -r line; do
  [[ -z "$line" ]] && continue
  quiet_hits+="${line}"$'\n'
done < <(pgrep -af '^qemu-system-x86_64 |/qemu-system-x86_64 ' 2>/dev/null || true)
while read -r line; do
  [[ -z "$line" ]] && continue
  # cmdline real: make/bash ./scripts/… — não wrappers cursorsandbox com histórico no argv
  if [[ "$line" == *cursorsandbox* ]]; then
    continue
  fi
  if [[ "$line" =~ (scripts/(verify-|run-harness-)|make[[:space:]]+verify) ]]; then
    quiet_hits+="${line}"$'\n'
  fi
done < <(pgrep -af 'qemu-system-x86_64|scripts/verify-|scripts/run-harness-|make verify' 2>/dev/null \
  | grep -vE "($$|$PPID|run-harness-a-b-comparable|verify-harness-comparable)" || true)

if [[ -n "$quiet_hits" ]]; then
  echo "IA_LIVRE_HARNESS_QUIET_WARN=concorrencia_detectada" >&2
  printf '%s' "$quiet_hits" >&2
  if [[ "${IA_LIVRE_HARNESS_QUIET_STRICT:-0}" == "1" && "${IA_LIVRE_HARNESS_QUIET_FORCE:-0}" != "1" ]]; then
    echo "IA_LIVRE_HARNESS_QUIET_HINT=aguarde, mate QEMU órfão, ou IA_LIVRE_HARNESS_QUIET_FORCE=1" >&2
    echo "IA_LIVRE_HARNESS_VERDICT=INCONCLUSIVO"
    echo "IA_LIVRE_HARNESS_VERDICT_REASON=host_nao_quieto_concorrencia"
    exit 1
  fi
  if [[ "${IA_LIVRE_HARNESS_QUIET_FORCE:-0}" == "1" ]]; then
    echo "IA_LIVRE_HARNESS_QUIET_FORCE=1" >&2
  fi
fi
echo "IA_LIVRE_HARNESS_QUIET_LOADAVG=$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null || echo n/a)"

echo "=== Harness comparável — Linha A (timeout ${TIMEOUT_SEC}s) ==="
set +e
A_SCRIPT=./scripts/run-harness-line-a.sh
if [[ "${IA_LIVRE_HARNESS_A_PROFILE:-}" == "A_otimizada" ]]; then
  A_SCRIPT=./scripts/run-harness-line-a-optimized.sh
  echo "IA_LIVRE_HARNESS_A_PROFILE=A_otimizada"
fi
timeout "${TIMEOUT_SEC}s" "$A_SCRIPT" >"$LOG_A" 2>"$LOG_A.err"
rc_a=$?
set -e
cat "$LOG_A.err" >>"$LOG_A" 2>/dev/null || true
cat "$LOG_A"

if (( rc_a == 124 )); then
  echo "IA_LIVRE_HARNESS_VERDICT=INCONCLUSIVO"
  echo "IA_LIVRE_HARNESS_VERDICT_REASON=timeout_linha_A"
  exit 1
fi
if (( rc_a != 0 )); then
  echo "IA_LIVRE_HARNESS_VERDICT=INCONCLUSIVO"
  echo "IA_LIVRE_HARNESS_VERDICT_REASON=falha_linha_A_exit_${rc_a}"
  exit 1
fi
if ! grep -q 'IA_LIVRE_HARNESS_LINE=A' "$LOG_A" || ! grep -q 'IA_LIVRE_HARNESS_OK' "$LOG_A"; then
  echo "IA_LIVRE_HARNESS_VERDICT=INCONCLUSIVO"
  echo "IA_LIVRE_HARNESS_VERDICT_REASON=marcadores_A_ausentes"
  exit 1
fi

echo "=== Harness comparável — Linha B (timeout ${TIMEOUT_SEC}s) ==="
# Entrypoint B: default proxy (Etapa 12); override quando B15 entregar GGUF
B_SCRIPT="${IA_LIVRE_HARNESS_B_SCRIPT:-./scripts/run-harness-line-b.sh}"
set +e
timeout "${TIMEOUT_SEC}s" "$B_SCRIPT" >"$LOG_B" 2>"$LOG_B.err"
rc_b=$?
set -e
cat "$LOG_B.err" >>"$LOG_B" 2>/dev/null || true
cat "$LOG_B"

if (( rc_b == 124 )); then
  echo "IA_LIVRE_HARNESS_VERDICT=INCONCLUSIVO"
  echo "IA_LIVRE_HARNESS_VERDICT_REASON=timeout_linha_B"
  exit 1
fi
if (( rc_b != 0 )); then
  echo "IA_LIVRE_HARNESS_VERDICT=INCONCLUSIVO"
  echo "IA_LIVRE_HARNESS_VERDICT_REASON=falha_linha_B_exit_${rc_b}"
  exit 1
fi
if ! grep -q 'IA_LIVRE_HARNESS_LINE=B' "$LOG_B" || ! grep -q 'IA_LIVRE_HARNESS_OK' "$LOG_B"; then
  echo "IA_LIVRE_HARNESS_VERDICT=INCONCLUSIVO"
  echo "IA_LIVRE_HARNESS_VERDICT_REASON=marcadores_B_ausentes"
  exit 1
fi

# Fraude: B proxy não pode emitir TOKENS_PER_S
b_is_proxy=0
if grep -q 'IA_LIVRE_HARNESS_PROXY=' "$LOG_B" \
  || grep -q 'IA_LIVRE_HARNESS_LOAD_KIND=proxy' "$LOG_B"; then
  b_is_proxy=1
fi

if (( b_is_proxy )) && grep -qE 'IA_LIVRE_HARNESS_TOKENS_PER_S=' "$LOG_B"; then
  echo "IA_LIVRE_HARNESS_VERDICT=INCONCLUSIVO"
  echo "IA_LIVRE_HARNESS_VERDICT_REASON=fraude_tokens_em_B_proxy"
  exit 1
fi

if (( b_is_proxy )); then
  # B ainda proxy: loader ESP (E26) ≠ geração — sem TOKENS_PER_S em B → INCONCLUSIVO
  echo "IA_LIVRE_HARNESS_VERDICT=INCONCLUSIVO"
  # Motivo ≠ "ausência de tokens" genérico: bloqueio estrutural 22L/KV (E33 Task 2+).
  echo "IA_LIVRE_HARNESS_VERDICT_REASON=E43_no_gguf_prefill_22l_subset_kv_ok"
  exit 0
fi

# Candidato comparável: B com load+tokens GGUF, sem PROXY
if ! grep -qE 'IA_LIVRE_HARNESS_TOKENS_PER_S=[0-9]' "$LOG_B" \
  || ! grep -qE 'IA_LIVRE_HARNESS_LOAD_S=[0-9]' "$LOG_B"; then
  echo "IA_LIVRE_HARNESS_VERDICT=INCONCLUSIVO"
  echo "IA_LIVRE_HARNESS_VERDICT_REASON=B_sem_metricas_GGUF_comparaveis"
  exit 0
fi

tokens_a="$(grep -oE 'IA_LIVRE_HARNESS_TOKENS_PER_S=[0-9.]+' "$LOG_A" | head -1 | cut -d= -f2)"
tokens_b="$(grep -oE 'IA_LIVRE_HARNESS_TOKENS_PER_S=[0-9.]+' "$LOG_B" | head -1 | cut -d= -f2)"

if [[ -z "$tokens_a" || -z "$tokens_b" ]]; then
  echo "IA_LIVRE_HARNESS_VERDICT=INCONCLUSIVO"
  echo "IA_LIVRE_HARNESS_VERDICT_REASON=parse_tokens_falhou"
  exit 0
fi

# Critério: R = B/A; margem default 5% (docs/harness-a-b-comparavel.md)
verdict="$(MARGIN="$MARGIN" TOKENS_A="$tokens_a" TOKENS_B="$tokens_b" python3 - <<'PY'
import os
a = float(os.environ["TOKENS_A"])
b = float(os.environ["TOKENS_B"])
m = float(os.environ["MARGIN"])
if a <= 0:
    print("INCONCLUSIVO")
    raise SystemExit
r = b / a
if r >= 1.0 + m:
    print("COMPROVA")
elif r <= 1.0 - m:
    print("REFUTA")
else:
    print("INCONCLUSIVO")
PY
)"

reason="R=B/A_tokens margin=${MARGIN} A=${tokens_a} B=${tokens_b}"
if [[ "$verdict" == "INCONCLUSIVO" ]]; then
  reason="dentro_da_margem_ou_empate ${reason}"
elif [[ "$verdict" == "COMPROVA" ]]; then
  reason="B_acima_de_A ${reason}"
else
  reason="B_abaixo_de_A ${reason}"
fi

echo "IA_LIVRE_HARNESS_VERDICT=${verdict}"
echo "IA_LIVRE_HARNESS_VERDICT_REASON=${reason}"
exit 0
