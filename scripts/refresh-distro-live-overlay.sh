#!/usr/bin/env bash
# Atualiza rootfs Debian já buildado com overlay atual + deps live (libgomp, symlinks).
# Não refaz mmdebstrap. Depois: IA_LIVRE_ISO_RESQUASH=1 ./scripts/build-distro-debian-iso.sh
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"

ROOTFS=build/distro-debian/rootfs
[[ -d "$ROOTFS/opt/ia-livre" ]] || {
  echo "erro: rootfs ausente — ./scripts/build-distro-debian-rootfs.sh" >&2
  exit 1
}

if [[ "${IA_LIVRE_REFRESH_SKIP_STAGE:-0}" != "1" ]]; then
  ./scripts/stage-distro-overlay.sh
else
  echo "refresh: pulando stage (IA_LIVRE_REFRESH_SKIP_STAGE=1)"
fi

OVERLAY="$(cd distro/overlay && pwd)"
docker run --rm --privileged \
  -v "$(pwd)/$ROOTFS:/rootfs" \
  -v "$OVERLAY:/overlay:ro" \
  debian:bookworm bash -c '
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
mount --bind /proc /rootfs/proc || true
mount --bind /sys /rootfs/sys || true
mount --bind /dev /rootfs/dev || true
cp /etc/resolv.conf /rootfs/etc/resolv.conf 2>/dev/null || true

# overlay (scripts + bins + catalog + docs)
cp -a /overlay/. /rootfs/

chroot /rootfs apt-get update -qq
chroot /rootfs apt-get install -y -qq libgomp1 curl ca-certificates >/dev/null

mkdir -p /rootfs/usr/local/bin
ln -sfn /opt/ia-livre/bin/ia-livre /rootfs/usr/local/bin/ia-livre
ln -sfn /opt/ia-livre/bin/ia-livre-native-tune /rootfs/usr/local/bin/ia-livre-native-tune
ln -sfn /opt/ia-livre/bin/ia-livre-runtime /rootfs/usr/local/bin/ia-livre-runtime
ln -sfn /opt/ia-livre/bin/ia-livre-agent /rootfs/usr/local/bin/ia-livre-agent
ln -sfn /opt/ia-livre/bin/ia-livre-node /rootfs/usr/local/bin/ia-livre-node

# fixture read_local (cwd=home do usuário live)
mkdir -p /rootfs/home/ialivre/agent/fixtures
if [[ -f /overlay/home/ialivre/agent/fixtures/read-local-smoke.txt ]]; then
  cp -f /overlay/home/ialivre/agent/fixtures/read-local-smoke.txt \
    /rootfs/home/ialivre/agent/fixtures/
else
  echo 'prova-read-local-ia-livre' >/rootfs/home/ialivre/agent/fixtures/read-local-smoke.txt
fi
chown -R 1000:1000 /rootfs/home/ialivre/agent 2>/dev/null || true

# strip GGUF default
rm -f /rootfs/var/lib/ia-livre/models/*.gguf 2>/dev/null || true

test -x /rootfs/opt/ia-livre/bin/ia-livre
test -f /rootfs/etc/ia-livre/models-catalog.tsv
test -f /rootfs/usr/lib/x86_64-linux-gnu/libgomp.so.1 \
  || test -f /rootfs/lib/x86_64-linux-gnu/libgomp.so.1
# glibc check: agent must not need 2.39
if command -v objdump >/dev/null; then
  objdump -T /rootfs/opt/ia-livre/bin/ia-livre-agent 2>/dev/null | grep -q GLIBC_2.39 \
    && { echo "erro: ia-livre-agent ainda exige GLIBC_2.39 — rode stage via bookworm"; exit 1; } || true
fi
echo IA_LIVRE_LIVE_OVERLAY_REFRESH_OK
'

# Invalida squash cache
rm -f build/distro-debian/iso-tree-cache/filesystem.squashfs
rm -f build/distro-debian/iso-tree/live/filesystem.squashfs

echo "IA_LIVRE_LIVE_OVERLAY_REFRESH_OK"
echo "Próximo: IA_LIVRE_ISO_RESQUASH=1 ./scripts/build-distro-debian-iso.sh"
