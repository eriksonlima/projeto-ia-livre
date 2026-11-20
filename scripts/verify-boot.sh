#!/usr/bin/env bash
# Gate do kernel (Etapas 4 / 10): serial QEMU deve emitir BOOT_OK + MEM_MAP_OK + ALLOC_OK.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

MARKERS=(
  "IA_LIVRE_BOOT_OK"
  "IA_LIVRE_MEM_MAP_OK"
  "IA_LIVRE_ALLOC_OK"
)
# Evidência numérica (Task 10) — presença da linha, não valor fixo.
NUMERIC=(
  "IA_LIVRE_MEM_CONVENTIONAL_PAGES="
  "IA_LIVRE_ALLOC_BYTES="
)

TIMEOUT_SEC="${VERIFY_TIMEOUT:-45}"
LOG="$(mktemp)"
trap 'rm -f "$LOG"; [[ -n "${QEMU_PID:-}" ]] && kill -KILL "$QEMU_PID" 2>/dev/null || true' EXIT

make esp

make run >"$LOG" 2>&1 &
QEMU_PID=$!

all_present() {
  local m
  for m in "${MARKERS[@]}" "${NUMERIC[@]}"; do
    grep -q "$m" "$LOG" 2>/dev/null || return 1
  done
  return 0
}

deadline=$((SECONDS + TIMEOUT_SEC))
while (( SECONDS < deadline )); do
  if all_present; then
    kill -KILL "$QEMU_PID" 2>/dev/null || true
    wait "$QEMU_PID" 2>/dev/null || true
    QEMU_PID=
    echo "GATE_OK: kernel — IA_LIVRE_BOOT_OK IA_LIVRE_MEM_MAP_OK IA_LIVRE_ALLOC_OK (+ páginas/bytes)"
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

echo "GATE_FAIL: marcadores do kernel incompletos em ${TIMEOUT_SEC}s"
echo "Esperado: ${MARKERS[*]} e ${NUMERIC[*]}"
echo "---- serial (últimas 80 linhas) ----"
tail -n 80 "$LOG" || true
exit 1
