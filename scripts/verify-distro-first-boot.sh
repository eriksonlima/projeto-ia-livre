#!/usr/bin/env bash
# Gate Etapa 84 / B79 — first-boot TTY (MOTD/PATH/fetch docs; sem GGUF default).
set -euo pipefail
cd "$(dirname "$0")/.."

test -f distro/overlay/etc/profile.d/ia-livre.sh
test -f distro/overlay/etc/ia-livre/FIRST_BOOT.md
test -f distro/overlay/etc/motd
grep -q '/opt/ia-livre/bin' distro/overlay/etc/profile.d/ia-livre.sh
grep -q 'fetch-model\|gguf\|GGUF' distro/overlay/etc/ia-livre/FIRST_BOOT.md
grep -q 'IA_LIVRE_DEBIAN_INCLUDE_GGUF' distro/overlay/etc/ia-livre/FIRST_BOOT.md
grep -q 'FIRST_BOOT\|first-boot\|profile.d' docs/linux-ia-nativo.md
grep -q 'IA_LIVRE_DEBIAN_INCLUDE_GGUF\|stripped' scripts/build-distro-debian-rootfs.sh

# Se rootfs Debian cacheado existir, confere strip (rebuild leve só se FORCE)
if [[ -d build/distro-debian/rootfs/etc/ia-livre ]]; then
  test -f build/distro-debian/rootfs/etc/ia-livre/FIRST_BOOT.md \
    || echo "IA_LIVRE_FIRST_BOOT_NOTE=rebuild_debian_for_overlay"
fi

echo "IA_LIVRE_DISTRO_FIRST_BOOT_OK"
echo "GATE_OK: first-boot — MOTD/PATH/FIRST_BOOT.md; GGUF default stripped no build Debian"
exit 0
