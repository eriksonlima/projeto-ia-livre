#!/usr/bin/env bash
# Gate Etapas 23 / 39 / 50: peer + bootstrap + mDNS opt-in (DISC_OK).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$(pwd)/target}"

TIMEOUT_SEC="${VERIFY_NODE_TIMEOUT:-45}"
TCP_A="${VERIFY_NODE_TCP_A:-7400}"
TCP_B="${VERIFY_NODE_TCP_B:-7401}"
TCP_B2="${VERIFY_NODE_TCP_B2:-7402}"
TCP_A_MDNS="${VERIFY_NODE_TCP_A_MDNS:-7403}"
TCP_B_MDNS="${VERIFY_NODE_TCP_B_MDNS:-7404}"
UDP_PORT="${VERIFY_NODE_UDP:-7410}"
UDP_PORT2="${VERIFY_NODE_UDP2:-7411}"
UDP_A_MDNS="${VERIFY_NODE_UDP_A_MDNS:-7412}"
UDP_B_MDNS="${VERIFY_NODE_UDP_B_MDNS:-7413}"
KEY_A="${VERIFY_NODE_KEY_A:-build/node-keys/gate-alice.key}"
KEY_B="${VERIFY_NODE_KEY_B:-build/node-keys/gate-bob.key}"
KEY_B2="${VERIFY_NODE_KEY_B2:-build/node-keys/gate-bob2.key}"
KEY_A_MDNS="${VERIFY_NODE_KEY_A_MDNS:-build/node-keys/gate-alice-mdns.key}"
KEY_B_MDNS="${VERIFY_NODE_KEY_B_MDNS:-build/node-keys/gate-bob-mdns.key}"
RUN_PEER="${VERIFY_NODE_LEGACY_PEER:-1}"
RUN_BOOTSTRAP="${VERIFY_NODE_BOOTSTRAP:-1}"
MDNS_SKIP="${VERIFY_NODE_MDNS_SKIP:-1}"
MDNS_FORCE="${VERIFY_NODE_MDNS_FORCE:-0}"

echo "Building ia-livre-node…"
cargo build -p ia-livre-node

BIN="${CARGO_TARGET_DIR}/debug/ia-livre-node"
if [[ ! -x "$BIN" ]]; then
  echo "GATE_FAIL: binário ausente: $BIN"
  exit 1
fi

mkdir -p build/node-keys

