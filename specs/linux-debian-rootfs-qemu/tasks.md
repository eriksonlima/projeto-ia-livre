# Tasks — Rootfs Debian mínimo bootável em QEMU (Etapa 82)

Uma task = uma fatia.

- [x] Task 1 — Script `build-distro-debian-rootfs`: mmdebstrap/debootstrap → rootfs Debian mínimo sob `build/distro-debian/`; inject `distro/overlay/` + `ia-livre` no PATH; marcador de artefato (`IA_LIVRE_DISTRO_DEBIAN_ROOTFS_OK` ou equivalente); skip `need_mmdebstrap`/`need_net` se faltar tool/rede
- [x] Task 2 — Runner `run-distro-debian-qemu`: QEMU `-nographic` + serial getty; boot da imagem Task 1 até prompt **ou** evidência de `ia-livre conf` no guest; emite `IA_LIVRE_DISTRO_DEBIAN_QEMU_OK` no sucesso (≠ Alpine); skip `need_qemu` se QEMU ausente
- [x] Task 3 — Gate `make verify-distro-debian-qemu` + docs (`docs/linux-ia-nativo.md`, ponte AGENTS se necessário); documentar skip `need_*` e contraste com smoke Alpine E80; README só se a capa ficar enganosa
