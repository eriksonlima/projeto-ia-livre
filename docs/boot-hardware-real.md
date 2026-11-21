# Boot / imagem em hardware real (Etapas 30 / 35)

ADR: [`0011-boot-imagem-esp-baremetal.md`](adr/0011-boot-imagem-esp-baremetal.md).  
Spec E35: [`../specs/boot-uefi-hardware-real/`](../specs/boot-uefi-hardware-real/).  
Evidências: [`evidence/boot-metal/`](evidence/boot-metal/).

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
- `IA_LIVRE/gguf.hdr` — opcional, só 4 KiB (default do gate)
- `IA_LIVRE/model.gguf` — **opt-in** (`IA_LIVRE_BAREMETAL_FULL_GGUF=1`); ver [gguf-baremetal-midia.md](gguf-baremetal-midia.md)

### GGUF na mídia (Etapa 36)

| Modo | Flag | Gate |
|------|------|------|
| Prefixo 4 KiB | default | `IMAGE_OK` |
| Modelo completo ~638 MiB | `IA_LIVRE_BAREMETAL_FULL_GGUF=1` | + `BAREMETAL_GGUF_OK` |
| USB externo / path doc | operador copia `model.gguf` | SimpleFileSystem documentado |

Contrato completo: [`gguf-baremetal-midia.md`](gguf-baremetal-midia.md).
## Gravar USB / ESP (manual)

1. Gerar artefato (`make baremetal-esp`).
2. Opção A — copiar a árvore para partição FAT ESP/USB (montar e `cp -a build/baremetal-esp/* /mnt/…`).
3. Opção B — se existir `.img` (com mtools): `dd if=build/ia-livre-esp.img of=/dev/sdX bs=4M status=progress` (**confirme o dispositivo**).
4. No firmware: boot USB/ESP; **Secure Boot off** ou modo setup (EFI não assinado).

## Checklist hardware real (Etapa 46)

| Passo | Ok? |
|-------|-----|
| Secure Boot desligado / setup | |
| Mídia aparece no Boot Menu | |
| Serial USB-UART no COM1 (ou adaptador) a 115200 8N1 | |
| Na serial: pelo menos `IA_LIVRE_BOOT_OK` (sucesso mínimo) | |
| Ideal: `EXIT_BOOT_OK` se o fluxo completo rodar | |
| Log **não** contém strings QEMU/OVMF/`SeaBIOS` | |

Sem serial: só confirmação visual de que o firmware carregou o EFI — **não** conta como gate CI.

### Caminhos Etapa 46 (ADR/spec)

| Caminho | Quando | Resultado |
|---------|--------|-----------|
| **A — evidência** | Operador anexa log em `docs/evidence/boot-metal/` | `SKIP=0` + `METAL_OK` |
| **B — bloqueio honesto** | Sem PC/log nesta máquina | `SKIP=1`; issue registra bloqueio; **proibido** fabricar log |

Agente **não** inventa evidência serial.

## Captura serial (Etapa 35)

| Item | Valor |
|------|--------|
| UART | COM1 (kernel pós-ExitBoot também reemite na COM1) |
| Params | **115200 8N1**, sem fluxo de hardware |
| Host | `picocom -b 115200 /dev/ttyUSB0` ou `minicom` / `screen` |
| Arquivo | redirecionar saída para log texto |

### Formato de evidência

Arquivo em `docs/evidence/boot-metal/<data>-host.txt` (ou path apontado por `IA_LIVRE_BAREMETAL_EVIDENCE`):

```text
# IA_LIVRE_BAREMETAL_EVIDENCE_V1
# HOST=<nome-do-pc>
# DATE_UTC=<ISO8601>
# EFI_SHA256=<sha256 de BOOTX64.EFI gravado>
# MEDIA=<usb|esp-interna|outro>
# NOTE=<opcional>
IA_LIVRE_BOOT_OK
…trecho serial…
```

**Proibido** no log de metal: strings de QEMU/OVMF fingindo hardware (`SeaBIOS`, `-bios OVMF`, `qemu-system`).

### Tabela de ambientes

| Ambiente | Prova | Gate |
|----------|-------|------|
| QEMU | Serial + marcadores | `make verify` |
| Artefato ESP/tar | Estrutura + MZ + checksum | `make verify-baremetal` (IMAGE_OK) |
| PC real | Log serial ≥ `BOOT_OK` | `IA_LIVRE_BAREMETAL_SKIP=0` + `IA_LIVRE_BAREMETAL_EVIDENCE=…` → `METAL_OK` |

### Limites honestos

- Path BlockIO/`gguf-canon` do QEMU **não** se aplica automaticamente ao PC; GGUF completo em metal é etapa futura.
- Observação canônica do gate metal: **serial**. Etapa 37 adiciona GOP/input **mínimos** sob Boot Services (prova também na serial) — ver [`observabilidade-minima-so.md`](observabilidade-minima-so.md); **não** substitui UART nem exige screenshot.
- Skip de metal (`BAREMETAL_SKIP`) ≠ sucesso em hardware.

## Relação com outros gates

| Gate | O que prova |
|------|-------------|
| `make verify` | Kernel em **QEMU** |
| `make verify-baremetal` | **Artefato** ESP/tar (+ metal se evidência) |
| `make verify-harness-comparable` | Hipótese A vs B (ainda INCONCLUSIVO) |
