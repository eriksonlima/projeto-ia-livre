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

# --- QEMU (Alpine virt) best-effort ---
QEMU_SKIP="${VERIFY_DISTRO_QEMU_SKIP:-0}"
if [[ "$QEMU_SKIP" == "1" ]]; then
  echo "IA_LIVRE_DISTRO_QEMU_SKIP=forced"
elif ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
  echo "IA_LIVRE_DISTRO_QEMU_SKIP=need_qemu"
else
  CACHE=build/distro-smoke-cache
  mkdir -p "$CACHE"
  ALPINE_VER="${IA_LIVRE_ALPINE_VER:-3.20.3}"
  BASE="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VER%.*}/releases/x86_64"
  KERNEL="$CACHE/vmlinuz-virt"
  INITRD="$CACHE/initramfs-virt"
  if [[ ! -f "$KERNEL" || ! -f "$INITRD" ]]; then
    echo "distro-smoke: baixando Alpine virt kernel/initrd…"
    if ! curl -fsSL -o "$KERNEL" "$BASE/netboot/vmlinuz-virt" \
      || ! curl -fsSL -o "$INITRD" "$BASE/netboot/initramfs-virt"; then
      echo "IA_LIVRE_DISTRO_QEMU_SKIP=need_net"
      echo "IA_LIVRE_DISTRO_SMOKE_OK"
      exit 0
    fi
  fi
  # Boot curto só para provar QEMU+kernel (login Alpine netboot; não monta nosso rootfs completo ainda)
  LOG=/tmp/distro-qemu-smoke.log
  timeout 25 qemu-system-x86_64 \
    -machine q35 \
    -m 512M \
    -nographic \
    -kernel "$KERNEL" \
    -initrd "$INITRD" \
    -append "console=ttyS0 quiet" \
    >"$LOG" 2>&1 || true
  if grep -qiE 'Alpine|login:|Kernel panic' "$LOG"; then
    # panic = ainda “subiu” o kernel; login/Alpine = ok
    if grep -qi 'Kernel panic' "$LOG" && ! grep -qiE 'Alpine|login:' "$LOG"; then
      echo "IA_LIVRE_DISTRO_QEMU_SKIP=boot_panic"
    else
      echo "IA_LIVRE_DISTRO_QEMU_OK"
    fi
  else
    echo "IA_LIVRE_DISTRO_QEMU_SKIP=no_console"
  fi
fi

echo "IA_LIVRE_DISTRO_SMOKE_OK"
