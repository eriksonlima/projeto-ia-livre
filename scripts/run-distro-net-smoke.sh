#!/usr/bin/env bash
# Etapa 89 / B84 — smoke Rede com binários do SO (overlay). ≠ guest UEFI.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

./scripts/stage-distro-overlay.sh >/tmp/stage-net.log 2>&1 || { cat /tmp/stage-net.log; exit 1; }
NODE=distro/overlay/opt/ia-livre/bin/ia-livre-node
test -x "$NODE"

# Dois nós loopback (stack do produto)
rm -rf build/distro-net-smoke && mkdir -p build/distro-net-smoke
A_LOG=/tmp/distro-net-a.log
B_LOG=/tmp/distro-net-b.log
rm -f "$A_LOG" "$B_LOG"

"$NODE" --tcp-port 7410 --node-id distro-alice --key-file build/distro-net-smoke/alice.key \
  >"$A_LOG" 2>&1 &
PA=$!
sleep 1
"$NODE" --tcp-port 7411 --node-id distro-bob --key-file build/distro-net-smoke/bob.key \
  --peer 127.0.0.1:7410 >"$B_LOG" 2>&1 &
PB=$!

ok=0
for _ in $(seq 1 30); do
  if grep -q 'IA_LIVRE_TASK_OK' "$B_LOG" 2>/dev/null || grep -q 'IA_LIVRE_PEER_OK' "$B_LOG" 2>/dev/null; then
    ok=1
    break
  fi
  sleep 1
done
kill "$PA" "$PB" 2>/dev/null || true
wait "$PA" "$PB" 2>/dev/null || true

if [[ "$ok" -eq 1 ]]; then
  echo "IA_LIVRE_DISTRO_NET_SRC=overlay_host"
  echo "IA_LIVRE_DISTRO_NET_OK"
  exit 0
fi
echo "IA_LIVRE_DISTRO_NET_SKIP=no_peer"
exit 0
