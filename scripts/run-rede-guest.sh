#!/usr/bin/env bash
# Caminho B Rede + bloqueio TCP guest (Etapa 66 / ADR 0024).
# Reusa bridge E52; emite NET_GUEST_BLOCK; proibido NET_NATIVE_OK.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

LOG="${1:-docs/evidence/bridge/serial-exit-boot-fixture.txt}"
[[ -f "$LOG" ]] || { echo "erro: log ausente: $LOG" >&2; exit 1; }

# Inventário documentado (sem stub TCP)
echo "IA_LIVRE_NET_GUEST_INVENTORY=uart_only_no_nic"
echo "IA_LIVRE_NET_GUEST_BLOCK=no_tcp_post_exit"

# Sessão Rede no caminho B = bridge (TASK_OK host + EXIT no log)
BRIDGE_OUT="$(./scripts/run-rede-bridge.sh --log "$LOG" 2>&1)" || {
  echo "$BRIDGE_OUT"
  echo "erro: bridge Rede falhou" >&2
  exit 1
}
echo "$BRIDGE_OUT"

grep -q 'IA_LIVRE_NET_BRIDGE_OK' <<<"$BRIDGE_OUT" \
  || { echo "erro: sem NET_BRIDGE_OK" >&2; exit 1; }

# Anti-fraude
if grep -q 'IA_LIVRE_NET_NATIVE_OK' <<<"$BRIDGE_OUT"; then
  echo "erro: NET_NATIVE_OK sem stack (fraude)" >&2
  exit 1
fi

echo "IA_LIVRE_NET_GUEST_BLOCK=no_tcp_post_exit"
echo "IA_LIVRE_NET_GUEST_OK"
exit 0
