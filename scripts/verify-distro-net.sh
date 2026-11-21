#!/usr/bin/env bash
# Gate Etapa 89 — smoke Rede no SO
set -euo pipefail
cd "$(dirname "$0")/.."
chmod +x scripts/run-distro-net-smoke.sh
out="$(./scripts/run-distro-net-smoke.sh 2>&1)" || { echo "$out"; exit 1; }
echo "$out"
test -x distro/overlay/opt/ia-livre/bin/ia-livre-node || test -f distro/overlay/opt/ia-livre/bin/ia-livre
grep -q 'ia-livre-node\|Rede\|DISTRO_NET' docs/linux-ia-nativo.md
if echo "$out" | grep -q 'IA_LIVRE_DISTRO_NET_OK'; then
  echo "GATE_OK: distro-net — TASK/PEER OK (overlay)"
  exit 0
fi
if echo "$out" | grep -q 'IA_LIVRE_DISTRO_NET_SKIP='; then
  echo "GATE_OK: distro-net — SKIP honesto"
  exit 0
fi
echo "GATE_FAIL: sem NET_OK nem SKIP"
exit 1
