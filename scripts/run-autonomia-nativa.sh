#!/usr/bin/env bash
# Etapa 70: autonomia host consome evidência bridge E49 (≠ só validar).
# Mecanismo: bridge → note(native_src=…) → recall → NATIVE_CONSUME_*.
# Sem shell irrestrito; sem METAL_OK / TOKENS inventados; sem agente no guest.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

SRC=""
LOG=""
MEMORY=""
AGENT_BIN="${IA_LIVRE_AGENT_BIN:-}"

usage() {
  cat <<'EOF'
Uso: ./scripts/run-autonomia-nativa.sh --src blockio|metal_block [--log FILE] [--memory FILE]

  Exige BRIDGE_OK via ./scripts/run-autonomia-bridge.sh, injeta SRC na memória
  do agente (REPL note+recall) e emite IA_LIVRE_NATIVE_CONSUME_*.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --src) SRC="${2:-}"; shift 2 ;;
    --log) LOG="${2:-}"; shift 2 ;;
    --memory) MEMORY="${2:-}"; shift 2 ;;
    *) echo "erro: opção $1" >&2; exit 1 ;;
  esac
done

[[ -n "$SRC" ]] || { usage; exit 1; }
case "$SRC" in
  blockio|metal_block) ;;
  *) echo "erro: --src deve ser blockio|metal_block" >&2; exit 1 ;;
esac

if [[ -z "$MEMORY" ]]; then
  MEMORY="build/agent-memory/native-consume-${SRC}.jsonl"
fi
mkdir -p "$(dirname "$MEMORY")"
: >"$MEMORY"

# 1) Bridge (validação E49) — obrigatória
bridge_args=(--src "$SRC")
if [[ -n "$LOG" ]]; then
  bridge_args+=(--log "$LOG")
elif [[ "$SRC" == "blockio" ]]; then
  bridge_args+=(--log docs/evidence/bridge/serial-blockio-fixture.txt)
fi

bridge_out="$(./scripts/run-autonomia-bridge.sh "${bridge_args[@]}" 2>&1)" || {
  echo "erro: bridge falhou" >&2
  echo "$bridge_out" >&2
  exit 1
}
echo "$bridge_out"
grep -q 'IA_LIVRE_BRIDGE_OK' <<<"$bridge_out" \
  || { echo "erro: bridge sem BRIDGE_OK" >&2; exit 1; }
grep -q "IA_LIVRE_BRIDGE_NATIVE_SRC=${SRC}" <<<"$bridge_out" \
  || { echo "erro: bridge SRC ≠ ${SRC}" >&2; exit 1; }

# 2) Consumo: REPL note + recall (sem inferência / sem GGUF)
NOTE_TEXT="native_src=${SRC} bridge_ok=1 e70_consume"
SCRIPT="$(mktemp)"
trap 'rm -f "$SCRIPT"' EXIT
cat >"$SCRIPT" <<EOF
note ${NOTE_TEXT}
recall 8
quit
EOF

if [[ -z "$AGENT_BIN" ]]; then
  cargo build -q -p ia-livre-agent
  AGENT_BIN="target/debug/ia-livre-agent"
fi
[[ -x "$AGENT_BIN" || -f "$AGENT_BIN" ]] || {
  echo "erro: agent bin ausente: $AGENT_BIN" >&2
  exit 1
}

agent_out="$("$AGENT_BIN" --memory "$MEMORY" --repl-script "$SCRIPT" 2>&1)" || {
  echo "erro: agent REPL falhou" >&2
  echo "$agent_out" >&2
  exit 1
}
echo "$agent_out"

# Prova de uso (≠ eco de BRIDGE_OK)
grep -q 'IA_LIVRE_TOOL=note' <<<"$agent_out" \
  || { echo "erro: consumo sem TOOL=note" >&2; exit 1; }
grep -q 'IA_LIVRE_TOOL=recall' <<<"$agent_out" \
  || { echo "erro: consumo sem TOOL=recall" >&2; exit 1; }
grep -q 'IA_LIVRE_REPL_OK' <<<"$agent_out" \
  || { echo "erro: consumo sem REPL_OK" >&2; exit 1; }
grep -q "native_src=${SRC}" "$MEMORY" \
  || { echo "erro: memória sem native_src=${SRC} (consumo não gravou)" >&2; exit 1; }

# Recusa fraude: não emitir métricas inventadas
if grep -qE 'IA_LIVRE_(BAREMETAL_METAL_OK|TOKENS_PER_S|HARNESS_VERDICT=COMPROVA)' <<<"$bridge_out$agent_out"; then
  echo "erro: marcadores proibidos no consumo" >&2
  exit 1
fi

echo "IA_LIVRE_NATIVE_CONSUME_MODE=host_bridge"
echo "IA_LIVRE_NATIVE_CONSUME_SRC=${SRC}"
echo "IA_LIVRE_NATIVE_CONSUME_OK"
exit 0
