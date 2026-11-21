#!/usr/bin/env bash
# Gate Etapa 48/63: path metal/SFS.
# Preferência E63: FAT32 + GGUF full → esp_sfs_full (desfecho A).
# Fallback: ESP-only fat:rw → B_BLOCK_METAL=no_gguf_metal_io (desfecho E48 / legacy).
# ≠ METAL_OK; ≠ tratar BlockIO como metal (ADR 0017 / docs/gguf-path-metal-io.md).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export IA_LIVRE_KERNEL_PROFILE="${IA_LIVRE_KERNEL_PROFILE:-release}"

TIMEOUT_SEC="${VERIFY_METAL_INFER_TIMEOUT:-300}"
MODEL="${IA_LIVRE_MODEL:-models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf}"
MODE="${IA_LIVRE_METAL_INFER_MODE:-auto}" # auto | full | legacy

test -f docs/adr/0017-path-metal-sfs-vs-blockio.md
test -f docs/gguf-path-metal-io.md

can_full() {
  [[ -f "$MODEL" ]] \
    && command -v mcopy >/dev/null \
    && command -v mmd >/dev/null \
    && command -v mkfs.vfat >/dev/null
}

choose_mode() {
  case "$MODE" in
    full|legacy) echo "$MODE" ;;
    auto)
      if can_full; then echo full; else echo legacy; fi
      ;;
    *)
      echo "erro: IA_LIVRE_METAL_INFER_MODE inválido: $MODE" >&2
      exit 1
      ;;
  esac
}

RUN_MODE="$(choose_mode)"
echo "IA_LIVRE_METAL_INFER_MODE=$RUN_MODE"

LOG="$(mktemp)"
trap 'rm -f "$LOG"; [[ -n "${QEMU_PID:-}" ]] && kill -KILL "$QEMU_PID" 2>/dev/null || true' EXIT

if [[ "$RUN_MODE" == "full" ]]; then
  test -f scripts/run-qemu-esp-fat32.sh
  chmod +x scripts/run-qemu-esp-fat32.sh
  # Reuso de img se já existir (acelera re-corridas)
  export IA_LIVRE_BAREMETAL_SKIP_REBUILD="${IA_LIVRE_BAREMETAL_SKIP_REBUILD:-0}"
  ./scripts/run-qemu-esp-fat32.sh >"$LOG" 2>&1 &
else
  test -f scripts/run-qemu-esp-only.sh
  chmod +x scripts/run-qemu-esp-only.sh
  ./scripts/run-qemu-esp-only.sh >"$LOG" 2>&1 &
fi
QEMU_PID=$!

deadline=$((SECONDS + TIMEOUT_SEC))
have_a() {
  grep -q 'IA_LIVRE_BOOT_OK' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_EXIT_BOOT_OK' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_GGUF_PATH=esp_sfs' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_GGUF_NATIVE_LOADER=esp_sfs_full' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_GGUF_MAGIC_OK' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_GGUF_HEADER_OK' "$LOG" 2>/dev/null
}
have_legacy() {
  grep -q 'IA_LIVRE_BOOT_OK' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_EXIT_BOOT_OK' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_GGUF_PATH=esp_sfs' "$LOG" 2>/dev/null \
    && grep -q 'IA_LIVRE_B_BLOCK_METAL=no_gguf_metal_io' "$LOG" 2>/dev/null
}

while (( SECONDS < deadline )); do
  if [[ "$RUN_MODE" == "full" ]]; then
    have_a && break
  else
    have_legacy && break
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

# Fraudes comuns
if grep -q 'IA_LIVRE_BAREMETAL_METAL_OK' "$LOG"; then
  echo "GATE_FAIL: não emitir METAL_OK neste gate"
  fail=1
fi
if grep -q 'IA_LIVRE_GGUF_PATH=blockio' "$LOG"; then
  echo "GATE_FAIL: path metal não deve usar PATH=blockio"
  fail=1
fi
if grep -q 'IA_LIVRE_GGUF_NATIVE_LOADER=blockio_full' "$LOG"; then
  echo "GATE_FAIL: BlockIO-as-metal (blockio_full no gate metal)"
  fail=1
fi

if [[ "$RUN_MODE" == "full" ]]; then
  for m in IA_LIVRE_BOOT_OK IA_LIVRE_EXIT_BOOT_OK \
    'IA_LIVRE_GGUF_PATH=esp_sfs' \
    'IA_LIVRE_GGUF_NATIVE_LOADER=esp_sfs_full' \
    IA_LIVRE_GGUF_MAGIC_OK IA_LIVRE_GGUF_HEADER_OK; do
    if ! grep -q "$m" "$LOG"; then
      echo "GATE_FAIL: marcador ausente (A): $m"
      fail=1
    fi
  done
  # no_gguf_metal_io não deve ser o desfecho A
  if grep -q 'IA_LIVRE_B_BLOCK_METAL=no_gguf_metal_io' "$LOG"; then
    echo "GATE_FAIL: desfecho A não deve emitir no_gguf_metal_io"
    fail=1
  fi
  if (( fail == 0 )); then
    echo "IA_LIVRE_GGUF_NATIVE_LOADER=esp_sfs_full"
    echo "IA_LIVRE_GGUF_PATH=esp_sfs"
    echo "IA_LIVRE_METAL_INFER_OK"
    echo "GATE_OK: metal-infer — FAT32 SFS full (E63 A; ≠ BlockIO; ≠ METAL_OK)"
    exit 0
  fi
else
  for m in IA_LIVRE_BOOT_OK IA_LIVRE_EXIT_BOOT_OK \
    'IA_LIVRE_GGUF_PATH=esp_sfs' \
    'IA_LIVRE_B_BLOCK_METAL=no_gguf_metal_io'; do
    if ! grep -q "$m" "$LOG"; then
      echo "GATE_FAIL: marcador ausente (legacy): $m"
      fail=1
    fi
  done
  # TOKENS no path bloqueado = fraude
  if grep -qE 'IA_LIVRE_RUNTIME_NATIVE_TOKENS_PER_S_MILLI=' "$LOG"; then
    echo "GATE_FAIL: TOKENS no path esp_sfs bloqueado (fraude)"
    fail=1
  fi
  if (( fail == 0 )); then
    echo "IA_LIVRE_B_BLOCK_METAL=no_gguf_metal_io"
    echo "IA_LIVRE_METAL_INFER_OK"
    echo "GATE_OK: metal-infer — ESP-only legacy B_BLOCK (E48; ≠ BlockIO; ≠ METAL_OK)"
    exit 0
  fi
fi

echo "---- serial (últimas 50) ----"
tail -n 50 "$LOG" || true
exit 1
