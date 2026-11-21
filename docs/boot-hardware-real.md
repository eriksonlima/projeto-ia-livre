# Boot / imagem em hardware real (Etapas 30 / 35 / 57)

ADR: [`0011-boot-imagem-esp-baremetal.md`](adr/0011-boot-imagem-esp-baremetal.md).  
Spec E35: [`../specs/boot-uefi-hardware-real/`](../specs/boot-uefi-hardware-real/).  
Evidências: [`evidence/boot-metal/`](evidence/boot-metal/).  
**Guia onboarding (Etapa 57):** [`guia-primeiro-boot-usb.md`](guia-primeiro-boot-usb.md) · prepare release: `./scripts/prepare-baremetal-release.sh` · gate: `make verify-boot-guide-release`.

> **QEMU ≠ bare-metal.** Este documento não prova a hipótese A vs B e **não** emite `TOKENS_PER_S`.  
> **Canal padrão de evidência (Etapa 73):** relatório na ESP — [`baremetal-report.md`](baremetal-report.md) / ADR [`0025`](adr/0025-baremetal-report-esp.md). UART COM1 é opcional.

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
## Gravar USB / ESP (Etapa 47 — one-shot)

**Preferido:** script com confirmação explícita (nunca grava sem digitar o path):

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
make baremetal-esp
./scripts/write-usb-esp.sh --list
# Revise o device com cuidado (checks anti-sistema são honestos, não absolutos):
./scripts/write-usb-esp.sh --device /dev/sdX --confirm /dev/sdX --yes
# Simulação sem escrita:
./scripts/write-usb-esp.sh --dry-run --device /dev/sdX --confirm /dev/sdX
```

- Prefere `build/ia-livre-esp.img` (`dd`); sem `.img` (sem mtools): monte a FAT e `IA_LIVRE_USB_MOUNT=/mnt/…` para `cp` da árvore.
- Gate CI (sem USB): `make verify-write-usb` → `IA_LIVRE_WRITE_USB_OK`.
- **Gravação ≠** `METAL_OK` (E46). No firmware: boot USB; **Secure Boot off** ou setup.

### Manual (legado)

Se preferir à mão: montar FAT e `cp -a build/baremetal-esp/* /mnt/…`, ou `dd if=build/ia-livre-esp.img of=/dev/sdX bs=4M status=progress` **só** após confirmar o dispositivo.

## Checklist hardware real (Etapa 46 / 73)

| Passo | Ok? |
|-------|-----|
| Secure Boot desligado / setup | |
| Mídia aparece no Boot Menu | |
| Boot até GOP / `EXIT_BOOT_BEGIN` | |
| **Padrão:** remount Linux + `IA_LIVRE/baremetal-report.txt` com `BOOT_OK` + `OBS_OK` + `REPORT_OK` | |
| Opcional: serial COM1 115200 8N1 | |
| Evidência **não** contém strings QEMU/OVMF/`SeaBIOS` | |

Só “pareceu bootar” sem report/serial → **não** conta como gate CI.

### Caminhos de evidência

| Caminho | Quando | Resultado |
|---------|--------|-----------|
| **A — report ESP (padrão)** | Operador copia `baremetal-report.txt` → `docs/evidence/boot-metal/` | `SKIP=0` + `METAL_OK` |
| **A' — serial (legado)** | Lab com UART | Idem |
| **B — bloqueio honesto** | Sem PC/report nesta máquina | `SKIP=1`; **proibido** fabricar evidência |

Agente **não** inventa evidência metal.

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
| PC real | Report ESP (padrão) ou serial ≥ `BOOT_OK` (+ `OBS_OK` no path ESP) | `IA_LIVRE_BAREMETAL_SKIP=0` + `IA_LIVRE_BAREMETAL_EVIDENCE=…` → `METAL_OK` |

### Limites honestos

- Path BlockIO/`gguf-canon` do QEMU **não** se aplica automaticamente ao PC; GGUF completo em metal é etapa futura.
- Observação canônica do gate metal: **report ESP** (ADR 0025); serial secundário. GOP na tela é bônus — ver [`observabilidade-minima-so.md`](observabilidade-minima-so.md); vídeo/foto ≠ gate.
- Skip de metal (`BAREMETAL_SKIP`) ≠ sucesso em hardware.

## Relação com outros gates

| Gate | O que prova |
|------|-------------|
| `make verify` | Kernel em **QEMU** |
| `make verify-baremetal` | **Artefato** ESP/tar (+ metal se evidência) |
| `make verify-harness-comparable` | Hipótese A vs B (ainda INCONCLUSIVO) |
