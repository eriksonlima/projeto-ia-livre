#!/usr/bin/env bash
# Gate artefato USB Linux (sem device físico) — tar + ISO quando disponível.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"
chmod +x scripts/prepare-linux-usb-artifact.sh scripts/write-linux-usb.sh

./scripts/prepare-linux-usb-artifact.sh
test -f build/linux-usb/ia-livre-distro-rootfs.tar.gz
test -f build/linux-usb/SHA256SUMS
test -f build/linux-usb/INSTALL.txt
test -f docs/guia-ia-livre-linux-usb.md
grep -q 'IA_LIVRE_WRITE_LINUX_USB_OK' scripts/write-linux-usb.sh
grep -q -- '--confirm' scripts/write-linux-usb.sh
grep -q -- '--mode iso' scripts/write-linux-usb.sh
grep -q 'dd if=' scripts/write-linux-usb.sh

(
  cd build/linux-usb
  sha256sum -c SHA256SUMS
)

if [[ -f build/linux-usb/ia-livre-linux.iso ]]; then
  echo "IA_LIVRE_LINUX_USB_ISO_GATE=present"
else
  echo "IA_LIVRE_LINUX_USB_ISO_GATE=absent_ok"
fi

echo "IA_LIVRE_LINUX_USB_ARTIFACT_GATE_OK"
echo "GATE_OK: linux-usb artifact — tar(+ISO) + writer --mode iso (≠ gravação real; ≠ ESP)"
