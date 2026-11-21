#!/usr/bin/env bash
# Smoke Linux IA-nativo: userspace (sempre) + QEMU Alpine opt-in/best-effort.
# ≠ metal UEFI. ≠ COMPROVA.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
if [[ -z "${BINDGEN_EXTRA_CLANG_ARGS:-}" ]]; then
  export BINDGEN_EXTRA_CLANG_ARGS="-I/usr/lib/gcc/x86_64-linux-gnu/13/include -I/usr/include"
fi

IA=distro/overlay/opt/ia-livre/bin/ia-livre
./scripts/pack-distro-rootfs.sh

chmod +x "$IA" distro/overlay/opt/ia-livre/bin/ia-livre-native-tune

echo "IA_LIVRE_DISTRO_SMOKE_MODE=userspace"
"$IA" conf | grep -q MODEL=
./distro/overlay/opt/ia-livre/bin/ia-livre-native-tune | grep -q 'IA_LIVRE_NATIVE_TUNE_OK'

GGUF=distro/overlay/var/lib/ia-livre/models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
if [[ -f "$GGUF" ]]; then
  "$IA" infer --n-predict 8 >/tmp/distro-smoke-infer.log 2>&1
  grep -q 'IA_LIVRE_INFER_OK' /tmp/distro-smoke-infer.log
  echo "IA_LIVRE_DISTRO_SMOKE_INFER_OK"
  # Agent one-shot curto (pode ser lento)
  "$IA" agent --n-predict 8 >/tmp/distro-smoke-agent.log 2>&1 || true
  if grep -q 'IA_LIVRE_AGENT_OK' /tmp/distro-smoke-agent.log; then
    echo "IA_LIVRE_DISTRO_SMOKE_AGENT_OK"
  else
    echo "IA_LIVRE_DISTRO_SMOKE_AGENT_SKIP=no_marker"
  fi
else
  echo "IA_LIVRE_DISTRO_SMOKE_INFER_SKIP=no_gguf"
fi

# --- QEMU Debian (Etapa 83 / B78) — exige imagem E82; ≠ Alpine ---
QEMU_SKIP="${VERIFY_DISTRO_QEMU_SKIP:-0}"
if [[ "$QEMU_SKIP" == "1" ]]; then
  echo "IA_LIVRE_DISTRO_QEMU_SKIP=forced"
else
  chmod +x scripts/run-distro-debian-qemu.sh
  deb_out="$(./scripts/run-distro-debian-qemu.sh 2>&1)" || {
    echo "$deb_out"
    echo "GATE_FAIL: debian qemu no smoke"
    exit 1
  }
  echo "$deb_out"
  if echo "$deb_out" | grep -q 'IA_LIVRE_DISTRO_DEBIAN_QEMU_OK'; then
    echo "IA_LIVRE_DISTRO_QEMU_OK"
    echo "IA_LIVRE_DISTRO_QEMU_SRC=debian"
  elif echo "$deb_out" | grep -q 'IA_LIVRE_DISTRO_DEBIAN_SKIP='; then
    skip="$(echo "$deb_out" | grep -o 'IA_LIVRE_DISTRO_DEBIAN_SKIP=[^[:space:]]*' | head -1 | cut -d= -f2)"
    echo "IA_LIVRE_DISTRO_QEMU_SKIP=${skip:-need_debian}"
  else
    echo "IA_LIVRE_DISTRO_QEMU_SKIP=no_debian_marker"
  fi
fi

echo "IA_LIVRE_DISTRO_SMOKE_OK"
