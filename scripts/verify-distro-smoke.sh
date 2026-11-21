#!/usr/bin/env bash
# Gate smoke (E80 userspace + E83 QEMU Debian).
set -euo pipefail
cd "$(dirname "$0")/.."
chmod +x scripts/run-distro-smoke.sh scripts/pack-distro-rootfs.sh

out="$(./scripts/run-distro-smoke.sh 2>&1)" || {
  echo "$out"
  echo "GATE_FAIL: run-distro-smoke exit ≠ 0"
  exit 1
}
echo "$out"
echo "$out" | grep -q 'IA_LIVRE_DISTRO_ROOTFS_OK'
echo "$out" | grep -q 'IA_LIVRE_DISTRO_SMOKE_OK'

# E83: QEMU Debian OK **ou** skip need_* (nunca Alpine como prova)
if echo "$out" | grep -q 'IA_LIVRE_DISTRO_QEMU_OK'; then
  echo "$out" | grep -qE 'IA_LIVRE_DISTRO_QEMU_SRC=debian|IA_LIVRE_DISTRO_DEBIAN_QEMU_OK'
elif echo "$out" | grep -q 'IA_LIVRE_DISTRO_QEMU_SKIP='; then
  echo "$out" | grep -q 'IA_LIVRE_DISTRO_QEMU_SKIP='
else
  echo "GATE_FAIL: falta DISTRO_QEMU_OK ou DISTRO_QEMU_SKIP"
  exit 1
fi

echo "GATE_OK: distro-smoke — userspace + QEMU Debian (ou SKIP need_*)"
exit 0
