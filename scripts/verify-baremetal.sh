#!/usr/bin/env bash
# Gate do artefato ESP/USB (Etapa 30) — NÃO boot em hardware; NÃO = make verify (QEMU).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

OUT_DIR="${IA_LIVRE_BAREMETAL_ESP:-build/baremetal-esp}"
EFI="$OUT_DIR/EFI/BOOT/BOOTX64.EFI"
TAR_OUT="${IA_LIVRE_BAREMETAL_TAR:-build/ia-livre-esp.tar.gz}"

./scripts/make-baremetal-esp.sh

fail=0
if [[ ! -f "$EFI" ]]; then
  echo "GATE_FAIL: ausente $EFI"
  fail=1
fi
if [[ ! -f "$OUT_DIR/IA_LIVRE/README.txt" ]]; then
  echo "GATE_FAIL: ausente README na ESP baremetal"
  fail=1
fi
if [[ ! -f "$TAR_OUT" ]]; then
  echo "GATE_FAIL: ausente tar empacotado $TAR_OUT"
  fail=1
fi

# EFI PE/COFF: MZ stub
if [[ -f "$EFI" ]]; then
  magic="$(od -An -N2 -tx1 "$EFI" | tr -d ' \n')"
  if [[ "$magic" != "4d5a" ]]; then
    echo "GATE_FAIL: BOOTX64.EFI sem assinatura MZ (PE)"
    fail=1
  fi
  BYTES="$(wc -c <"$EFI" | tr -d ' ')"
  if (( BYTES < 1024 )); then
    echo "GATE_FAIL: EFI suspeitamente pequeno ($BYTES)"
    fail=1
  fi
  SHA="$(sha256sum "$EFI" | awk '{print $1}')"
  echo "IA_LIVRE_BAREMETAL_EFI_SHA256=$SHA"
  echo "IA_LIVRE_BAREMETAL_EFI_BYTES=$BYTES"
fi

# Proibido confundir com sucesso QEMU
if [[ "${IA_LIVRE_BAREMETAL_REQUIRE_QEMU:-0}" == "1" ]]; then
  echo "GATE_FAIL: este gate não deve exigir QEMU (fraude de ambiente)"
  fail=1
fi

if (( fail )); then
  exit 1
fi

echo "IA_LIVRE_BAREMETAL_ESP_DIR=$OUT_DIR"
echo "IA_LIVRE_BAREMETAL_TAR=$TAR_OUT"
echo "IA_LIVRE_BAREMETAL_IMAGE_OK"

# Trecho hardware (opcional) — skip honesto não dispensa IMAGE_OK acima
if [[ "${IA_LIVRE_BAREMETAL_SKIP:-1}" == "1" ]]; then
  echo "IA_LIVRE_BAREMETAL_SKIP=1"
  echo "nota: hardware real não exercitado neste gate — ver docs/boot-hardware-real.md"
else
  echo "IA_LIVRE_BAREMETAL_SKIP=0"
  echo "nota: operador deve completar checklist manual em hardware (serial COM1)."
fi

echo "GATE_OK: baremetal — artefato ESP/tar validado (≠ QEMU; ≠ TOKENS_PER_S)"
exit 0
