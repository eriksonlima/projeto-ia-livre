#!/usr/bin/env bash
# Gate Etapa 48: path metal/SFS (ESP-only) → B_BLOCK_METAL honesto ou geração.
# Sem USB físico; ≠ METAL_OK; ≠ tratar BlockIO como metal (ADR 0017).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export IA_LIVRE_KERNEL_PROFILE="${IA_LIVRE_KERNEL_PROFILE:-release}"

TIMEOUT_SEC="${VERIFY_METAL_INFER_TIMEOUT:-120}"
LOG="$(mktemp)"
trap 'rm -f "$LOG"; [[ -n "${QEMU_PID:-}" ]] && kill -KILL "$QEMU_PID" 2>/dev/null || true' EXIT

test -f docs/adr/0017-path-metal-sfs-vs-blockio.md
test -f scripts/run-qemu-esp-only.sh
chmod +x scripts/run-qemu-esp-only.sh

./scripts/run-qemu-esp-only.sh >"$LOG" 2>&1 &
QEMU_PID=$!

deadline=$((SECONDS + TIMEOUT_SEC))
have() {
  grep -q 'IA_LIVRE_BOOT_OK' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_EXIT_BOOT_OK' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_GGUF_PATH=esp_sfs' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_B_BLOCK_METAL=no_gguf_metal_io' "$LOG" 2>/dev/null
}

while (( SECONDS < deadline )); do
  if have; then
    break
  fi
  if ! kill -0 "$QEMU_PID" 2>/dev/null; then
    break
  fi
  sleep 0.5
done

kill -KILL "$QEMU_PID" 2>/dev/null || true
wait "$QEMU_PID" 2>/dev/null || true
QEMU_PID=

fail=0
for m in IA_LIVRE_BOOT_OK IA_LIVRE_EXIT_BOOT_OK IA_LIVRE_GGUF_PATH=esp_sfs IA_LIVRE_B_BLOCK_METAL=no_gguf_metal_io; do
  if ! grep -q "$m" "$LOG"; then
    echo "GATE_FAIL: marcador ausente: $m"
    fail=1
  fi
done

# Fraudes
if grep -q 'IA_LIVRE_BAREMETAL_METAL_OK' "$LOG"; then
  echo "GATE_FAIL: não emitir METAL_OK neste gate"
  fail=1
fi
if grep -q 'IA_LIVRE_GGUF_PATH=blockio' "$LOG"; then
  echo "GATE_FAIL: ESP-only não deve usar path blockio"
  fail=1
fi
# TOKENS no path metal bloqueado = fraude
if grep -qE 'IA_LIVRE_RUNTIME_NATIVE_TOKENS_PER_S_MILLI=' "$LOG"; then
  echo "GATE_FAIL: TOKENS no path esp_sfs bloqueado (fraude)"
  fail=1
fi

if (( fail )); then
  echo "---- serial (últimas 40) ----"
  tail -n 40 "$LOG" || true
  exit 1
fi

echo "IA_LIVRE_B_BLOCK_METAL=no_gguf_metal_io"
echo "IA_LIVRE_METAL_INFER_OK"
echo "GATE_OK: metal-infer — ESP-only SFS → B_BLOCK_METAL=no_gguf_metal_io (ADR 0017; ≠ BlockIO; ≠ METAL_OK)"
exit 0
