#!/usr/bin/env bash
# Prepara build/linux-usb/ (tar + README + checksums) — Etapa 81 / B76.
set -euo pipefail
cd "$(dirname "$0")/.."

./scripts/pack-distro-rootfs.sh

OUT=build/linux-usb
rm -rf "$OUT"
mkdir -p "$OUT"
cp -f build/ia-livre-distro-rootfs.tar.gz "$OUT/"
cp -f docs/guia-ia-livre-linux-usb.md "$OUT/README-USB.md"
cat >"$OUT/INSTALL.txt" <<'EOF'
IA Livre Linux — artefato USB (ADR 0027)

1. Em um Debian/Ubuntu mínimo:
   sudo tar -C / -xzf ia-livre-distro-rootfs.tar.gz
   # ou extraia só opt/ etc/ var/ conforme necessário

2. export PATH=/opt/ia-livre/bin:$PATH
3. ia-livre model list
4. ia-livre infer

Não confundir com o pendrive ESP UEFI (Linha B arquivada).
EOF

(
  cd "$OUT"
  sha256sum ia-livre-distro-rootfs.tar.gz README-USB.md INSTALL.txt >SHA256SUMS
)

echo "IA_LIVRE_LINUX_USB_DIR=$OUT"
echo "IA_LIVRE_LINUX_USB_ARTIFACT_OK"