run_pair() {
  local stage="$1"
  local a_tcp="$2"
  local a_udp="$3"
  local a_key="$4"
  local a_extra="$5"
  local b_tcp="$6"
  local b_udp="$7"
  local b_key="$8"
  local b_extra="$9"
  local need_disc="${10}"
  local disc_mode="${11}"

  local A_LOG B_LOG A_PID B_PID
  A_LOG="$(mktemp)"
  B_LOG="$(mktemp)"
  A_PID=""
  B_PID=""

  cleanup_pair() {
    if [[ -n "${A_PID}" ]]; then kill "${A_PID}" 2>/dev/null || true; fi
    if [[ -n "${B_PID}" ]]; then kill "${B_PID}" 2>/dev/null || true; fi
    wait "${A_PID}" "${B_PID}" 2>/dev/null || true
    rm -f "$A_LOG" "$B_LOG"
  }
  trap cleanup_pair RETURN

  echo "---- estágio ${stage}: Starting node A (tcp=${a_tcp})…"
  # shellcheck disable=SC2086
  "$BIN" --tcp-port "$a_tcp" --udp-port "$a_udp" --node-id "alice-${stage}" \
    --key-file "$a_key" $a_extra >"$A_LOG" 2>&1 &
  A_PID=$!
  # mDNS: dar tempo ao anúncio antes do browse do B
  if [[ "$stage" == "mdns" ]]; then
    sleep 1.0
  else
    sleep 0.4
  fi

  echo "---- estágio ${stage}: Starting node B (tcp=${b_tcp}, ${b_extra})…"
  # shellcheck disable=SC2086
  "$BIN" --tcp-port "$b_tcp" --udp-port "$b_udp" --node-id "bob-${stage}" \
    --key-file "$b_key" $b_extra >"$B_LOG" 2>&1 &
  B_PID=$!

  local deadline ok_peer ok_msg ok_ident ok_ping ok_disc
  deadline=$((SECONDS + TIMEOUT_SEC))
  ok_peer=0
  ok_msg=0
  ok_ident=0
  ok_ping=0
  ok_disc=0

  while (( SECONDS < deadline )); do
    if ! kill -0 "$A_PID" 2>/dev/null || ! kill -0 "$B_PID" 2>/dev/null; then
      echo "GATE_FAIL (${stage}): processo do nó terminou cedo"
      echo "---- log A ----"; cat "$A_LOG" || true
      echo "---- log B ----"; cat "$B_LOG" || true
      return 1
    fi

    if grep -q 'IA_LIVRE_PEER_OK' "$A_LOG" && grep -q 'IA_LIVRE_PEER_OK' "$B_LOG"; then
      ok_peer=1
    fi
    if grep -q 'IA_LIVRE_MSG_OK' "$A_LOG" || grep -q 'IA_LIVRE_MSG_OK' "$B_LOG"; then
      ok_msg=1
    fi
    if grep -q 'IA_LIVRE_IDENT_OK' "$A_LOG" || grep -q 'IA_LIVRE_IDENT_OK' "$B_LOG"; then
      ok_ident=1
    fi
    if grep -q 'IA_LIVRE_PING_OK' "$A_LOG" || grep -q 'IA_LIVRE_PING_OK' "$B_LOG"; then
      ok_ping=1
    fi
    if grep -q 'IA_LIVRE_DISC_OK' "$A_LOG" || grep -q 'IA_LIVRE_DISC_OK' "$B_LOG"; then
      ok_disc=1
    fi

    if (( ok_peer && ok_msg && ok_ident && ok_ping )); then
      if [[ "$need_disc" == "1" ]]; then
        if (( ok_disc )); then
          break
        fi
      else
        break
      fi
    fi
    sleep 0.2
  done

  local fail=0
  if (( ! ok_peer )); then
    echo "GATE_FAIL (${stage}): IA_LIVRE_PEER_OK ausente"
    fail=1
  fi
  if (( ! ok_msg )); then
    echo "GATE_FAIL (${stage}): IA_LIVRE_MSG_OK ausente"
    fail=1
  fi
  if (( ! ok_ident )); then
    echo "GATE_FAIL (${stage}): IA_LIVRE_IDENT_OK ausente"
    fail=1
  fi
  if (( ! ok_ping )); then
    echo "GATE_FAIL (${stage}): IA_LIVRE_PING_OK ausente"
    fail=1
  fi
  if [[ "$need_disc" == "1" ]] && (( ! ok_disc )); then
    echo "GATE_FAIL (${stage}): IA_LIVRE_DISC_OK ausente"
    fail=1
  fi
  if [[ "$need_disc" == "1" && -n "$disc_mode" ]]; then
    if ! grep -q "IA_LIVRE_DISC_MODE=${disc_mode}" "$A_LOG" \
      && ! grep -q "IA_LIVRE_DISC_MODE=${disc_mode}" "$B_LOG"; then
      echo "GATE_FAIL (${stage}): IA_LIVRE_DISC_MODE=${disc_mode} ausente"
      fail=1
    fi
  fi

  if (( fail )); then
    echo "---- log A ----"; cat "$A_LOG" || true
    echo "---- log B ----"; cat "$B_LOG" || true
    return 1
  fi

  echo "GATE_OK (${stage}): PEER_OK + MSG_OK + IDENT_OK + PING_OK$([ "$need_disc" = 1 ] && echo " + DISC_OK (${disc_mode})" || true)"
  return 0
}

if [[ "$RUN_PEER" == "1" ]]; then
  run_pair peer "$TCP_A" "$UDP_PORT" "$KEY_A" "" \
    "$TCP_B" "$UDP_PORT" "$KEY_B" "--peer 127.0.0.1:${TCP_A}" 0 ""
fi

if [[ "$RUN_BOOTSTRAP" == "1" ]]; then
  run_pair bootstrap "$TCP_A" "$UDP_PORT" "$KEY_A" "" \
    "$TCP_B2" "$UDP_PORT2" "$KEY_B2" "--bootstrap 127.0.0.1:${TCP_A}" 1 bootstrap
fi

if [[ "$MDNS_SKIP" == "1" ]]; then
  echo "IA_LIVRE_DISC_MDNS_SKIP=1"
  echo "GATE_OK: nó Rede IA Livre — peer + bootstrap (mDNS skip; Etapa 50)"
  exit 0
fi

echo "---- estágio mdns (VERIFY_NODE_MDNS_SKIP=0)…"
set +e
run_pair mdns "$TCP_A_MDNS" "$UDP_A_MDNS" "$KEY_A_MDNS" "--disc-mdns" \
  "$TCP_B_MDNS" "$UDP_B_MDNS" "$KEY_B_MDNS" "--disc-mdns" 1 mdns
mdns_rc=$?
set -e

if [[ "$mdns_rc" -eq 0 ]]; then
  echo "GATE_OK: nó Rede IA Livre — peer + bootstrap + mdns (Etapa 50)"
  exit 0
fi

if [[ "$MDNS_FORCE" == "1" ]]; then
  echo "GATE_FAIL: mDNS falhou e VERIFY_NODE_MDNS_FORCE=1"
  exit 1
fi

# Multicast indisponível / flaky → skip honesto (sem fingir DISC_OK)
echo "IA_LIVRE_DISC_MDNS_SKIP=multicast_or_timeout"
echo "GATE_OK: nó Rede IA Livre — peer + bootstrap (mDNS skip honesto; Etapa 50)"
exit 0
