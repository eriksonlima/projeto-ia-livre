#!/usr/bin/env bash
# Gate Etapa 80 / B75
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

echo "GATE_OK: distro-smoke — rootfs tar + userspace (+ QEMU best-effort/skip)"
exit 0
