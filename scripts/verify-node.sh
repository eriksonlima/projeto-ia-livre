#!/usr/bin/env bash
# Gate Etapa 6: dois nós (mesmo host) — PEER_OK + MSG_OK.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$(pwd)/target}"

TIMEOUT_SEC="${VERIFY_NODE_TIMEOUT:-45}"
TCP_A="${VERIFY_NODE_TCP_A:-7400}"
TCP_B="${VERIFY_NODE_TCP_B:-7401}"
UDP_PORT="${VERIFY_NODE_UDP:-7410}"

echo "Building ia-livre-node…"
cargo build -p ia-livre-node

BIN="${CARGO_TARGET_DIR}/debug/ia-livre-node"
if [[ ! -x "$BIN" ]]; then
  echo "GATE_FAIL: binário ausente: $BIN"
  exit 1
fi

A_LOG="$(mktemp)"
B_LOG="$(mktemp)"
A_PID=""
B_PID=""

cleanup() {
  if [[ -n "${A_PID}" ]]; then kill "${A_PID}" 2>/dev/null || true; fi
  if [[ -n "${B_PID}" ]]; then kill "${B_PID}" 2>/dev/null || true; fi
  wait "${A_PID}" "${B_PID}" 2>/dev/null || true
  rm -f "$A_LOG" "$B_LOG"
}
trap cleanup EXIT

echo "Starting node A (tcp=${TCP_A})…"
"$BIN" --tcp-port "$TCP_A" --udp-port "$UDP_PORT" --node-id alice >"$A_LOG" 2>&1 &
A_PID=$!

sleep 0.4

echo "Starting node B (tcp=${TCP_B}, --peer 127.0.0.1:${TCP_A})…"
"$BIN" --tcp-port "$TCP_B" --udp-port "$UDP_PORT" --node-id bob \
  --peer "127.0.0.1:${TCP_A}" >"$B_LOG" 2>&1 &
B_PID=$!

deadline=$((SECONDS + TIMEOUT_SEC))
ok_peer=0
ok_msg=0

while (( SECONDS < deadline )); do
  if ! kill -0 "$A_PID" 2>/dev/null || ! kill -0 "$B_PID" 2>/dev/null; then
    echo "GATE_FAIL: processo do nó terminou cedo"
    echo "---- log A ----"; cat "$A_LOG" || true
    echo "---- log B ----"; cat "$B_LOG" || true
    exit 1
  fi

  if grep -q 'IA_LIVRE_PEER_OK' "$A_LOG" && grep -q 'IA_LIVRE_PEER_OK' "$B_LOG"; then
    ok_peer=1
  fi
  # MSG_OK em pelo menos um processo (preferencialmente ambos — aceita um).
  if grep -q 'IA_LIVRE_MSG_OK' "$A_LOG" || grep -q 'IA_LIVRE_MSG_OK' "$B_LOG"; then
    ok_msg=1
  fi

  if (( ok_peer && ok_msg )); then
    break
  fi
  sleep 0.2
done

COMBINED="$(mktemp)"
trap 'rm -f "$A_LOG" "$B_LOG" "$COMBINED"; if [[ -n "${A_PID}" ]]; then kill "${A_PID}" 2>/dev/null || true; fi; if [[ -n "${B_PID}" ]]; then kill "${B_PID}" 2>/dev/null || true; fi' EXIT
cat "$A_LOG" "$B_LOG" >"$COMBINED"

fail=0
if (( ! ok_peer )); then
  echo "GATE_FAIL: IA_LIVRE_PEER_OK ausente em um ou ambos os nós (timeout ${TIMEOUT_SEC}s)"
  fail=1
fi
if (( ! ok_msg )); then
  echo "GATE_FAIL: IA_LIVRE_MSG_OK ausente (timeout ${TIMEOUT_SEC}s)"
  fail=1
fi

if (( fail )); then
  echo "---- log A ----"; cat "$A_LOG" || true
  echo "---- log B ----"; cat "$B_LOG" || true
  exit 1
fi

echo "GATE_OK: nó Rede IA Livre — PEER_OK + MSG_OK"
grep -E 'IA_LIVRE_(PEER_OK|MSG_OK|PEER_ADDR=|NODE_ID=)' "$COMBINED" | head -n 20 || true
exit 0
