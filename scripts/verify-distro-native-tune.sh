#!/usr/bin/env bash
# Gate Etapa 79 / B74 — perfil nativo default.
set -euo pipefail
cd "$(dirname "$0")/.."

TUNE=distro/overlay/opt/ia-livre/bin/ia-livre-native-tune
test -f distro/overlay/etc/sysctl.d/99-ia-livre-native.conf
test -f "$TUNE"
chmod +x "$TUNE"

# No overlay: sysctl file exists but apply may SKIP without root
out="$("$TUNE" 2>&1)"
echo "$out" | grep -q 'IA_LIVRE_NATIVE_TUNE_OK'
echo "$out" | grep -q 'IA_LIVRE_NATIVE_GOVERNOR='
echo "$out" | grep -q 'IA_LIVRE_NATIVE_SYSCTL='
echo "$out" | grep -q 'IA_LIVRE_NATIVE_N_THREADS_HINT='

grep -q 'native-tune\|A_otimizada\|sysctl' docs/linux-ia-nativo.md

echo "IA_LIVRE_DISTRO_NATIVE_TUNE_OK"
echo "GATE_OK: native tune — script + sysctl conf (SKIP honesto sem root)"
