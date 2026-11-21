# Progress

## O que funciona

- Etapas 1–81; produto = Linux IA-nativo (ADR 0027)
- Stack host + overlay distro (`ia-livre model/infer`, `ia-livre-native-tune`)
- Rootfs tar + smoke userspace (infer/agent); artefato USB Linux (tar+checksums)
- Writer `write-linux-usb.sh` com confirmação (gravação real = operador)
- Linha B UEFI = lab arquivado

## Bloqueios

- ISO Debian live completa ainda não
- QEMU Alpine no smoke: best-effort (`QEMU_SKIP=no_console` neste host); userspace cobre o gate
- Kernel Linux custom patches = depois

## Roadmap

- Sem `em_andamento` / `pendente`; Abertas vazio
