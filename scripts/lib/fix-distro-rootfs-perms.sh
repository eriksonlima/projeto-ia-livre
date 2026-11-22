#!/usr/bin/env bash
# Corrige ownership após cp do overlay (host uid 1000) — senão sudo/su quebram.
# Uso (no host ou no container com rootfs montado): fix-distro-rootfs-perms.sh <rootfs>
set -euo pipefail
R="${1:?rootfs}"
[[ -d "$R/etc" ]] || { echo "erro: sem $R/etc" >&2; exit 1; }

chown -R root:root "$R/etc"
chmod 755 "$R/etc"

if [[ -f "$R/etc/shadow" ]]; then
  chown root:shadow "$R/etc/shadow"
  chmod 640 "$R/etc/shadow"
fi
if [[ -f "$R/etc/gshadow" ]]; then
  chown root:shadow "$R/etc/gshadow"
  chmod 640 "$R/etc/gshadow"
fi
if [[ -f "$R/etc/sudoers" ]]; then
  chown root:root "$R/etc/sudoers"
  chmod 440 "$R/etc/sudoers"
fi
if [[ -d "$R/etc/sudoers.d" ]]; then
  chown -R root:root "$R/etc/sudoers.d"
  chmod 755 "$R/etc/sudoers.d"
  find "$R/etc/sudoers.d" -type f -exec chmod 440 {} \;
fi

echo ialivre >"$R/etc/hostname"
chown root:root "$R/etc/hostname"
chmod 644 "$R/etc/hostname"
if [[ -f "$R/etc/hosts" ]]; then
  chown root:root "$R/etc/hosts"
  chmod 644 "$R/etc/hosts"
fi

if [[ -d "$R/opt/ia-livre" ]]; then
  chown -R root:root "$R/opt/ia-livre"
  find "$R/opt/ia-livre/bin" -type f -exec chmod 755 {} \; 2>/dev/null || true
fi

if [[ -d "$R/home/ialivre" ]]; then
  chown -R 1000:1000 "$R/home/ialivre" 2>/dev/null || true
fi

mkdir -p "$R/etc/sudoers.d"
printf '%s\n' 'ialivre ALL=(ALL) NOPASSWD:ALL' >"$R/etc/sudoers.d/ia-livre-live"
chown root:root "$R/etc/sudoers.d/ia-livre-live"
chmod 440 "$R/etc/sudoers.d/ia-livre-live"

echo "IA_LIVRE_ROOTFS_PERMS_OK"
