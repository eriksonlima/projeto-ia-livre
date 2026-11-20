#!/usr/bin/env bash
# Gate Etapa 4: boot UEFI em QEMU deve emitir IA_LIVRE_BOOT_OK na serial.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

MARKER="IA_LIVRE_BOOT_OK"
TIMEOUT_SEC="${VERIFY_TIMEOUT:-45}"
LOG="$(mktemp)"
trap 'rm -f "$LOG"; [[ -n "${QEMU_PID:-}" ]] && kill -KILL "$QEMU_PID" 2>/dev/null || true' EXIT

make esp

# Roda QEMU em background e encerra assim que a marcação aparecer
make run >"$LOG" 2>&1 &
QEMU_PID=$!

deadline=$((SECONDS + TIMEOUT_SEC))
while (( SECONDS < deadline )); do
  if grep -q "$MARKER" "$LOG" 2>/dev/null; then
    kill -KILL "$QEMU_PID" 2>/dev/null || true
    wait "$QEMU_PID" 2>/dev/null || true
    QEMU_PID=
    echo "GATE_OK: encontrada $MARKER na serial"
    exit 0
  fi
  if ! kill -0 "$QEMU_PID" 2>/dev/null; then
    wait "$QEMU_PID" 2>/dev/null || true
    QEMU_PID=
    break
  fi
  sleep 0.5
done

kill -KILL "$QEMU_PID" 2>/dev/null || true
wait "$QEMU_PID" 2>/dev/null || true
QEMU_PID=

echo "GATE_FAIL: $MARKER não apareceu em ${TIMEOUT_SEC}s"
echo "---- serial (últimas 80 linhas) ----"
tail -n 80 "$LOG" || true
exit 1
