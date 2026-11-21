#!/usr/bin/env bash
# Gate Etapa 66: NET_GUEST_BLOCK + bridge; sem NET_NATIVE_OK; ≠ verify-node.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

test -f docs/adr/0024-tcp-rede-guest-inviavel.md
test -f docs/rede-tcp-guest.md
test -f scripts/run-rede-guest.sh
chmod +x scripts/run-rede-guest.sh scripts/run-rede-bridge.sh

out="$(./scripts/run-rede-guest.sh 2>&1)" || {
  echo "GATE_FAIL: run-rede-guest exit ≠ 0"
  echo "$out"
  exit 1
}
echo "$out"

fail=0
grep -q 'IA_LIVRE_NET_GUEST_BLOCK=no_tcp_post_exit' <<<"$out" || fail=1
grep -q 'IA_LIVRE_NET_BRIDGE_OK' <<<"$out" || fail=1
grep -q 'IA_LIVRE_NET_GUEST_OK' <<<"$out" || fail=1

if grep -q 'IA_LIVRE_NET_NATIVE_OK' <<<"$out"; then
  echo "GATE_FAIL: NET_NATIVE_OK sem stack"
  fail=1
fi

if (( fail )); then
  exit 1
fi

echo "GATE_OK: rede-guest — NET_GUEST_BLOCK + bridge (E66/ADR 0024; ≠ TCP fingido; ≠ verify-node SO)"
exit 0
