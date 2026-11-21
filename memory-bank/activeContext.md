# Active context

## Foco atual

- Etapas 1–82 **feitas**
- E82: Debian rootfs bootável em QEMU (`verify-distro-debian-qemu`)
- Abertas: B78–B91 (topo B78 smoke QEMU exige imagem)

## Próximo passo

- Promover **B78** no próximo ciclo / após este push

## Notas

- Build: mmdebstrap via Docker se host sem mmdebstrap
- Boot: 9p + initrd com módulos 9p; evidência `ia-livre conf` no guest
