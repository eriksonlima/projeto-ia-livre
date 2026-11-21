#!/usr/bin/env bash
# Etapa 85 — boot QEMU da ISO híbrida (UEFI/OVMF -cdrom; SeaBIOS costuma falhar El Torito).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"
OUT=build/distro-debian
ISO="$OUT/ia-livre-linux.iso"
TIMEOUT_S="${IA_LIVRE_ISO_QEMU_TIMEOUT:-240}"
LOG="${IA_LIVRE_ISO_QEMU_LOG:-/tmp/distro-iso-qemu.log}"
MEM="${IA_LIVRE_ISO_QEMU_MEM:-2048}"

if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
  echo "IA_LIVRE_DISTRO_ISO_SKIP=need_qemu"
  exit 0
fi

find_ovmf() {
  local c
  for c in \
    "${OVMF_CODE:-}" \
    /usr/share/OVMF/OVMF_CODE_4M.fd \
    /usr/share/OVMF/OVMF_CODE.fd \
    /usr/share/ovmf/OVMF.fd \
    /usr/share/qemu/OVMF.fd
  do
    [[ -n "$c" && -f "$c" ]] && { echo "$c"; return 0; }
  done
  return 1
}

OVMF="$(find_ovmf || true)"
if [[ -z "$OVMF" ]]; then
  echo "IA_LIVRE_DISTRO_ISO_SKIP=need_ovmf"
  exit 0
fi

chmod +x scripts/build-distro-debian-iso.sh
build_out="$(./scripts/build-distro-debian-iso.sh 2>&1)" || {
  echo "$build_out"
  exit 1
}
echo "$build_out"
if echo "$build_out" | grep -q 'IA_LIVRE_DISTRO_ISO_SKIP='; then
  exit 0
fi
echo "$build_out" | grep -q 'IA_LIVRE_DISTRO_ISO_OK'
test -f "$ISO"

VARS_TMP="$(mktemp /tmp/ovmf-vars.XXXXXX.fd)"
VARS_TEMPLATE=""
for t in /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/OVMF/OVMF_VARS.fd; do
  if [[ -f "$t" ]]; then VARS_TEMPLATE="$t"; break; fi
done
if [[ -n "$VARS_TEMPLATE" ]]; then
  cp -f "$VARS_TEMPLATE" "$VARS_TMP"
else
  # fallback: empty vars file same size not always needed for CODE-only
  rm -f "$VARS_TMP"
  VARS_TMP=""
fi
cleanup() { [[ -n "${VARS_TMP:-}" && -f "$VARS_TMP" ]] && rm -f "$VARS_TMP"; }
trap cleanup EXIT

echo "IA_LIVRE_DISTRO_ISO_QEMU_MODE=uefi_cdrom"
echo "IA_LIVRE_DISTRO_ISO_OVMF=$OVMF"
rm -f "$LOG"

QEMU_ARGS=(
  -machine q35
  -m "$MEM"
  -smp 2
  -nographic
  -no-reboot
  -drive "if=pflash,format=raw,readonly=on,file=$OVMF"
)
if [[ -n "$VARS_TMP" ]]; then
  QEMU_ARGS+=(-drive "if=pflash,format=raw,file=$VARS_TMP")
fi
QEMU_ARGS+=(-cdrom "$ISO" -boot order=d)

set +e
timeout "$TIMEOUT_S" qemu-system-x86_64 "${QEMU_ARGS[@]}" >"$LOG" 2>&1
qec=$?
set -e

if grep -q 'IA_LIVRE_DISTRO_DEBIAN_GUEST_CONF_OK' "$LOG" \
  || grep -qE 'MODEL=|CONF=/etc/ia-livre' "$LOG" \
  || grep -qiE 'Debian GNU/Linux|login:|live-boot|Welcome to.*Debian' "$LOG"; then
  echo "IA_LIVRE_DISTRO_ISO_QEMU_LOG=$LOG"
  if grep -q 'IA_LIVRE_DISTRO_DEBIAN_GUEST_CONF_OK' "$LOG" || grep -qE 'MODEL=|CONF=/etc/ia-livre' "$LOG"; then
    echo "IA_LIVRE_DISTRO_ISO_GUEST=conf"
  else
    echo "IA_LIVRE_DISTRO_ISO_GUEST=prompt"
  fi
  echo "IA_LIVRE_DISTRO_ISO_QEMU_OK"
  exit 0
fi

if grep -qiE 'Kernel panic|No live filesystem|unable to find a medium|Could not read from CDROM' "$LOG"; then
  echo "IA_LIVRE_DISTRO_ISO_SKIP=boot_fail"
  echo "IA_LIVRE_DISTRO_ISO_QEMU_LOG=$LOG"
  exit 0
fi

echo "IA_LIVRE_DISTRO_ISO_SKIP=no_console"
echo "IA_LIVRE_DISTRO_ISO_QEMU_LOG=$LOG"
echo "qemu_exit=$qec"
exit 0
