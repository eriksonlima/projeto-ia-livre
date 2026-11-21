#!/usr/bin/env bash
# Gate Etapa 88 / B83 — units systemd opcionais (disabled by default).
set -euo pipefail
cd "$(dirname "$0")/.."

test -f distro/overlay/etc/systemd/system/ia-livre-node.service
test -f distro/overlay/etc/systemd/system/ia-livre-agent.service
test -f distro/overlay/etc/ia-livre/SYSTEMD.md
grep -q 'WantedBy=multi-user.target' distro/overlay/etc/systemd/system/ia-livre-node.service
grep -q 'enable\|disable' distro/overlay/etc/ia-livre/SYSTEMD.md
grep -q 'opcional\|disabled\|não' distro/overlay/etc/ia-livre/SYSTEMD.md
# Não devem estar pré-habilitadas no overlay
! test -e distro/overlay/etc/systemd/system/multi-user.target.wants/ia-livre-node.service
! test -e distro/overlay/etc/systemd/system/multi-user.target.wants/ia-livre-agent.service
grep -q 'systemd\|SYSTEMD' docs/linux-ia-nativo.md

echo "IA_LIVRE_DISTRO_SYSTEMD_OK"
echo "GATE_OK: systemd units opcionais (node/agent; default disabled)"
exit 0
