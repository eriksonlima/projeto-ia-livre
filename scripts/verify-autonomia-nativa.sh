#!/usr/bin/env bash
# Gate Etapa 70: autonomia consome evidência bridge (NATIVE_CONSUME_*).
# Default: blockio fixture (sem QEMU). ADR 0001: ≠ verify-agent SO.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

test -f docs/autonomia-nativa.md
test -f docs/autonomia-bridge-nativo.md
test -f scripts/run-autonomia-nativa.sh
test -f scripts/run-autonomia-bridge.sh
test -f docs/evidence/bridge/serial-blockio-fixture.txt
chmod +x scripts/run-autonomia-nativa.sh scripts/verify-autonomia-nativa.sh

fail=0

out="$(./scripts/run-autonomia-nativa.sh --src blockio \
  --log docs/evidence/bridge/serial-blockio-fixture.txt 2>&1)" || {
  echo "GATE_FAIL: run-autonomia-nativa blockio exit ≠ 0"
  echo "$out"
  fail=1
}
echo "$out"

grep -q 'IA_LIVRE_BRIDGE_OK' <<<"$out" || {
  echo "GATE_FAIL: sem BRIDGE_OK (pré-requisito E49)"
  fail=1
}
grep -q 'IA_LIVRE_NATIVE_CONSUME_MODE=host_bridge' <<<"$out" || fail=1
grep -q 'IA_LIVRE_NATIVE_CONSUME_SRC=blockio' <<<"$out" || fail=1
grep -q 'IA_LIVRE_NATIVE_CONSUME_OK' <<<"$out" || fail=1
grep -q 'IA_LIVRE_TOOL=note' <<<"$out" || {
  echo "GATE_FAIL: sem prova note (eco de bridge?)"
  fail=1
}
grep -q 'IA_LIVRE_TOOL=recall' <<<"$out" || {
  echo "GATE_FAIL: sem prova recall"
  fail=1
}

# Proibidos
if grep -qE 'IA_LIVRE_BAREMETAL_METAL_OK' <<<"$out"; then
  echo "GATE_FAIL: não emitir METAL_OK"
  fail=1
fi
if grep -qE 'IA_LIVRE_HARNESS_VERDICT=COMPROVA' <<<"$out"; then
  echo "GATE_FAIL: não emitir COMPROVA"
  fail=1
fi

# Documentação: consumir ≠ validar
grep -q 'consum' docs/autonomia-nativa.md || {
  echo "GATE_FAIL: contrato sem distinção consumir"
  fail=1
}
grep -q 'NATIVE_CONSUME' docs/autonomia-nativa.md || fail=1

if (( fail )); then
  exit 1
fi

echo "IA_LIVRE_NATIVE_CONSUME_OK"
echo "GATE_OK: autonomia-nativa — consume blockio via bridge+note/recall (ADR 0001; ≠ verify-agent SO)"
exit 0
