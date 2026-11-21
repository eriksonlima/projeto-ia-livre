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

# --- GGUF completo na ESP (Etapa 36, opt-in) ---
FULL_GGUF="${IA_LIVRE_BAREMETAL_FULL_GGUF:-0}"
GGUF_FILE="$OUT_DIR/IA_LIVRE/model.gguf"
MIN_GGUF_BYTES=$((600 * 1024 * 1024))
if [[ "$FULL_GGUF" == "1" ]]; then
  if [[ ! -f "$GGUF_FILE" ]]; then
    echo "GATE_FAIL: FULL_GGUF=1 mas ausente $GGUF_FILE"
    exit 1
  fi
  GGUF_BYTES="$(wc -c <"$GGUF_FILE" | tr -d ' ')"
  if (( GGUF_BYTES < MIN_GGUF_BYTES )); then
    echo "GATE_FAIL: model.gguf pequeno demais ($GGUF_BYTES < $MIN_GGUF_BYTES)"
    exit 1
  fi
  magic="$(od -An -N4 -tx1 "$GGUF_FILE" | tr -d ' \n')"
  # GGUF little-endian ASCII: 47 47 55 46
  if [[ "$magic" != "47475546" ]]; then
    echo "GATE_FAIL: model.gguf sem magic GGUF"
    exit 1
  fi
  GGUF_SHA="$(sha256sum "$GGUF_FILE" | awk '{print $1}')"
  echo "IA_LIVRE_BAREMETAL_GGUF_SIZE=$GGUF_BYTES"
  echo "IA_LIVRE_BAREMETAL_GGUF_SHA256=$GGUF_SHA"
  echo "IA_LIVRE_BAREMETAL_GGUF_OK"
else
  echo "nota: GGUF completo não exigido (sem IA_LIVRE_BAREMETAL_FULL_GGUF=1) — docs/gguf-baremetal-midia.md"
fi

# --- Metal (Etapa 35) ---
if [[ "${IA_LIVRE_BAREMETAL_SKIP:-1}" == "1" ]]; then
  echo "IA_LIVRE_BAREMETAL_SKIP=1"
  echo "nota: hardware real não exercitado — ver docs/boot-hardware-real.md / docs/evidence/boot-metal/"
  echo "GATE_OK: baremetal — artefato ESP/tar validado (≠ QEMU; ≠ TOKENS_PER_S)"
  exit 0
fi

echo "IA_LIVRE_BAREMETAL_SKIP=0"
if [[ -z "$EVIDENCE" || ! -f "$EVIDENCE" ]]; then
  echo "GATE_FAIL: SKIP=0 exige IA_LIVRE_BAREMETAL_EVIDENCE apontando para report/log de metal"
  exit 1
fi

if ! grep -q 'IA_LIVRE_BOOT_OK' "$EVIDENCE"; then
  echo "GATE_FAIL: evidência sem IA_LIVRE_BOOT_OK"
  exit 1
fi

# Canal ESP (ADR 0025 / Etapa 73): report padrão exige OBS_OK + cabeçalho report/evidence
esp_report=0
if grep -q 'IA_LIVRE_BAREMETAL_REPORT_V1' "$EVIDENCE" \
  || grep -q 'MEDIA=usb_esp_file' "$EVIDENCE" \
  || grep -q 'IA_LIVRE_BAREMETAL_REPORT_OK' "$EVIDENCE"; then
  esp_report=1
fi
# Alias legado EVIDENCE_V1 com MEDIA usb_esp_file
if grep -q 'IA_LIVRE_BAREMETAL_EVIDENCE_V1' "$EVIDENCE" && grep -q 'MEDIA=usb_esp_file' "$EVIDENCE"; then
  esp_report=1
fi

if [[ "$esp_report" -eq 1 ]]; then
  grep -q 'IA_LIVRE_OBS_OK' "$EVIDENCE" \
    || { echo "GATE_FAIL: report ESP sem IA_LIVRE_OBS_OK"; exit 1; }
  grep -q 'IA_LIVRE_BAREMETAL_REPORT_OK' "$EVIDENCE" \
    || { echo "GATE_FAIL: report ESP sem IA_LIVRE_BAREMETAL_REPORT_OK"; exit 1; }
  echo "IA_LIVRE_BAREMETAL_EVIDENCE_SRC=esp_report"
else
  echo "IA_LIVRE_BAREMETAL_EVIDENCE_SRC=serial_or_legacy"
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
echo "GATE_OK: baremetal — artefato + evidência metal (report ESP ou serial ≥ BOOT_OK)"
exit 0
