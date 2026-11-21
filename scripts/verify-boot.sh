#!/usr/bin/env bash
# Gate do kernel (Etapas 4 / 10 / 11): serial QEMU com BOOT_OK + MEM/ALLOC + EXIT_BOOT_OK.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

MARKERS=(
  "IA_LIVRE_BOOT_OK"
  "IA_LIVRE_MEM_MAP_OK"
  "IA_LIVRE_ALLOC_OK"
  "IA_LIVRE_EXIT_BOOT_BEGIN"
  "IA_LIVRE_EXIT_MAP_OK"
  "IA_LIVRE_EXIT_MEM_OK"
  "IA_LIVRE_EXIT_BOOT_OK"
  "IA_LIVRE_GGUF_MAGIC_OK"
  "IA_LIVRE_GGUF_HEADER_OK"
  "IA_LIVRE_GGUF_NATIVE_LOADER=blockio_full"
  "IA_LIVRE_GGUF_TENSORS_STUB_OK"
  "IA_LIVRE_NATIVE_INFER_BEGIN"
  "IA_LIVRE_RUNTIME_NATIVE_LAYOUT_OK"
  "IA_LIVRE_GGUF_STATUS=layout_ok"
  "IA_LIVRE_RUNTIME_NATIVE_TENSOR_MAP_OK"
  "IA_LIVRE_RUNTIME_NATIVE_Q4K_DEQUANT_OK"
  "IA_LIVRE_RUNTIME_NATIVE_FORWARD_OP_OK"
  "IA_LIVRE_RUNTIME_NATIVE_TOKENIZE_OK"
  "IA_LIVRE_RUNTIME_NATIVE_EMBED_OK"
  "IA_LIVRE_RUNTIME_NATIVE_LAYER_PARTIAL_OK"
  "IA_LIVRE_RUNTIME_NATIVE_ATTN_LAYER_OK"
  "IA_LIVRE_RUNTIME_NATIVE_FORWARD_FAIL=no_decode"
  "IA_LIVRE_TYPED_WEIGHTS_OK"
  "IA_LIVRE_TYPED_KVCACHE_OK"
  "IA_LIVRE_PHASE=prefill"
  "IA_LIVRE_PHASE=decode"
  "IA_LIVRE_MEM_SCHED_OK"
  "IA_LIVRE_NATIVE_BENCH_OK"
)
NUMERIC=(
  "IA_LIVRE_MEM_CONVENTIONAL_PAGES="
  "IA_LIVRE_ALLOC_BYTES="
  "IA_LIVRE_EXIT_MAP_PAGES="
  "IA_LIVRE_GGUF_BYTES="
  "IA_LIVRE_TYPED_WEIGHTS_BYTES="
  "IA_LIVRE_TYPED_KVCACHE_BYTES="
  "IA_LIVRE_QUANTUM="
  "IA_LIVRE_NATIVE_BENCH_OPS="
  "IA_LIVRE_NATIVE_BENCH_MS="
)

# Etapa 27: carga GGUF ~638 MiB via FAT pode demorar.
TIMEOUT_SEC="${VERIFY_TIMEOUT:-300}"
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
    echo "GATE_OK: kernel — BOOT_OK … EXIT_BOOT_OK + GGUF blockio_full + LAYOUT_OK + MEM_SCHED_OK + NATIVE_BENCH_OK"
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
