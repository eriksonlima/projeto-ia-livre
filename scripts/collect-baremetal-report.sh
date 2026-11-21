#!/usr/bin/env bash
# Etapa 76 / B71 — coleta o baremetal-report de um mount IALIVRE (ou path).
# Não inventa METAL_OK / COMPROVA. Opcionalmente dispara verify-baremetal SKIP=0.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

usage() {
  cat <<'EOF'
Uso: ./scripts/collect-baremetal-report.sh [--mount DIR] [--out FILE] [--verify]

  --mount DIR   Diretório montado do pendrive (default: procura */IA_LIVRE ou /media/$USER/*/IA_LIVRE)
  --out FILE    Destino (default: docs/evidence/boot-metal/YYYY-MM-DD-<host>.txt)
  --verify      Roda IA_LIVRE_BAREMETAL_SKIP=0 make verify-baremetal com o arquivo coletado

EOF
}

MOUNT=""
OUT=""
DO_VERIFY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mount) MOUNT="${2:-}"; shift 2 ;;
    --out) OUT="${2:-}"; shift 2 ;;
    --verify) DO_VERIFY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "arg desconhecido: $1" >&2; usage; exit 1 ;;
  esac
done

find_mount() {
  local d
  for d in /media/"${USER:-}"/*/IA_LIVRE /run/media/"${USER:-}"/*/IA_LIVRE /mnt/*/IA_LIVRE; do
    if [[ -f "$d/baremetal-report.txt" ]]; then
      echo "$(dirname "$d")"
      return 0
    fi
  done
  # label IALIVRE comum
  for d in /media/"${USER:-}"/IALIVRE /run/media/"${USER:-}"/IALIVRE /mnt/IALIVRE; do
    if [[ -f "$d/IA_LIVRE/baremetal-report.txt" ]]; then
      echo "$d"
      return 0
    fi
  done
  return 1
}

if [[ -z "$MOUNT" ]]; then
  MOUNT="$(find_mount || true)"
fi
if [[ -z "$MOUNT" || ! -d "$MOUNT" ]]; then
  echo "erro: informe --mount DIR (pendrive montado) ou monte o volume IALIVRE" >&2
  exit 1
fi

SRC=""
if [[ -f "$MOUNT/IA_LIVRE/baremetal-report.txt" ]]; then
  SRC="$MOUNT/IA_LIVRE/baremetal-report.txt"
elif [[ -f "$MOUNT/baremetal-report.txt" ]]; then
  SRC="$MOUNT/baremetal-report.txt"
else
  echo "erro: não achei baremetal-report.txt sob $MOUNT" >&2
  exit 1
fi

HOST="$(hostname -s 2>/dev/null || echo host)"
DAY="$(date +%Y-%m-%d)"
OUT="${OUT:-docs/evidence/boot-metal/${DAY}-${HOST}.txt}"
mkdir -p "$(dirname "$OUT")"
cp -f "$SRC" "$OUT"
echo "IA_LIVRE_COLLECT_SRC=$SRC"
echo "IA_LIVRE_COLLECT_OUT=$OUT"
echo "IA_LIVRE_COLLECT_OK"

if (( DO_VERIFY )); then
  IA_LIVRE_BAREMETAL_SKIP=0 IA_LIVRE_BAREMETAL_EVIDENCE="$OUT" make verify-baremetal
fi
