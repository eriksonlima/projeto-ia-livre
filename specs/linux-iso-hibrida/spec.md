# Spec — ISO híbrida / live USB bootável (Etapa 85 / B80)

## Resultado

Artefato **ISO híbrida** (grub-mkrescue/xorriso) a partir do rootfs Debian E82, distinta do tarball E81; gate de artefato; QEMU `-cdrom` prova boot quando tools existem (ou skip `need_*` honesto).

## Pronto quando

- `build/distro-debian/ia-livre-linux.iso` (ou path documentado) + marcadores `DISTRO_ISO_OK`
- Boot QEMU CD-ROM até evidência guest (`GUEST_CONF` / Debian / live) **ou** skip `need_xorriso`/`need_squashfs`/`need_qemu`/`boot_fail`
- Docs em `linux-ia-nativo.md` / guia USB; ≠ ESP UEFI; sem GGUF default

## Fora de escopo

- Writer USB grava ISO (B81); release SHA256SUMS completo (B82)
- Desktop; COMPROVA/METAL
