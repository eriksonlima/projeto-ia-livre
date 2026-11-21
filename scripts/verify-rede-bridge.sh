#!/usr/bin/env bash
# Gate Etapa 52: bridge Rede UEFI↔host (NET_BRIDGE_OK). verify-node permanece independente.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

test -f docs/rede-bridge-nativo.md
test -f docs/adr/0019-rede-bridge-uefi-host.md
test -f scripts/run-rede-bridge.sh
test -f docs/evidence/bridge/serial-exit-boot-fixture.txt
chmod +x scripts/run-rede-bridge.sh

out="$(./scripts/run-rede-bridge.sh --log docs/evidence/bridge/serial-exit-boot-fixture.txt 2>&1)" || {
  echo "GATE_FAIL: run-rede-bridge exit ≠ 0"
  echo "$out"
  exit 1
}
echo "$out"

fail=0
grep -q 'IA_LIVRE_NET_BRIDGE_MODE=host_uefi' <<<"$out" || fail=1
grep -q 'IA_LIVRE_NET_BRIDGE_NATIVE_SRC=serial_exit' <<<"$out" || fail=1
grep -q 'IA_LIVRE_NET_BRIDGE_OK' <<<"$out" || fail=1

# Recusa: log sem ExitBoot
set +e
./scripts/run-rede-bridge.sh --log <(echo 'IA_LIVRE_BOOT_OK') >/dev/null 2>&1
rc=$?
set -e
[[ "$rc" -ne 0 ]] || { echo "GATE_FAIL: deveria recusar log sem EXIT_BOOT_OK"; fail=1; }

# Fraude: não emitir NET_NATIVE_OK
if grep -q 'IA_LIVRE_NET_NATIVE_OK' <<<"$out"; then
  echo "GATE_FAIL: não emitir NET_NATIVE_OK"
  fail=1
fi

if (( fail )); then
  exit 1
fi

echo "IA_LIVRE_NET_BRIDGE_OK"
echo "GATE_OK: rede-bridge — serial_exit + TASK_OK (ADR 0019; ≠ verify-node SO)"
exit 0
