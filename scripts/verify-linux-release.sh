#!/usr/bin/env bash
# Gate Etapa 87 — release packaging Linux (sem device).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"
chmod +x scripts/prepare-linux-release.sh

# Reusa ISO já buildada quando possível
export IA_LIVRE_LINUX_RELEASE_SKIP_BUILD="${IA_LIVRE_LINUX_RELEASE_SKIP_BUILD:-0}"
# Se ISO existe, ainda precisa do tar — pack é rápido se stage cacheado
out="$(./scripts/prepare-linux-release.sh 2>&1)" || {
  echo "$out"
  echo "GATE_FAIL: prepare-linux-release"
  exit 1
}
echo "$out"
echo "$out" | grep -q 'IA_LIVRE_LINUX_RELEASE_ARTIFACT_OK'

test -d build/release-linux
test -f build/release-linux/SHA256SUMS
test -f build/release-linux/README-RELEASE.txt
test -f build/release-linux/ia-livre-distro-rootfs.tar.gz
grep -q 'GGUF\|fetch-model\|FIRST_BOOT\|sem GGUF\|não embute' build/release-linux/README-RELEASE.txt
grep -q 'prepare-linux-release\|release-linux\|verify-linux-release' docs/linux-ia-nativo.md \
  || grep -q 'release-linux\|prepare-linux-release' docs/guia-ia-livre-linux-usb.md

(
  cd build/release-linux
  sha256sum -c SHA256SUMS
)

# ISO opcional no CI sem docker/mtools — se presente, marca OK
if [[ -f build/release-linux/ia-livre-linux.iso ]]; then
  echo "IA_LIVRE_LINUX_RELEASE_ISO_GATE=present"
  # Tamanho tipicamente < 500MiB sem GGUF
  BYTES="$(wc -c <build/release-linux/ia-livre-linux.iso | tr -d ' ')"
  if [[ "${IA_LIVRE_DEBIAN_INCLUDE_GGUF:-0}" != "1" && "$BYTES" -gt 500000000 ]]; then
    echo "GATE_FAIL: ISO release parece incluir GGUF (bytes=$BYTES)"
    exit 1
  fi
  echo "IA_LIVRE_LINUX_RELEASE_ISO_BYTES=$BYTES"
else
  echo "IA_LIVRE_LINUX_RELEASE_ISO_GATE=absent_ok"
fi

echo "IA_LIVRE_LINUX_RELEASE_GATE_OK"
echo "GATE_OK: linux-release — SHA256SUMS + artefato sem GGUF na ISO (default)"
exit 0
