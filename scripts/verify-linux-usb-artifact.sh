#!/usr/bin/env bash
# Gate artefato USB Linux (sem device físico).
set -euo pipefail
cd "$(dirname "$0")/.."
chmod +x scripts/prepare-linux-usb-artifact.sh scripts/write-linux-usb.sh

./scripts/prepare-linux-usb-artifact.sh
test -f build/linux-usb/ia-livre-distro-rootfs.tar.gz
test -f build/linux-usb/SHA256SUMS
test -f build/linux-usb/INSTALL.txt
test -f docs/guia-ia-livre-linux-usb.md
grep -q 'IA_LIVRE_WRITE_LINUX_USB_OK' scripts/write-linux-usb.sh
grep -q -- '--confirm' scripts/write-linux-usb.sh
(
  cd build/linux-usb
  sha256sum -c SHA256SUMS
)

echo "IA_LIVRE_LINUX_USB_ARTIFACT_GATE_OK"
echo "GATE_OK: linux-usb artifact — tar+checksums (≠ gravação real; ≠ ESP UEFI)"
