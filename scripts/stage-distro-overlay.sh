#!/usr/bin/env bash
# Monta binários da stack no overlay distro/ (scaffold Linux IA-nativo).
set -euo pipefail
cd "$(dirname "$0")/.."
# Sob sudo, PATH/HOME do usuário real
if [[ -n "${SUDO_USER:-}" ]]; then
  SUDO_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
  export HOME="${SUDO_HOME}"
  export PATH="${SUDO_HOME}/.cargo/bin:${SUDO_HOME}/.local/bin:/usr/local/bin:/usr/bin:${PATH}"
else
  export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
fi
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
if [[ -z "${BINDGEN_EXTRA_CLANG_ARGS:-}" ]]; then
  export BINDGEN_EXTRA_CLANG_ARGS="-I/usr/lib/gcc/x86_64-linux-gnu/13/include -I/usr/include"
fi

if ! command -v cargo >/dev/null 2>&1; then
  echo "erro: cargo não encontrado no PATH (sob sudo use ISO já buildada, ou rode stage sem sudo)" >&2
  echo "  ./scripts/build-distro-debian-iso.sh" >&2
  echo "  sudo ./scripts/write-linux-usb.sh --mode iso --device /dev/sdX --confirm /dev/sdX --yes" >&2
  exit 1
fi

OUT=distro/overlay/opt/ia-livre/bin
mkdir -p "$OUT" distro/overlay/var/lib/ia-livre/models \
  distro/overlay/var/lib/ia-livre/agent-memory \
  distro/overlay/etc/ia-livre

echo "stage: building runtime, agent, node…"
# Debian live = bookworm (glibc 2.36). Build no host Ubuntu novo exige GLIBC_2.39+
# e quebra no guest — preferir Docker bookworm (IA_LIVRE_STAGE_HOST=1 força host).
STAGE_HOST="${IA_LIVRE_STAGE_HOST:-0}"
if [[ "$STAGE_HOST" != "1" ]] && command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  echo "stage: cargo --release via Docker rust:bookworm (glibc live)…"
  docker run --rm \
    -v "$PWD:/src:rw" \
    -w /src \
    -e CARGO_HOME=/src/build/cargo-home-bookworm \
    -e TARGET_DIR=/src/build/target-bookworm \
    rust:bookworm bash -c '
set -euo pipefail
export PATH="/usr/local/cargo/bin:/usr/local/rustup/bin:${PATH:-/usr/bin}"
export DEBIAN_FRONTEND=noninteractive
# Portátil p/ QEMU qemu64 / CPUs velhos (sem AVX2/FMA nativo do builder)
export CMAKE_ARGS="${CMAKE_ARGS:--DGGML_NATIVE=OFF -DGGML_AVX=ON -DGGML_AVX2=OFF -DGGML_FMA=OFF -DGGML_F16C=OFF}"
export RUSTFLAGS="${RUSTFLAGS:--C target-cpu=x86-64}"
apt-get update -qq
apt-get install -y -qq build-essential cmake libclang-dev pkg-config >/dev/null
mkdir -p "$CARGO_HOME" "$TARGET_DIR"
export CARGO_TARGET_DIR="$TARGET_DIR"
command -v cargo
# força rebuild do llama-cpp-sys se target já existir com native
cargo clean -p llama-cpp-sys-2 2>/dev/null || true
cargo build -p ia-livre-runtime -p ia-livre-agent -p ia-livre-node --release
'
  REL=build/target-bookworm/release
  cp -f "$REL/ia-livre-runtime" "$OUT/"
  cp -f "$REL/ia-livre-agent" "$OUT/"
  cp -f "$REL/ia-livre-node" "$OUT/"
  echo "stage: binaries from bookworm target"
else
  if [[ "$STAGE_HOST" != "1" ]]; then
    echo "stage: aviso — Docker indisponível; build no host (pode falhar no Debian live por glibc)" >&2
  fi
  cargo build -p ia-livre-runtime -p ia-livre-agent -p ia-livre-node --release
  cp -f target/release/ia-livre-runtime "$OUT/"
  cp -f target/release/ia-livre-agent "$OUT/"
  cp -f target/release/ia-livre-node "$OUT/"
fi
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
