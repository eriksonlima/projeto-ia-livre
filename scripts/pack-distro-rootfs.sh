#!/usr/bin/env bash
# Empacota overlay staged em build/ia-livre-distro-rootfs.tar.gz
set -euo pipefail
cd "$(dirname "$0")/.."

./scripts/stage-distro-overlay.sh

OUT_DIR=build
TAR="$OUT_DIR/ia-livre-distro-rootfs.tar.gz"
mkdir -p "$OUT_DIR"

tar -C distro/overlay -czf "$TAR" .
BYTES="$(wc -c <"$TAR" | tr -d ' ')"
echo "IA_LIVRE_DISTRO_ROOTFS=$TAR"
echo "IA_LIVRE_DISTRO_ROOTFS_BYTES=$BYTES"
echo "IA_LIVRE_DISTRO_ROOTFS_OK"
