#!/usr/bin/env bash
# Etapa 85 / B80 — ISO híbrida live a partir do rootfs Debian (≠ tarball E81).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"
REPO="$(pwd)"
OUT="$REPO/build/distro-debian"
ROOTFS="$OUT/rootfs"
ISO_DIR="$OUT/iso-tree"
ISO="$OUT/ia-livre-linux.iso"

need() {
  echo "IA_LIVRE_DISTRO_ISO_SKIP=$1"
  exit 0
}

command -v mksquashfs >/dev/null 2>&1 || need need_squashfs
command -v grub-mkrescue >/dev/null 2>&1 || need need_grub
command -v xorriso >/dev/null 2>&1 || need need_xorriso
# grub-mkrescue hybrid FAT stage precisa de mformat (mtools)
command -v mformat >/dev/null 2>&1 || need need_mtools

chmod +x scripts/build-distro-debian-rootfs.sh
# Sempre rebuild leve se overlay first-boot mudou; cache rootfs ok se existir
if [[ "${IA_LIVRE_DEBIAN_REBUILD:-0}" == "1" || ! -d "$ROOTFS/opt/ia-livre/bin" ]]; then
  ./scripts/build-distro-debian-rootfs.sh
fi
if [[ ! -d "$ROOTFS" || ! -x "$ROOTFS/opt/ia-livre/bin/ia-livre" ]]; then
  ./scripts/build-distro-debian-rootfs.sh
fi
if [[ ! -d "$ROOTFS" ]]; then
  need need_rootfs
fi

have_docker() { command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; }

# Garantir live-boot no rootfs (para montar squashfs)
if [[ ! -f "$ROOTFS/usr/share/initramfs-tools/hooks/live" ]] \
  && [[ ! -d "$ROOTFS/usr/share/live" ]] \
  && [[ ! -f "$ROOTFS/bin/live-boot" ]] \
  && [[ ! -f "$ROOTFS/sbin/live-boot" ]] \
  && [[ ! -e "$ROOTFS/usr/lib/live/boot" ]]; then
  if have_docker; then
    echo "iso: instalando live-boot no rootfs via Docker…"
    docker run --rm --privileged \
      -v "$ROOTFS:/rootfs" \
      debian:bookworm bash -c '
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
mount --bind /proc /rootfs/proc || true
mount --bind /sys /rootfs/sys || true
mount --bind /dev /rootfs/dev || true
cp /etc/resolv.conf /rootfs/etc/resolv.conf 2>/dev/null || true
chroot /rootfs apt-get update -qq
chroot /rootfs apt-get install -y -qq live-boot live-tools live-boot-initramfs-tools || \
  chroot /rootfs apt-get install -y -qq live-boot live-tools
chroot /rootfs update-initramfs -u || chroot /rootfs /usr/sbin/update-initramfs -u
' || need need_live_boot
  else
    need need_live_boot
  fi
fi

K="$(ls -1 "$ROOTFS"/boot/vmlinuz-* 2>/dev/null | head -1 || true)"
I="$(ls -1 "$ROOTFS"/boot/initrd.img-* 2>/dev/null | head -1 || true)"
[[ -n "$K" && -n "$I" ]] || need need_kernel

rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR/live" "$ISO_DIR/boot/grub"
cp -f "$K" "$ISO_DIR/live/vmlinuz"
cp -f "$I" "$ISO_DIR/live/initrd.img"

