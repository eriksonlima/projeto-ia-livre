#!/usr/bin/env bash
# Gate Etapa 47: contrato de segurança do writer USB — sem pendrive físico.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

SCRIPT=./scripts/write-usb-esp.sh
test -f "$SCRIPT"
test -x "$SCRIPT" || chmod +x "$SCRIPT"

fail=0

# --help
if ! "$SCRIPT" --help 2>/dev/null | grep -q 'write-usb-esp'; then
  echo "GATE_FAIL: --help não descreve o script"
  fail=1
fi

# --list
if ! "$SCRIPT" --list 2>/dev/null | grep -q 'IA_LIVRE_WRITE_USB_LIST_OK'; then
  echo "GATE_FAIL: --list deve emitir IA_LIVRE_WRITE_USB_LIST_OK"
  fail=1
fi

# Sem confirmação → exit ≠ 0
set +e
"$SCRIPT" --device /dev/null 2>/dev/null
rc_no_confirm=$?
set -e
if [[ "$rc_no_confirm" -eq 0 ]]; then
  echo "GATE_FAIL: sem --confirm deve falhar"
  fail=1
fi

# Confirm divergente → exit ≠ 0
set +e
"$SCRIPT" --dry-run --device /dev/sdX_ci_fake --confirm /dev/sdY_other 2>/dev/null
rc_div=$?
set -e
if [[ "$rc_div" -eq 0 ]]; then
  echo "GATE_FAIL: --confirm divergente deve falhar"
  fail=1
fi

# Dry-run com confirmação idêntica → OK (sem escrita)
out="$("$SCRIPT" --dry-run --device /dev/sdX_ci_fake --confirm /dev/sdX_ci_fake 2>&1)" || {
  echo "GATE_FAIL: dry-run com confirm idêntico deveria exit 0"
  echo "$out"
  fail=1
}
if ! grep -q 'IA_LIVRE_WRITE_USB_OK' <<<"$out"; then
  echo "GATE_FAIL: dry-run deve emitir IA_LIVRE_WRITE_USB_OK"
  echo "$out"
  fail=1
fi
if grep -qE 'IA_LIVRE_BAREMETAL_METAL_OK' <<<"$out"; then
  echo "GATE_FAIL: writer não deve emitir IA_LIVRE_BAREMETAL_METAL_OK"
  fail=1
fi

if (( fail )); then
  exit 1
fi

echo "IA_LIVRE_WRITE_USB_OK"
echo "GATE_OK: write-usb — help/list/dry-run/recusa sem confirmação (≠ USB físico; ≠ METAL_OK)"
exit 0
