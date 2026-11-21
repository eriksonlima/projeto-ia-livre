#!/usr/bin/env bash
# Bridge host↔nativo (Etapa 49 / ADR 0018). Valida serial/log nativo; emite BRIDGE_*.
# Sem shell irrestrito; sem METAL_OK / TOKENS inventados.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

SRC=""
LOG=""
MODE="host_native"

usage() {
  cat <<'EOF'
Uso: ./scripts/run-autonomia-bridge.sh --src blockio|metal_block [--log FILE]

  --src metal_block   Roda verify-metal-infer (ou --log) e exige B_BLOCK_METAL
  --src blockio       Exige DECODE_OK/RUNTIME_NATIVE_OK no --log (fixture ou captura)
  --log FILE          Log serial a validar (obrigatório para blockio; opcional metal)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --src) SRC="${2:-}"; shift 2 ;;
    --log) LOG="${2:-}"; shift 2 ;;
    *) echo "erro: opção $1" >&2; exit 1 ;;
  esac
done

[[ -n "$SRC" ]] || { usage; exit 1; }

TMP=""
cleanup() { [[ -n "${TMP:-}" && -f "$TMP" ]] && rm -f "$TMP"; return 0; }
trap cleanup EXIT

case "$SRC" in
  metal_block)
    # E63: verify-metal-infer default=full (esp_sfs_full). Bridge E49 prova o
    # bloqueio legado — força MODE=legacy (≠ confundir com I/O full).
    if [[ -z "$LOG" ]]; then
      TMP="$(mktemp)"
      LOG="$TMP"
      set +e
      IA_LIVRE_METAL_INFER_MODE=legacy ./scripts/verify-metal-infer.sh >"$LOG" 2>&1
      metal_rc=$?
      set -e
      [[ "$metal_rc" -eq 0 ]] || {
        echo "erro: verify-metal-infer exit=$metal_rc" >&2
        cat "$LOG" >&2
        exit 1
      }
    fi
    grep -q 'IA_LIVRE_B_BLOCK_METAL=no_gguf_metal_io' "$LOG" \
      || { echo "erro: log sem B_BLOCK_METAL=no_gguf_metal_io" >&2; exit 1; }
    grep -q 'IA_LIVRE_GGUF_PATH=esp_sfs' "$LOG" \
      || grep -q 'IA_LIVRE_METAL_INFER_OK' "$LOG" \
      || { echo "erro: log metal incompleto" >&2; exit 1; }
    ;;
  blockio)
    [[ -n "$LOG" && -f "$LOG" ]] || {
      echo "erro: --src blockio exige --log FILE (ex. docs/evidence/bridge/serial-blockio-fixture.txt)" >&2
      exit 1
    }
    grep -q 'IA_LIVRE_RUNTIME_NATIVE_DECODE_OK' "$LOG" \
      || { echo "erro: log blockio sem DECODE_OK" >&2; exit 1; }
    grep -q 'IA_LIVRE_RUNTIME_NATIVE_OK' "$LOG" \
      || { echo "erro: log blockio sem RUNTIME_NATIVE_OK" >&2; exit 1; }
    # Não aceitar metal_block misturado como blockio
    if grep -q 'IA_LIVRE_B_BLOCK_METAL=' "$LOG"; then
      echo "erro: log parece metal_block, não blockio" >&2
      exit 1
    fi
    ;;
  *)
    echo "erro: --src deve ser blockio|metal_block" >&2
    exit 1
    ;;
esac

echo "IA_LIVRE_BRIDGE_MODE=${MODE}"
echo "IA_LIVRE_BRIDGE_NATIVE_SRC=${SRC}"
echo "IA_LIVRE_BRIDGE_OK"
exit 0