# Artefato default sem GGUF (E84); força resquash se pesos ainda no rootfs/cache
if [[ "${IA_LIVRE_DEBIAN_INCLUDE_GGUF:-0}" != "1" ]]; then
  rm -f "$ROOTFS"/var/lib/ia-livre/models/*.gguf 2>/dev/null || true
fi

SQ="$ISO_DIR/live/filesystem.squashfs"
need_squash=1

# Cache inválido se /etc/shadow veio vazio (mksquashfs sem root não lê shadow 0640).
squash_shadow_ok() {
  local sq="$1" line sz
  command -v unsquashfs >/dev/null 2>&1 || return 1
  line="$(unsquashfs -ll "$sq" 2>/dev/null | grep -E '/etc/shadow$' | head -1 || true)"
  [[ -n "$line" ]] || return 1
  # unsquashfs -ll: perms owner/group size date time path
  sz="$(awk '{print $3}' <<<"$line")"
  [[ "$sz" =~ ^[0-9]+$ ]] && [[ "$sz" -gt 0 ]]
}

if [[ "${IA_LIVRE_ISO_RESQUASH:-0}" != "1" \
  && -f "$OUT/iso-tree-cache/filesystem.squashfs" \
  && "${IA_LIVRE_DEBIAN_INCLUDE_GGUF:-0}" != "1" ]]; then
  if command -v unsquashfs >/dev/null 2>&1 \
    && unsquashfs -ll "$OUT/iso-tree-cache/filesystem.squashfs" 2>/dev/null | grep -qi '\.gguf'; then
    echo "iso: cache squashfs tinha GGUF — regenerando…"
    need_squash=1
  elif ! squash_shadow_ok "$OUT/iso-tree-cache/filesystem.squashfs"; then
    echo "iso: cache squashfs com /etc/shadow vazio/ilegível — regenerando (precisa root/docker)…"
    need_squash=1
  else
    echo "iso: reusando squashfs em cache…"
    mkdir -p "$ISO_DIR/live"
    cp -f "$OUT/iso-tree-cache/filesystem.squashfs" "$SQ"
    need_squash=0
  fi
fi
if [[ "$need_squash" -eq 1 ]]; then
  echo "iso: mksquashfs (pode demorar)…"
  mkdir -p "$ISO_DIR/live"
  rm -f "$SQ"
  # Sem root, mksquashfs não lê etc/shadow (0640) → arquivo vazio na ISO → login falha.
  if [[ "$(id -u)" -eq 0 ]]; then
    mksquashfs "$ROOTFS" "$SQ" \
      -comp xz -no-progress -e boot/vmlinuz-\* -e boot/initrd.img-\* 2>/dev/null \
      || mksquashfs "$ROOTFS" "$SQ" -comp xz -no-progress
  elif have_docker; then
    echo "iso: mksquashfs via Docker (root) para preservar /etc/shadow…"
    docker run --rm --privileged \
      -v "$ROOTFS:/rootfs:ro" \
      -v "$ISO_DIR/live:/out" \
      debian:bookworm bash -c '
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq squashfs-tools >/dev/null
mksquashfs /rootfs /out/filesystem.squashfs \
  -comp xz -no-progress -e boot/vmlinuz-* -e boot/initrd.img-*
'
  else
    echo "erro: mksquashfs precisa de root ou Docker para incluir /etc/shadow (login live)" >&2
    echo "  sudo $0   ou instale/inicie Docker" >&2
    exit 1
  fi
  if ! squash_shadow_ok "$SQ"; then
    echo "erro: filesystem.squashfs sem /etc/shadow utilizável — abortando ISO" >&2
    exit 1
  fi
  mkdir -p "$OUT/iso-tree-cache"
  cp -f "$SQ" "$OUT/iso-tree-cache/filesystem.squashfs"
  echo "IA_LIVRE_DISTRO_ISO_SHADOW_OK"
fi
if [[ "${IA_LIVRE_DEBIAN_INCLUDE_GGUF:-0}" != "1" ]] && command -v unsquashfs >/dev/null 2>&1; then
  if unsquashfs -ll "$SQ" 2>/dev/null | grep -qi '\.gguf'; then
    echo "erro: ISO squashfs ainda contém .gguf (use strip + RESQUASH)" >&2
    exit 1
  fi
  echo "IA_LIVRE_DISTRO_ISO_GGUF=stripped"
fi
# Sempre emitir se shadow ok (cache hit também)
if squash_shadow_ok "$SQ"; then
  echo "IA_LIVRE_DISTRO_ISO_SHADOW_OK"
else
  echo "erro: ISO squashfs /etc/shadow inválido" >&2
  exit 1
fi

cat >"$ISO_DIR/boot/grub/grub.cfg" <<'EOF'
set timeout=5
set default=0
insmod all_video
terminal_input console
terminal_output console

menuentry "IA Livre Linux (live)" {
  linux /live/vmlinuz boot=live components console=ttyS0,115200n8 hostname=ialivre noeject
  initrd /live/initrd.img
}
menuentry "IA Livre Linux (live, debug)" {
  linux /live/vmlinuz boot=live components console=ttyS0,115200n8 hostname=ialivre noeject debug
  initrd /live/initrd.img
}
EOF

echo "iso: grub-mkrescue → $ISO"
rm -f "$ISO"
grub-mkrescue -o "$ISO" "$ISO_DIR" 2>"$OUT/grub-mkrescue.log" || {
  cat "$OUT/grub-mkrescue.log" >&2 || true
  need need_grub_mkrescue
}

BYTES="$(wc -c <"$ISO" | tr -d ' ')"
test -f "$ISO"
test "$BYTES" -gt 1000000

echo "IA_LIVRE_DISTRO_ISO=$ISO"
echo "IA_LIVRE_DISTRO_ISO_BYTES=$BYTES"
echo "IA_LIVRE_DISTRO_ISO_OK"
