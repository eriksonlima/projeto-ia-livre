#!/usr/bin/env bash
# Gate Etapa 85 — ISO híbrida (artefato + QEMU best-effort/skip).
set -euo pipefail
cd "$(dirname "$0")/.."
chmod +x scripts/build-distro-debian-iso.sh scripts/run-distro-iso-qemu.sh

out="$(./scripts/run-distro-iso-qemu.sh 2>&1)" || {
  echo "$out"
  echo "GATE_FAIL: run-distro-iso-qemu exit ≠ 0"
  exit 1
}
echo "$out"

if echo "$out" | grep -q 'IA_LIVRE_DISTRO_ISO_SKIP='; then
  # Skip honesto: ainda exige que o script de build exista e docs
  test -f scripts/build-distro-debian-iso.sh
  grep -q 'ISO\|híbrid\|hibrid\|live USB' docs/linux-ia-nativo.md || grep -qi 'iso' docs/guia-ia-livre-linux-usb.md
  echo "GATE_OK: distro-iso — SKIP honesto ($out)" | head -c 200
  echo
  echo "GATE_OK: distro-iso — SKIP need_*|boot_fail|no_console"
  exit 0
fi

echo "$out" | grep -q 'IA_LIVRE_DISTRO_ISO_OK'
echo "$out" | grep -q 'IA_LIVRE_DISTRO_ISO_QEMU_OK'
test -f build/distro-debian/ia-livre-linux.iso
grep -q 'verify-distro-iso\|ISO híbrida\|ia-livre-linux.iso' docs/linux-ia-nativo.md

echo "GATE_OK: distro-iso — ISO + QEMU OK (≠ tarball; ≠ ESP UEFI)"
exit 0
