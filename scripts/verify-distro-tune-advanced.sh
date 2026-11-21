#!/usr/bin/env bash
# Gate Etapa 92 / B87 — tuning avançado (isolcpus/cgroups/hugepages docs + script).
set -euo pipefail
cd "$(dirname "$0")/.."

TUNE=distro/overlay/opt/ia-livre/bin/ia-livre-native-tune
test -f "$TUNE"
chmod +x "$TUNE"
grep -q 'isolcpus\|cgroup\|hugepage\|HUGE\|ISOL' "$TUNE" \
  || grep -q 'isolcpus\|cgroup\|hugepage' docs/linux-ia-nativo.md
test -f docs/linux-ia-nativo-tuning.md
grep -q 'isolcpus\|hugepage\|cgroup' docs/linux-ia-nativo-tuning.md

out="$("$TUNE" 2>&1)"
echo "$out"
echo "$out" | grep -q 'IA_LIVRE_NATIVE_TUNE_OK'
echo "$out" | grep -qE 'IA_LIVRE_NATIVE_HUGEPAGES=|IA_LIVRE_NATIVE_ISOLCPUS_HINT=|IA_LIVRE_NATIVE_CGROUP='

echo "IA_LIVRE_DISTRO_TUNE_ADV_OK"
echo "GATE_OK: tuning avançado — hints + docs"
exit 0
