#!/usr/bin/env bash
# Gate Etapa 67: descoberta via relay intro (DISC_MODE=relay + DISC_OK + RELAY_OK).
# Não substitui verify-node; sem libp2p; loopback ≠ internet pública.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$(pwd)/target}"

TIMEOUT="${VERIFY_NODE_RELAY_TIMEOUT:-45}"

test -f docs/rede-descoberta-wan.md
cargo build -q -p ia-livre-node
BIN="${CARGO_TARGET_DIR}/debug/ia-livre-node"
mkdir -p build/node-keys

R_LOG="$(mktemp)"; A_LOG="$(mktemp)"; B_LOG="$(mktemp)"
cleanup() {
  [[ -n "${R_PID:-}" ]] && kill "$R_PID" 2>/dev/null || true
  [[ -n "${A_PID:-}" ]] && kill "$A_PID" 2>/dev/null || true
  [[ -n "${B_PID:-}" ]] && kill "$B_PID" 2>/dev/null || true
  wait "${R_PID:-}" "${A_PID:-}" "${B_PID:-}" 2>/dev/null || true
  rm -f "$R_LOG" "$A_LOG" "$B_LOG"
}
trap cleanup EXIT

"$BIN" --relay-listen --tcp-port 7399 >"$R_LOG" 2>&1 &
R_PID=$!
sleep 0.3
"$BIN" --tcp-port 7400 --node-id relay-alice \
  --key-file build/node-keys/relay-alice.key \
  --relay-reg 127.0.0.1:7399 >"$A_LOG" 2>&1 &
A_PID=$!
sleep 0.5
"$BIN" --tcp-port 7401 --node-id relay-bob \
  --key-file build/node-keys/relay-bob.key \
  --relay 127.0.0.1:7399 >"$B_LOG" 2>&1 &
B_PID=$!

deadline=$((SECONDS + TIMEOUT))
ok=0
while (( SECONDS < deadline )); do
  if grep -q 'IA_LIVRE_DISC_MODE=relay' "$B_LOG" \
    && grep -q 'IA_LIVRE_DISC_OK' "$B_LOG" \
    && grep -q 'IA_LIVRE_RELAY_OK' "$B_LOG" \
    && grep -q 'IA_LIVRE_PEER_OK' "$B_LOG"; then
    ok=1
    break
  fi
  sleep 0.2
done

if (( !ok )); then
  echo "GATE_FAIL: relay sem DISC_MODE=relay + DISC_OK + RELAY_OK + PEER_OK"
  echo '---- R ----'; cat "$R_LOG" || true
  echo '---- A ----'; cat "$A_LOG" || true
  echo '---- B ----'; cat "$B_LOG" || true
  exit 1
fi

# Anti-fraude
if grep -qi libp2p node/Cargo.toml; then
  echo "GATE_FAIL: libp2p em node/Cargo.toml"
  exit 1
fi

echo "IA_LIVRE_DISC_MODE=relay"
echo "IA_LIVRE_DISC_OK"
echo "IA_LIVRE_RELAY_OK"
echo "GATE_OK: node-relay — intro RELAY_HINT → sessão v1 (E67; ≠ WAN pública)"
exit 0
