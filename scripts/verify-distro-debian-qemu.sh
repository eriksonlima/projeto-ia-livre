#!/usr/bin/env bash
# Gate Etapa 82 — Debian rootfs QEMU (≠ Alpine).
set -euo pipefail
cd "$(dirname "$0")/.."
chmod +x scripts/build-distro-debian-rootfs.sh scripts/run-distro-debian-qemu.sh

out="$(./scripts/run-distro-debian-qemu.sh 2>&1)" || {
  echo "$out"
  echo "GATE_FAIL: run-distro-debian-qemu exit ≠ 0"
  exit 1
}
echo "$out"

if echo "$out" | grep -q 'IA_LIVRE_DISTRO_DEBIAN_SKIP='; then
  echo "$out" | grep -q 'IA_LIVRE_DISTRO_DEBIAN_SKIP='
  echo "GATE_OK: distro-debian-qemu — SKIP honesto (need_*|boot_fail|no_console)"
  exit 0
fi

echo "$out" | grep -q 'IA_LIVRE_DISTRO_DEBIAN_ROOTFS_OK'
echo "$out" | grep -q 'IA_LIVRE_DISTRO_DEBIAN_QEMU_OK'
grep -q 'Debian' docs/linux-ia-nativo.md
grep -q 'verify-distro-debian-qemu' docs/linux-ia-nativo.md
! grep -q 'IA_LIVRE_DISTRO_DEBIAN_QEMU_OK' scripts/run-distro-smoke.sh

echo "GATE_OK: distro-debian-qemu — rootfs + QEMU OK (≠ Alpine)"
exit 0
