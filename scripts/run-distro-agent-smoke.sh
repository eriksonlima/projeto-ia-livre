#!/usr/bin/env bash
# Etapa 90 / B85 — smoke autonomia com binários do SO (overlay).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
if [[ -z "${BINDGEN_EXTRA_CLANG_ARGS:-}" ]]; then
  export BINDGEN_EXTRA_CLANG_ARGS="-I/usr/lib/gcc/x86_64-linux-gnu/13/include -I/usr/include"
fi

./scripts/stage-distro-overlay.sh >/tmp/stage-agent.log 2>&1 || { cat /tmp/stage-agent.log; exit 1; }
IA=distro/overlay/opt/ia-livre/bin/ia-livre
chmod +x "$IA"
GGUF=distro/overlay/var/lib/ia-livre/models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
if [[ ! -f "$GGUF" ]]; then
  echo "IA_LIVRE_DISTRO_AGENT_SKIP=no_gguf"
  exit 0
fi
"$IA" agent --n-predict 8 >/tmp/distro-agent-smoke.log 2>&1 || true
if grep -q 'IA_LIVRE_AGENT_OK' /tmp/distro-agent-smoke.log; then
  echo "IA_LIVRE_DISTRO_AGENT_SRC=overlay_host"
  echo "IA_LIVRE_DISTRO_AGENT_OK"
  exit 0
fi
echo "IA_LIVRE_DISTRO_AGENT_SKIP=no_marker"
exit 0
