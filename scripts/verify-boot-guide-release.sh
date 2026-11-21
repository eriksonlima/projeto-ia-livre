#!/usr/bin/env bash
# Gate Etapa 57: guia USB + artefato de release com checksums. Sem USB / sem METAL_OK.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

test -f docs/guia-primeiro-boot-usb.md
test -f scripts/prepare-baremetal-release.sh
test -f docs/boot-hardware-real.md
chmod +x scripts/prepare-baremetal-release.sh

# Guia: seções mínimas + honestidade
grep -q 'Secure Boot' docs/guia-primeiro-boot-usb.md
grep -q '115200' docs/guia-primeiro-boot-usb.md
grep -q 'INCONCLUSIVO' docs/guia-primeiro-boot-usb.md
grep -q 'METAL_OK' docs/guia-primeiro-boot-usb.md
grep -q 'write-usb-esp' docs/guia-primeiro-boot-usb.md
# Não afirmar hipótese comprovada (aceita negações: "não comprovada", "INCONCLUSIVO")
if grep -qiE 'hip[oó]tese[[:space:]].{0,40}(foi |está |é )?comprovada' docs/guia-primeiro-boot-usb.md \
  && ! grep -qiE 'n[aã]o[[:space:]]+comprov|INCONCLUSIVO' docs/guia-primeiro-boot-usb.md; then
  echo "GATE_FAIL: guia não deve declarar hipótese comprovada"
  exit 1
fi
# Fraude explícita COMPROVA no guia
if grep -qE 'HARNESS_VERDICT=COMPROVA|veredito[[:space:]]+COMPROVA' docs/guia-primeiro-boot-usb.md; then
  echo "GATE_FAIL: guia não deve emitir COMPROVA"
  exit 1
fi

# Ponte
grep -q 'guia-primeiro-boot-usb' docs/boot-hardware-real.md \
  || grep -q 'Guia' docs/boot-hardware-real.md

# Prepare (pode reusar baremetal já buildado se SKIP_BUILD=1 após baremetal-esp)
export IA_LIVRE_RELEASE_SKIP_BUILD="${IA_LIVRE_RELEASE_SKIP_BUILD:-0}"
if [[ ! -f build/ia-livre-esp.tar.gz ]]; then
  IA_LIVRE_RELEASE_SKIP_BUILD=0
fi
# Se tar já existe, skip rebuild para acelerar gate
if [[ -f build/ia-livre-esp.tar.gz ]]; then
  export IA_LIVRE_RELEASE_SKIP_BUILD=1
fi

out="$(./scripts/prepare-baremetal-release.sh 2>&1)" || {
  echo "GATE_FAIL: prepare-baremetal-release exit ≠ 0"
  echo "$out"
  exit 1
}
echo "$out"

grep -q 'IA_LIVRE_RELEASE_ARTIFACT_OK' <<<"$out" \
  || { echo "GATE_FAIL: RELEASE_ARTIFACT_OK ausente"; exit 1; }

test -f build/release/ia-livre-esp.tar.gz
test -f build/release/SHA256SUMS
test -f build/release/README-RELEASE.txt

# Checksums consistentes
(
  cd build/release
  sha256sum -c SHA256SUMS
) || { echo "GATE_FAIL: SHA256SUMS inconsistente"; exit 1; }

# Anti-fraude
if grep -q 'IA_LIVRE_BAREMETAL_METAL_OK' <<<"$out"; then
  echo "GATE_FAIL: prepare não deve emitir METAL_OK"
  exit 1
fi

echo "IA_LIVRE_BOOT_GUIDE_OK"
echo "IA_LIVRE_RELEASE_ARTIFACT_OK"
echo "GATE_OK: boot-guide-release — guia + SHA256SUMS (Etapa 57; sem USB)"
exit 0
