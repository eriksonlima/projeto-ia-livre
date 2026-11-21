#!/usr/bin/env bash
# Gate Etapa 76: script collect presente e smoke (sem USB).
set -euo pipefail
cd "$(dirname "$0")/.."

test -f scripts/collect-baremetal-report.sh
chmod +x scripts/collect-baremetal-report.sh
grep -q 'IA_LIVRE_COLLECT_OK' scripts/collect-baremetal-report.sh
grep -q 'baremetal-report.txt' scripts/collect-baremetal-report.sh
grep -q 'verify-baremetal' scripts/collect-baremetal-report.sh

# Smoke: copia fixture local como se fosse mount
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/IA_LIVRE"
cp docs/evidence/boot-metal/fixture-esp-report.txt "$tmp/IA_LIVRE/baremetal-report.txt"
out="$tmp/out.txt"
./scripts/collect-baremetal-report.sh --mount "$tmp" --out "$out"
test -f "$out"
grep -q 'IA_LIVRE_BOOT_OK' "$out"

echo "IA_LIVRE_COLLECT_SCRIPT_OK"
echo "GATE_OK: collect-baremetal-report — script + smoke fixture (≠ USB real; ≠ METAL_OK)"
