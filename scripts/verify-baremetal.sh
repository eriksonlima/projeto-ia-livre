#!/usr/bin/env bash
# Gate do artefato ESP/USB (Etapa 30) + evidência metal opcional (Etapa 35).
# NÃO = make verify (QEMU). Não inventa BOOT_OK de metal a partir de QEMU.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

OUT_DIR="${IA_LIVRE_BAREMETAL_ESP:-build/baremetal-esp}"
EFI="$OUT_DIR/EFI/BOOT/BOOTX64.EFI"
TAR_OUT="${IA_LIVRE_BAREMETAL_TAR:-build/ia-livre-esp.tar.gz}"
EVIDENCE="${IA_LIVRE_BAREMETAL_EVIDENCE:-}"

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

SHA=""
BYTES=""
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

# --- Metal (Etapa 35) ---
if [[ "${IA_LIVRE_BAREMETAL_SKIP:-1}" == "1" ]]; then
  echo "IA_LIVRE_BAREMETAL_SKIP=1"
  echo "nota: hardware real não exercitado — ver docs/boot-hardware-real.md / docs/evidence/boot-metal/"
  echo "GATE_OK: baremetal — artefato ESP/tar validado (≠ QEMU; ≠ TOKENS_PER_S)"
  exit 0
fi

echo "IA_LIVRE_BAREMETAL_SKIP=0"
if [[ -z "$EVIDENCE" || ! -f "$EVIDENCE" ]]; then
  echo "GATE_FAIL: SKIP=0 exige IA_LIVRE_BAREMETAL_EVIDENCE apontando para log de metal"
  exit 1
fi

if ! grep -q 'IA_LIVRE_BOOT_OK' "$EVIDENCE"; then
  echo "GATE_FAIL: evidência sem IA_LIVRE_BOOT_OK"
  exit 1
fi

# Rejeitar indicadores óbvios de QEMU/OVMF no log de metal
if grep -qiE 'qemu-system|SeaBIOS|OVMF_CODE|ovmf' "$EVIDENCE"; then
  echo "GATE_FAIL: evidência parece QEMU/OVMF — proibido fingir metal"
  exit 1
fi

# SHA opcional: se o cabeçalho declara EFI_SHA256=, deve bater com o artefato atual
hdr_sha="$(grep -E '^# EFI_SHA256=' "$EVIDENCE" | head -1 | cut -d= -f2 | tr -d ' \r' || true)"
if [[ -n "$hdr_sha" && -n "$SHA" && "$hdr_sha" != "$SHA" ]]; then
  echo "GATE_FAIL: EFI_SHA256 da evidência ($hdr_sha) ≠ artefato atual ($SHA)"
  exit 1
fi

echo "IA_LIVRE_BAREMETAL_EVIDENCE=$EVIDENCE"
echo "IA_LIVRE_BAREMETAL_METAL_OK"
echo "GATE_OK: baremetal — artefato + evidência metal (≥ BOOT_OK)"
exit 0
