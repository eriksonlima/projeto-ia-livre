#!/usr/bin/env bash
# Prepara build/linux-usb/ — tar + ISO (se buildável) + README + checksums.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"

./scripts/pack-distro-rootfs.sh

OUT=build/linux-usb
rm -rf "$OUT"
mkdir -p "$OUT"
cp -f build/ia-livre-distro-rootfs.tar.gz "$OUT/"
cp -f docs/guia-ia-livre-linux-usb.md "$OUT/README-USB.md"

# ISO híbrida (E85) — best-effort; artefato ainda OK só com tar
ISO_SRC=build/distro-debian/ia-livre-linux.iso
if [[ ! -f "$ISO_SRC" ]]; then
  chmod +x scripts/build-distro-debian-iso.sh
  ./scripts/build-distro-debian-iso.sh || true
fi
if [[ -f "$ISO_SRC" ]]; then
  cp -f "$ISO_SRC" "$OUT/ia-livre-linux.iso"
  echo "IA_LIVRE_LINUX_USB_ISO=included"
else
  echo "IA_LIVRE_LINUX_USB_ISO=skipped"
fi

cat >"$OUT/INSTALL.txt" <<'EOF'
IA Livre Linux — artefato USB (ADR 0027)

## Opção A — ISO live (recomendado se ia-livre-linux.iso estiver presente)

  ./scripts/write-linux-usb.sh --mode iso --device /dev/sdX --confirm /dev/sdX --yes
  # ou: sudo dd if=ia-livre-linux.iso of=/dev/sdX bs=4M status=progress conv=fsync

Boot UEFI no PC; first-boot: /etc/ia-livre/FIRST_BOOT.md

## Opção B — tarball em Debian já instalado

  sudo tar -C / -xzf ia-livre-distro-rootfs.tar.gz
  export PATH=/opt/ia-livre/bin:$PATH
  ia-livre model list

Não confundir com o pendrive ESP UEFI (Linha B arquivada).
EOF

(
  cd "$OUT"
  files=(ia-livre-distro-rootfs.tar.gz README-USB.md INSTALL.txt)
  [[ -f ia-livre-linux.iso ]] && files+=(ia-livre-linux.iso)
  sha256sum "${files[@]}" >SHA256SUMS
)

echo "IA_LIVRE_LINUX_USB_DIR=$OUT"
echo "IA_LIVRE_LINUX_USB_ARTIFACT_OK"
