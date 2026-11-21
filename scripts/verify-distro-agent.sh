#!/usr/bin/env bash
# Gate Etapa 90 — smoke autonomia no SO
set -euo pipefail
cd "$(dirname "$0")/.."
chmod +x scripts/run-distro-agent-smoke.sh
out="$(./scripts/run-distro-agent-smoke.sh 2>&1)" || { echo "$out"; exit 1; }
echo "$out"
grep -q 'agent\|autonomia\|DISTRO_AGENT' docs/linux-ia-nativo.md
if echo "$out" | grep -q 'IA_LIVRE_DISTRO_AGENT_OK'; then
  echo "GATE_OK: distro-agent — AGENT_OK (overlay)"
  exit 0
fi
if echo "$out" | grep -q 'IA_LIVRE_DISTRO_AGENT_SKIP='; then
  echo "GATE_OK: distro-agent — SKIP honesto"
  exit 0
fi
echo "GATE_FAIL"
exit 1
