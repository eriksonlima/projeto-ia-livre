#!/usr/bin/env bash
# Gate Etapa 49: bridge host↔nativo (metal_block + fixture blockio).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

test -f docs/autonomia-bridge-nativo.md
test -f docs/adr/0018-autonomia-bridge-host-nativo.md
test -f scripts/run-autonomia-bridge.sh
test -f docs/evidence/bridge/serial-blockio-fixture.txt
chmod +x scripts/run-autonomia-bridge.sh

fail=0

# 1) metal_block (corre QEMU ESP-only via verify-metal-infer)
out_m="$(./scripts/run-autonomia-bridge.sh --src metal_block 2>&1)" || {
  echo "GATE_FAIL: bridge metal_block exit ≠ 0"
  echo "$out_m"
  fail=1
}
echo "$out_m"
grep -q 'IA_LIVRE_BRIDGE_MODE=host_native' <<<"$out_m" || fail=1
grep -q 'IA_LIVRE_BRIDGE_NATIVE_SRC=metal_block' <<<"$out_m" || fail=1
grep -q 'IA_LIVRE_BRIDGE_OK' <<<"$out_m" || fail=1

# 2) blockio via fixture (sem QEMU longo)
out_b="$(./scripts/run-autonomia-bridge.sh --src blockio --log docs/evidence/bridge/serial-blockio-fixture.txt 2>&1)" || {
  echo "GATE_FAIL: bridge blockio fixture exit ≠ 0"
  echo "$out_b"
  fail=1
}
echo "$out_b"
grep -q 'IA_LIVRE_BRIDGE_MODE=host_native' <<<"$out_b" || fail=1
grep -q 'IA_LIVRE_BRIDGE_NATIVE_SRC=blockio' <<<"$out_b" || fail=1
grep -q 'IA_LIVRE_BRIDGE_OK' <<<"$out_b" || fail=1

# Fraudes
if grep -qE 'IA_LIVRE_BAREMETAL_METAL_OK' <<<"$out_m$out_b"; then
  echo "GATE_FAIL: bridge não deve emitir METAL_OK"
  fail=1
fi

# Recusa: blockio com log metal
set +e
./scripts/run-autonomia-bridge.sh --src blockio --log <(echo 'IA_LIVRE_B_BLOCK_METAL=no_gguf_metal_io') 2>/dev/null
rc=$?
set -e
[[ "$rc" -ne 0 ]] || { echo "GATE_FAIL: deveria recusar blockio com log metal"; fail=1; }

if (( fail )); then
  exit 1
fi

echo "IA_LIVRE_BRIDGE_OK"
echo "GATE_OK: autonomia-bridge — metal_block + blockio fixture (ADR 0018; ≠ verify-agent SO)"
exit 0
