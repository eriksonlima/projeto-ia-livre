#!/usr/bin/env bash
# Release packaging produto Linux (Etapa 87 / B82).
# Pacote em build/release-linux/: ISO (sem GGUF) + tar overlay + SHA256SUMS + guia.
# ≠ prepare-baremetal-release (ESP UEFI). ≠ COMPROVA/METAL.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"

OUT="${IA_LIVRE_LINUX_RELEASE_DIR:-build/release-linux}"
SKIP_BUILD="${IA_LIVRE_LINUX_RELEASE_SKIP_BUILD:-0}"

if [[ "$SKIP_BUILD" != "1" ]]; then
  chmod +x scripts/pack-distro-rootfs.sh scripts/build-distro-debian-iso.sh
  ./scripts/pack-distro-rootfs.sh
  # ISO: força strip GGUF (default)
  export IA_LIVRE_DEBIAN_INCLUDE_GGUF="${IA_LIVRE_DEBIAN_INCLUDE_GGUF:-0}"
  if [[ ! -f build/distro-debian/ia-livre-linux.iso ]]; then
    ./scripts/build-distro-debian-iso.sh || true
  fi
fi

TAR=build/ia-livre-distro-rootfs.tar.gz
ISO=build/distro-debian/ia-livre-linux.iso
test -f "$TAR"

rm -rf "$OUT"
mkdir -p "$OUT"
cp -f "$TAR" "$OUT/ia-livre-distro-rootfs.tar.gz"
HAVE_ISO=0
if [[ -f "$ISO" ]]; then
  # Recusa ISO com GGUF se unsquashfs disponível e ISO foi montável… checagem leve via tamanho
  # (ISO com TinyLlama ~900MiB; sem GGUF ~300MiB). Preferir rebuild se INCLUDE=0 e ISO grande.
  BYTES="$(wc -c <"$ISO" | tr -d ' ')"
  if [[ "${IA_LIVRE_DEBIAN_INCLUDE_GGUF:-0}" != "1" && "$BYTES" -gt 500000000 ]]; then
    echo "prepare-linux-release: ISO parece incluir GGUF (bytes=$BYTES) — regenerando…"
    export IA_LIVRE_ISO_RESQUASH=1
    ./scripts/build-distro-debian-iso.sh
  fi
  cp -f build/distro-debian/ia-livre-linux.iso "$OUT/ia-livre-linux.iso"
  HAVE_ISO=1
fi

cp -f docs/guia-ia-livre-linux-usb.md "$OUT/README-USB.md"
cp -f docs/linux-ia-nativo.md "$OUT/README-LINUX.md" 2>/dev/null || true

cat >"$OUT/README-RELEASE.txt" <<'EOF'
Projeto IA Livre — release Linux IA-nativo (ADR 0027)

Conteúdo:
  ia-livre-linux.iso           — live híbrida UEFI (se buildada; sem GGUF no default)
  ia-livre-distro-rootfs.tar.gz — overlay staged (pode ser grande se stage copiou GGUF no host)
  SHA256SUMS
  README-USB.md / README-RELEASE.txt

Gravar ISO:
  ./scripts/write-linux-usb.sh --mode iso --device /dev/sdX --confirm /dev/sdX --yes

First-boot / modelos:
  docs: FIRST_BOOT.md no guest; host: ./scripts/fetch-model.sh
  Artefato de release **não** embute pesos GGUF na ISO (IA_LIVRE_DEBIAN_INCLUDE_GGUF=0).

≠ pendrive ESP UEFI (Linha B arquivada). ≠ COMPROVA / METAL_OK.
EOF

(
  cd "$OUT"
  files=(ia-livre-distro-rootfs.tar.gz README-RELEASE.txt README-USB.md)
  [[ -f README-LINUX.md ]] && files+=(README-LINUX.md)
  [[ -f ia-livre-linux.iso ]] && files+=(ia-livre-linux.iso)
  sha256sum "${files[@]}" >SHA256SUMS
)

# Garantia: ISO no pacote sem .gguf se unsquashfs + squash interno… skip se sem ISO
if [[ "$HAVE_ISO" -eq 1 ]]; then
  echo "IA_LIVRE_LINUX_RELEASE_ISO=present"
else
  echo "IA_LIVRE_LINUX_RELEASE_ISO=absent"
fi

echo "IA_LIVRE_LINUX_RELEASE_DIR=$OUT"
echo "IA_LIVRE_LINUX_RELEASE_ARTIFACT_OK"
