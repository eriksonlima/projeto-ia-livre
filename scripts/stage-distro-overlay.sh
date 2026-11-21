#!/usr/bin/env bash
# Monta binários da stack no overlay distro/ (scaffold Linux IA-nativo).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
if [[ -z "${BINDGEN_EXTRA_CLANG_ARGS:-}" ]]; then
  export BINDGEN_EXTRA_CLANG_ARGS="-I/usr/lib/gcc/x86_64-linux-gnu/13/include -I/usr/include"
fi

OUT=distro/overlay/opt/ia-livre/bin
mkdir -p "$OUT" distro/overlay/var/lib/ia-livre/models \
  distro/overlay/var/lib/ia-livre/agent-memory \
  distro/overlay/etc/ia-livre

echo "stage: building runtime, agent, node…"
cargo build -p ia-livre-runtime -p ia-livre-agent -p ia-livre-node --release

cp -f target/release/ia-livre-runtime "$OUT/"
cp -f target/release/ia-livre-agent "$OUT/"
cp -f target/release/ia-livre-node "$OUT/"
chmod +x distro/overlay/opt/ia-livre/bin/ia-livre
chmod +x distro/overlay/opt/ia-livre/bin/ia-livre-native-tune 2>/dev/null || true
chmod +x "$OUT"/ia-livre-runtime "$OUT"/ia-livre-agent "$OUT"/ia-livre-node

# Modelo opcional (não falha se ausente)
GGUF=models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
if [[ -f "$GGUF" ]]; then
  cp -f "$GGUF" distro/overlay/var/lib/ia-livre/models/
  echo "stage: GGUF presente no overlay models/"
else
  echo "stage: nota — GGUF ausente (rode ./scripts/fetch-model.sh para infer smoke)"
fi

echo "IA_LIVRE_DISTRO_OVERLAY=$OUT"
echo "IA_LIVRE_DISTRO_STAGE_OK"
