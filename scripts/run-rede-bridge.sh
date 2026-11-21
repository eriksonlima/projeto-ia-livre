#!/usr/bin/env bash
# Bridge Rede UEFI↔host (Etapa 52 / ADR 0019). Evidência nativa + âncora ia-livre-node.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$(pwd)/target}"

LOG=""
MODE="host_uefi"
SRC="serial_exit"

usage() {
  cat <<'EOF'
Uso: ./scripts/run-rede-bridge.sh --log FILE

  --log FILE   Serial/log com EXIT_BOOT_OK (fixture ou captura QEMU)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --log) LOG="${2:-}"; shift 2 ;;
    *) echo "erro: opção $1" >&2; exit 1 ;;
  esac
done

[[ -n "$LOG" && -f "$LOG" ]] || { usage; exit 1; }

grep -q 'IA_LIVRE_EXIT_BOOT_OK' "$LOG" \
  || { echo "erro: log sem EXIT_BOOT_OK (caminho B)" >&2; exit 1; }

# Âncora Rede host: dois nós --peer até TASK_OK (sem QEMU)
cargo build -q -p ia-livre-node
BIN="${CARGO_TARGET_DIR}/debug/ia-livre-node"
mkdir -p build/node-keys
A_LOG="$(mktemp)"
B_LOG="$(mktemp)"
cleanup() {
  [[ -n "${A_PID:-}" ]] && kill "$A_PID" 2>/dev/null || true
  [[ -n "${B_PID:-}" ]] && kill "$B_PID" 2>/dev/null || true
  wait "${A_PID:-}" "${B_PID:-}" 2>/dev/null || true
  rm -f "$A_LOG" "$B_LOG"
  return 0
}
trap cleanup EXIT

"$BIN" --tcp-port 7450 --udp-port 7460 --node-id bridge-a \
  --key-file build/node-keys/bridge-a.key >"$A_LOG" 2>&1 &
A_PID=$!
sleep 0.4
"$BIN" --tcp-port 7451 --udp-port 7460 --node-id bridge-b \
  --key-file build/node-keys/bridge-b.key --peer 127.0.0.1:7450 >"$B_LOG" 2>&1 &
B_PID=$!

deadline=$((SECONDS + 30))
ok=0
while (( SECONDS < deadline )); do
  if grep -q 'IA_LIVRE_TASK_OK' "$A_LOG" || grep -q 'IA_LIVRE_TASK_OK' "$B_LOG"; then
    ok=1
    break
  fi
  sleep 0.2
done

(( ok )) || {
  echo "erro: âncora Rede sem TASK_OK" >&2
  cat "$A_LOG" >&2
  cat "$B_LOG" >&2
  exit 1
}

echo "IA_LIVRE_NET_BRIDGE_MODE=${MODE}"
echo "IA_LIVRE_NET_BRIDGE_NATIVE_SRC=${SRC}"
echo "IA_LIVRE_NET_BRIDGE_OK"
exit 0
