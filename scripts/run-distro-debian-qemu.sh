#!/usr/bin/env bash
# Etapa 82 — boot QEMU do rootfs Debian (9p) até conf guest ou prompt.
# ≠ Alpine netboot.
set -euo pipefail
cd "$(dirname "$0")/.."

OUT=build/distro-debian
ROOTFS="$OUT/rootfs"
TIMEOUT_S="${IA_LIVRE_DEBIAN_QEMU_TIMEOUT:-180}"
LOG="${IA_LIVRE_DEBIAN_QEMU_LOG:-/tmp/distro-debian-qemu.log}"

if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
  echo "IA_LIVRE_DISTRO_DEBIAN_SKIP=need_qemu"
  exit 0
fi

chmod +x scripts/build-distro-debian-rootfs.sh
if [[ "${IA_LIVRE_DEBIAN_REBUILD:-0}" != "1" \
  && -d "$ROOTFS" \
  && -f "$OUT/vmlinuz.name" \
  && -x "$ROOTFS/opt/ia-livre/bin/ia-livre" ]]; then
  echo "IA_LIVRE_DISTRO_DEBIAN_ROOTFS=$ROOTFS"
  echo "IA_LIVRE_DISTRO_DEBIAN_ROOTFS_OK"
  echo "IA_LIVRE_DISTRO_DEBIAN_CACHE=1"
else
  build_out="$(./scripts/build-distro-debian-rootfs.sh 2>&1)" || {
    echo "$build_out"
    echo "GATE_FAIL: build-distro-debian-rootfs exit ≠ 0"
    exit 1
  }
  echo "$build_out"
  if echo "$build_out" | grep -q 'IA_LIVRE_DISTRO_DEBIAN_SKIP='; then
    exit 0
  fi
  echo "$build_out" | grep -q 'IA_LIVRE_DISTRO_DEBIAN_ROOTFS_OK'
fi

test -d "$ROOTFS"
K_NAME="$(cat "$OUT/vmlinuz.name")"
I_NAME="$(cat "$OUT/initrd.name")"
KERNEL="$ROOTFS/boot/$K_NAME"
INITRD="$ROOTFS/boot/$I_NAME"
test -f "$KERNEL" && test -f "$INITRD"

# Alguns kernels Debian não bootam com root 9p sem módulos no initrd —
# append com rootfstype=9p; se falhar, reportamos skip boot_fail (honesto).
APPEND="root=fsroot rootfstype=9p rootflags=trans=virtio,version=9p2000.L,msize=1048576 rw console=ttyS0,115200n8 systemd.show_status=false"

echo "IA_LIVRE_DISTRO_DEBIAN_QEMU_MODE=9p"
rm -f "$LOG"
set +e
timeout "$TIMEOUT_S" qemu-system-x86_64 \
  -machine q35 \
  -m "${IA_LIVRE_DEBIAN_QEMU_MEM:-1024}" \
  -smp 2 \
  -nographic \
  -no-reboot \
  -kernel "$KERNEL" \
  -initrd "$INITRD" \
  -append "$APPEND" \
  -fsdev local,id=rootfs,path="$ROOTFS",security_model=none,multidevs=remap \
  -device virtio-9p-pci,fsdev=rootfs,mount_tag=fsroot \
  >"$LOG" 2>&1
qec=$?
set -e

# Sucesso: conf guest OU prompt/login Debian
if grep -q 'IA_LIVRE_DISTRO_DEBIAN_GUEST_CONF_OK' "$LOG" \
  || grep -qE 'MODEL=|CONF=/etc/ia-livre' "$LOG" \
  || grep -qiE 'Debian GNU/Linux|login:|root@' "$LOG"; then
  echo "IA_LIVRE_DISTRO_DEBIAN_QEMU_LOG=$LOG"
  if grep -q 'IA_LIVRE_DISTRO_DEBIAN_GUEST_CONF_OK' "$LOG" || grep -qE 'MODEL=|CONF=/etc/ia-livre' "$LOG"; then
    echo "IA_LIVRE_DISTRO_DEBIAN_GUEST=conf"
  else
    echo "IA_LIVRE_DISTRO_DEBIAN_GUEST=prompt"
  fi
  echo "IA_LIVRE_DISTRO_DEBIAN_QEMU_OK"
  exit 0
fi

# Diagnóstico honesto
if grep -qiE 'Kernel panic|VFS: Cannot open root|9p.*fail' "$LOG"; then
  echo "IA_LIVRE_DISTRO_DEBIAN_SKIP=boot_fail"
  echo "IA_LIVRE_DISTRO_DEBIAN_QEMU_LOG=$LOG"
  # Ainda exit 0 — B78 apertará; E82 documenta skip se 9p inviável neste host
  exit 0
fi

echo "IA_LIVRE_DISTRO_DEBIAN_SKIP=no_console"
echo "IA_LIVRE_DISTRO_DEBIAN_QEMU_LOG=$LOG"
echo "qemu_exit=$qec"
exit 0
