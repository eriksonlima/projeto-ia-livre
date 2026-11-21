#!/usr/bin/env bash
# One-shot seguro: gravar ESP/imagem bare-metal em pendrive UEFI (Etapa 47).
# NUNCA grava sem confirmação explícita do path do device.
# QEMU ≠ metal; NÃO emite METAL_OK / TOKENS_PER_S.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

IMG="${IA_LIVRE_BAREMETAL_IMG:-build/ia-livre-esp.img}"
ESP_DIR="${IA_LIVRE_BAREMETAL_ESP:-build/baremetal-esp}"
MODE="write" # write | dry-run | list | help
DEVICE=""
CONFIRM=""
YES_FLAG=0

usage() {
  cat <<'EOF'
Uso: ./scripts/write-usb-esp.sh [opções]

Grava a imagem/ESP bare-metal num dispositivo USB/removível com confirmação
explícita. Sem confirmação → exit ≠ 0 e nenhuma escrita.

Opções:
  -h, --help          Esta ajuda
  -l, --list          Só lista candidatos (lsblk) e sai 0
  -n, --dry-run       Simula: valida artefato + confirmação; não escreve
  -d, --device PATH   Device alvo (ex. /dev/sdb) — ainda exige confirmação
  -y, --yes           Aceita confirmação via --confirm (ainda obrigatório)
  --confirm PATH      Deve ser idêntico ao --device (digitar o path)

Fluxo típico:
  make baremetal-esp
  ./scripts/write-usb-esp.sh --list
  ./scripts/write-usb-esp.sh --device /dev/sdX --confirm /dev/sdX

Fonte: preferir build/ia-livre-esp.img; se ausente, tenta make baremetal-esp
ou fallback cp árvore → partição FAT montada (documentado).

AVISO: checks anti-sistema são honestos, não absolutos. Confirme o device.
EOF
}

die() { echo "erro: $*" >&2; exit 1; }

list_candidates() {
  echo "Candidatos removíveis/USB (lsblk):"
  if command -v lsblk >/dev/null 2>&1; then
    lsblk -d -o NAME,SIZE,TYPE,TRAN,RM,MODEL,SERIAL 2>/dev/null | head -1 || true
    # Prefer USB (TRAN=usb) ou RM=1
    lsblk -dn -o NAME,SIZE,TYPE,TRAN,RM,MODEL 2>/dev/null | while read -r name size typ tran rm model; do
      [[ "$typ" == "disk" ]] || continue
      if [[ "${tran:-}" == "usb" || "${rm:-0}" == "1" ]]; then
        echo "  /dev/${name}  size=${size}  tran=${tran:-?}  rm=${rm}  model=${model:-}"
      fi
    done
    echo "(Todos os discos — revise com cuidado:)"
    lsblk -d -o NAME,SIZE,TYPE,TRAN,RM,MOUNTPOINT,MODEL 2>/dev/null || true
  else
    echo "  (lsblk ausente — liste manualmente /dev/sd* /dev/nvme*)"
  fi
}

