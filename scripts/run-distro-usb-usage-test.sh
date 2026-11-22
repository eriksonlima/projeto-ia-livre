#!/usr/bin/env bash
# Teste de uso end-to-end da imagem live (USB/ISO) no QEMU — serial automatizado.
# Cobre: boot/login, docs, conf, catalog, model set (via 9p host), infer, agent, node, tune.
# ≠ COMPROVA. ≠ metal UEFI Linha B.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"

ISO="${IA_LIVRE_USB_TEST_ISO:-build/distro-debian/ia-livre-linux.iso}"
USB_DEV="${IA_LIVRE_USB_TEST_DEV:-/dev/sdc}"
MEM="${IA_LIVRE_USB_TEST_MEM:-4096}"
TIMEOUT_S="${IA_LIVRE_USB_TEST_TIMEOUT:-900}"
LOG="${IA_LIVRE_USB_TEST_LOG:-/tmp/ia-livre-usb-usage-test.log}"
REPORT="${IA_LIVRE_USB_TEST_REPORT:-/tmp/ia-livre-usb-usage-report.txt}"
GGUF_HOST="${IA_LIVRE_USB_TEST_GGUF:-models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf}"
MODELS_DIR_HOST="$(cd "$(dirname "$GGUF_HOST")" && pwd)"
GGUF_NAME="$(basename "$GGUF_HOST")"

if [[ ! -f "$ISO" ]]; then
  echo "erro: ISO ausente: $ISO" >&2
  exit 1
fi
if [[ ! -f "$GGUF_HOST" && ! -f "$MODELS_DIR_HOST/$GGUF_NAME" ]]; then
  echo "erro: GGUF host ausente ($GGUF_HOST) — rode ./scripts/fetch-model.sh" >&2
  exit 1
fi

find_ovmf() {
  local c
  for c in "${OVMF_CODE:-}" /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd; do
    [[ -n "$c" && -f "$c" ]] && { echo "$c"; return 0; }
  done
  return 1
}
OVMF="$(find_ovmf || true)"
if [[ -z "$OVMF" ]]; then
  echo "IA_LIVRE_USB_USAGE_SKIP=need_ovmf"
  exit 0
fi

# Conteúdo do pendrive = ISO (mesmos bytes). Boot QEMU via ISO (-cdrom/OVMF);
# abrir /dev/sdc no QEMU host exige root e é instável com UEFI.
BOOT_SRC=iso
BOOT_FILE="$ISO"
USB_VERIFIED=0
if [[ -b "$USB_DEV" ]] && command -v docker >/dev/null 2>&1; then
  if docker run --rm --privileged \
      -v "$(pwd)/$ISO:/iso:ro" \
      debian:bookworm bash -lc "
        iso=\$(dd if=/iso bs=1M count=4 status=none | sha256sum | awk '{print \$1}')
        usb=\$(dd if=$USB_DEV bs=1M count=4 status=none | sha256sum | awk '{print \$1}')
        echo iso4=\$iso
        echo usb4=\$usb
        [ \"\$iso\" = \"\$usb\" ]
      " >"/tmp/ia-usb-iso-match.txt" 2>&1; then
    USB_VERIFIED=1
  fi
fi
if [[ "$USB_VERIFIED" -eq 1 ]]; then
  echo "IA_LIVRE_USB_USAGE_USB_VERIFIED=1"
  echo "IA_LIVRE_USB_USAGE_BOOT=iso_equiv_usb:$USB_DEV"
else
  echo "IA_LIVRE_USB_USAGE_USB_VERIFIED=0"
  echo "IA_LIVRE_USB_USAGE_BOOT=iso (USB não verificado — ver /tmp/ia-usb-iso-match.txt)"
fi
# Remover ramo usb do driver Python (sempre ISO)
BOOT_SRC=iso

VARS_TMP="$(mktemp /tmp/ovmf-vars.XXXXXX.fd)"
cp -f /usr/share/OVMF/OVMF_VARS_4M.fd "$VARS_TMP" 2>/dev/null \
  || cp -f /usr/share/OVMF/OVMF_VARS.fd "$VARS_TMP"
cleanup() { rm -f "$VARS_TMP"; }
trap cleanup EXIT

rm -f "$LOG" "$REPORT"
echo "IA_LIVRE_USB_USAGE_START iso=$ISO boot=$BOOT_SRC mem=$MEM" | tee "$REPORT"

# Disco virtio com GGUF (9p é frágil no live)
GGUF_DISK="${IA_LIVRE_USB_TEST_GGUF_DISK:-/tmp/ia-gguf-disk.img}"
if [[ ! -f "$GGUF_DISK" ]]; then
  echo "erro: disco GGUF ausente ($GGUF_DISK) — gere com Docker/loop + tinyllama" >&2
  exit 1
fi

python3 scripts/lib/usb-usage-guest-driver.py \
  "$BOOT_FILE" "$BOOT_SRC" "$OVMF" "$VARS_TMP" \
  "$GGUF_DISK" "$GGUF_NAME" "$LOG" "$REPORT" "$MEM" "$TIMEOUT_S"
ec=$?
echo "IA_LIVRE_USB_USAGE_LOG=$LOG"
echo "IA_LIVRE_USB_USAGE_REPORT=$REPORT"
exit "$ec"
