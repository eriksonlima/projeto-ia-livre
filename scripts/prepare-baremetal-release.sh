#!/usr/bin/env bash
# Prepara artefatos de release bare-metal (Etapa 57): ESP/tar (+img) + SHA256SUMS.
# Sem USB. Sem GGUF full por default. QEMU ≠ metal; não declara hipótese comprovada.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

OUT="${IA_LIVRE_RELEASE_DIR:-build/release}"
TAR_SRC="${IA_LIVRE_BAREMETAL_TAR:-build/ia-livre-esp.tar.gz}"
IMG_SRC="${IA_LIVRE_BAREMETAL_IMG:-build/ia-livre-esp.img}"
SKIP_BUILD="${IA_LIVRE_RELEASE_SKIP_BUILD:-0}"

if [[ "$SKIP_BUILD" != "1" ]]; then
  echo "prepare-baremetal-release: make baremetal-esp…"
  make baremetal-esp
fi

if [[ ! -f "$TAR_SRC" ]]; then
  echo "erro: tar ausente: $TAR_SRC (rode make baremetal-esp)" >&2
  exit 1
fi

rm -rf "$OUT"
mkdir -p "$OUT"
cp -f "$TAR_SRC" "$OUT/ia-livre-esp.tar.gz"
[[ -f "$IMG_SRC" ]] && cp -f "$IMG_SRC" "$OUT/ia-livre-esp.img" || true

# README curto do pacote
cat >"$OUT/README-RELEASE.txt" <<'EOF'
Projeto IA Livre — artefato ESP/USB (release)

Conteúdo típico:
  ia-livre-esp.tar.gz  — árvore ESP empacotada
  ia-livre-esp.img     — imagem FAT (se mtools estava disponível no build)
  SHA256SUMS           — checksums

Guia: docs/guia-primeiro-boot-usb.md
Gravar: ./scripts/write-usb-esp.sh (confirmação explícita do device)

Limites:
  - QEMU ≠ metal; gravação ≠ METAL_OK
  - Hipótese A vs B: INCONCLUSIVO (não comprovada por este artefato)
  - GGUF completo (~638 MiB) não está no default; ver docs/gguf-baremetal-midia.md
EOF

(
  cd "$OUT"
  sha256sum ia-livre-esp.tar.gz >SHA256SUMS
  [[ -f ia-livre-esp.img ]] && sha256sum ia-livre-esp.img >>SHA256SUMS
  sha256sum README-RELEASE.txt >>SHA256SUMS
)

echo "IA_LIVRE_RELEASE_DIR=${OUT}"
echo "IA_LIVRE_RELEASE_TAR=${OUT}/ia-livre-esp.tar.gz"
echo "IA_LIVRE_RELEASE_SHA256SUMS=${OUT}/SHA256SUMS"
echo "IA_LIVRE_RELEASE_ARTIFACT_OK"

cat <<'EOF'

Próximo passo (mantenedor — sem USB):
  git tag vX.Y.Z
  git push origin vX.Y.Z
  gh release create vX.Y.Z \
    build/release/ia-livre-esp.tar.gz \
    build/release/SHA256SUMS \
    build/release/README-RELEASE.txt \
    $(test -f build/release/ia-livre-esp.img && echo build/release/ia-livre-esp.img)

EOF
exit 0