# True se device (ou partições) monta raiz/boot/home óbvios.
is_systemish() {
  local dev="$1"
  local base mounts mp
  base="$(basename "$dev")"
  mounts="$(lsblk -nr -o NAME,MOUNTPOINT 2>/dev/null || true)"
  while read -r name mp; do
    [[ -z "${mp:-}" ]] && continue
    case "$name" in
      "$base"|"${base}"p[0-9]*|"${base}"[0-9]*)
        case "$mp" in
          /|/boot|/boot/*|/home|/home/*|/usr|/var|/|/efi|/efi/*)
            return 0
            ;;
        esac
        ;;
    esac
  done <<<"$mounts"
  # Device contém partição com mountpoint do root atual
  if findmnt -n -o SOURCE / 2>/dev/null | grep -q "$base"; then
    return 0
  fi
  if findmnt -n -o SOURCE /boot 2>/dev/null | grep -q "$base"; then
    return 0
  fi
  return 1
}

ensure_img() {
  if [[ -f "$IMG" ]]; then
    return 0
  fi
  echo "nota: $IMG ausente — tentando make baremetal-esp …" >&2
  make baremetal-esp >&2 || true
  if [[ -f "$IMG" ]]; then
    return 0
  fi
  if [[ -d "$ESP_DIR/EFI/BOOT" ]]; then
    echo "nota: sem .img (mtools?). Fallback: copiar árvore ESP para partição FAT montada." >&2
    return 2
  fi
  die "sem artefato: rode make baremetal-esp (e instale mtools para .img)"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) MODE=help; shift ;;
    -l|--list) MODE=list; shift ;;
    -n|--dry-run) MODE=dry-run; shift ;;
    -d|--device) DEVICE="${2:-}"; shift 2 ;;
    -y|--yes) YES_FLAG=1; shift ;;
    --confirm) CONFIRM="${2:-}"; shift 2 ;;
    *) die "opção desconhecida: $1 (use --help)" ;;
  esac
done

if [[ "$MODE" == "help" ]]; then
  usage
  exit 0
fi

if [[ "$MODE" == "list" ]]; then
  list_candidates
  echo "IA_LIVRE_WRITE_USB_LIST_OK"
  exit 0
fi

# write ou dry-run exigem device + confirm
if [[ -z "$DEVICE" ]]; then
  list_candidates
  die "informe --device /dev/… e --confirm com o mesmo path (ou use --list / --dry-run com ambos)"
fi

if [[ ! -b "$DEVICE" && "$MODE" != "dry-run" ]]; then
  # Em dry-run aceitamos path sintático para o gate CI sem device real
  if [[ "$MODE" == "dry-run" && "$DEVICE" == /dev/* ]]; then
    :
  elif [[ ! -b "$DEVICE" ]]; then
    die "device não é bloco: $DEVICE"
  fi
fi

if [[ -z "$CONFIRM" ]]; then
  die "confirmação obrigatória: --confirm deve repetir o path do device ($DEVICE)"
fi

if [[ "$CONFIRM" != "$DEVICE" ]]; then
  die "confirmação divergente: --confirm='$CONFIRM' ≠ --device='$DEVICE'"
fi

if [[ "$YES_FLAG" -eq 0 && "$MODE" != "dry-run" ]]; then
  # Para escrita real, exigir também -y após digitar o path (dupla trava)
  die "para gravar de verdade use também -y/--yes (após --confirm idêntico ao device)"
fi

if [[ -b "$DEVICE" ]] && is_systemish "$DEVICE"; then
  die "recusado: $DEVICE parece montar sistema (/ /boot /home) — escolha outro device"
fi

# Artefato
rc_img=0
ensure_img || rc_img=$?

if [[ "$MODE" == "dry-run" ]]; then
  echo "dry-run: device=$DEVICE confirm=$CONFIRM"
  if [[ -f "$IMG" ]]; then
    echo "dry-run: gravaria dd if=$IMG of=$DEVICE bs=4M"
  else
    echo "dry-run: sem .img — fallback cp $ESP_DIR/* → partição FAT montada (manual mount)"
  fi
  echo "IA_LIVRE_WRITE_USB_OK"
  echo "nota: gravação ≠ METAL_OK — ver docs/boot-hardware-real.md / E46"
  exit 0
fi

# Escrita real
if [[ -f "$IMG" ]]; then
  echo "gravando $IMG → $DEVICE …" >&2
  dd if="$IMG" of="$DEVICE" bs=4M status=progress conv=fsync
  sync
  echo "IA_LIVRE_WRITE_USB_OK"
  echo "nota: remova com segurança; Secure Boot off; serial 115200 — ≠ METAL_OK automático"
  exit 0
fi

# Fallback: precisa de mount point
MNT="${IA_LIVRE_USB_MOUNT:-}"
[[ -n "$MNT" && -d "$MNT" ]] || die "sem .img: monte a partição FAT e exporte IA_LIVRE_USB_MOUNT=/mnt/… ou instale mtools e rode make baremetal-esp"
echo "copiando árvore $ESP_DIR → $MNT …" >&2
cp -a "$ESP_DIR"/. "$MNT"/
sync
echo "IA_LIVRE_WRITE_USB_OK"
echo "nota: fallback cp árvore FAT; ≠ METAL_OK"
exit 0
