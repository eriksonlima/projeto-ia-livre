# Boot / imagem em hardware real (Etapa 30)

ADR: [`0011-boot-imagem-esp-baremetal.md`](adr/0011-boot-imagem-esp-baremetal.md).

> **QEMU ≠ bare-metal.** Este documento não prova a hipótese A vs B e **não** emite `TOKENS_PER_S`.

## Artefato (prova CI)

| Peça | Caminho |
|------|---------|
| Árvore ESP | `build/baremetal-esp/` |
| `BOOTX64.EFI` | `build/baremetal-esp/EFI/BOOT/BOOTX64.EFI` |
| Tar | `build/ia-livre-esp.tar.gz` |
| FAT `.img` | `build/ia-livre-esp.img` **se** `mtools` instalado; senão skip |

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
make baremetal-esp          # ou: ./scripts/make-baremetal-esp.sh
make verify-baremetal       # gate do artefato → IA_LIVRE_BAREMETAL_IMAGE_OK
```

O gate valida estrutura + EFI (MZ) + tar + checksum. **Não** sobe QEMU e **não** exige PC físico.

`IA_LIVRE_BAREMETAL_SKIP=1` (default no gate): trecho “hardware exercitado” omitido. **Não** dispensa `IMAGE_OK`.

## Conteúdo da ESP

- `EFI/BOOT/BOOTX64.EFI` — kernel buildado
- `IA_LIVRE/README.txt` — limites
- `IA_LIVRE/gguf.hdr` — opcional, só 4 KiB; **modelo completo (~638 MiB) não vai na mídia do gate**

## Gravar USB / ESP (manual)

1. Gerar artefato (`make baremetal-esp`).
2. Opção A — copiar a árvore para partição FAT ESP/USB (montar e `cp -a build/baremetal-esp/* /mnt/…`).
3. Opção B — se existir `.img` (com mtools): `dd if=build/ia-livre-esp.img of=/dev/sdX bs=4M status=progress` (**confirme o dispositivo**).
4. No firmware: boot USB/ESP; **Secure Boot off** ou modo setup (EFI não assinado).

## Checklist hardware real

| Passo | Ok? |
|-------|-----|
| Secure Boot desligado / setup | |
| Mídia aparece no Boot Menu | |
| Serial USB-UART no COM1 (ou adaptador) a 115200 8N1 | |
| Na serial: pelo menos `IA_LIVRE_BOOT_OK` (sucesso mínimo) | |
| Ideal: `EXIT_BOOT_OK` se o fluxo completo rodar | |

Sem serial: só confirmação visual de que o firmware carregou o EFI — **não** conta como gate CI.

### Limites honestos

- Path BlockIO/`gguf-canon` do QEMU **não** se aplica automaticamente ao PC; GGUF completo em metal é etapa futura.
- Sem framebuffer/teclado no kernel — observação via serial.
- Skip de metal (`BAREMETAL_SKIP`) ≠ sucesso em hardware.

## Relação com outros gates

| Gate | O que prova |
|------|-------------|
| `make verify` | Kernel em **QEMU** |
| `make verify-baremetal` | **Artefato** ESP/tar |
| `make verify-harness-comparable` | Hipótese A vs B (ainda INCONCLUSIVO) |
