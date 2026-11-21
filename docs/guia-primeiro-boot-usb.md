# Guia — primeiro boot USB (IA Livre)

Onboarding para contribuidores: gravar a ESP num pendrive UEFI e ver o kernel na serial.  
Etapa 57 · contrato técnico: [`boot-hardware-real.md`](boot-hardware-real.md) · writer: `scripts/write-usb-esp.sh`.

> **Honestidade:** QEMU ≠ metal. Gravação USB ≠ `METAL_OK`. Hipótese A vs B permanece **INCONCLUSIVO** (espécie subset na Linha B). Este guia **não** prova a hipótese de pesquisa.

## Ambientes (não confundir)

| Ambiente | O que prova | Gate típico |
|----------|-------------|-------------|
| QEMU + OVMF | Boot/serial no emulador | `make verify` |
| Artefato ESP/tar | Imagem empacotável | `make verify-baremetal` |
| Pendrive gravado | Mídia pronta | `write-usb-esp.sh` (≠ metal) |
| PC físico + report ESP | Boot real (sem COM1) | evidência → `METAL_OK` (opt-in) |

## Pré-requisitos

- PC x86-64 com firmware UEFI
- Pendrive (será **apagado**)
- Host Linux com Rust (para buildar/gravar); `gh` opcional para Release
- **Serial COM1:** opcional (lab); evidência padrão = report na ESP (Etapa 73)

## 1. Obter o artefato

### Opção A — release GitHub

1. Abra [Releases](https://github.com/eriksonlima/projeto-ia-livre/releases).
2. Baixe `ia-livre-esp.tar.gz` e `SHA256SUMS` (e `.img` se existir).
3. Verifique: `sha256sum -c SHA256SUMS`.

### Opção B — build local

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
git clone https://github.com/eriksonlima/projeto-ia-livre.git
cd projeto-ia-livre
make baremetal-esp
# ou prepare de release (tar + checksums):
./scripts/prepare-baremetal-release.sh
```

Default **não** inclui o GGUF completo (~638 MiB). Opt-in: `IA_LIVRE_BAREMETAL_FULL_GGUF=1` (ver [`gguf-baremetal-midia.md`](gguf-baremetal-midia.md)).

## 2. Gravar o pendrive

```bash
./scripts/write-usb-esp.sh --list
# Confirme o device (ex. /dev/sdX) — NÃO use disco do sistema:
./scripts/write-usb-esp.sh --device /dev/sdX --confirm /dev/sdX --yes
```

Simulação: `--dry-run`. Prefere `build/ia-livre-esp.img` via `dd`; sem `.img`, monte a FAT e use a árvore `build/baremetal-esp/`.

## 3. Firmware (Secure Boot / Boot Menu)

1. **Secure Boot:** desligar ou entrar em setup mode. Este projeto **não** assina o EFI.
2. Entre no Boot Menu (tecla do fabricante: F12 / Esc / F10…).
3. Escolha o pendrive em modo **UEFI** (não Legacy/CSM, se evitável).

## 4. Evidência padrão (sem cabo serial) — Etapa 73

Canal canônico: arquivo na ESP [`baremetal-report.md`](baremetal-report.md) / ADR [`0025`](adr/0025-baremetal-report-esp.md).

1. Boot até a tela azul (“IA Livre”) / `EXIT_BOOT_BEGIN`.
2. Desligue; no Linux, monte o pendrive.
3. Colete o report (ou copie à mão):

   ```bash
   ./scripts/collect-baremetal-report.sh --mount /media/$USER/IALIVRE
   # opcional: --verify
   ```
4. Valide:
   ```bash
   IA_LIVRE_BAREMETAL_SKIP=0 \
   IA_LIVRE_BAREMETAL_EVIDENCE=docs/evidence/boot-metal/YYYY-MM-DD-<host>.txt \
   make verify-baremetal
   ```
   Esperado: `IA_LIVRE_BAREMETAL_METAL_OK`.

**Serial (opcional):** lab com USB-UART COM1 115200 8N1 ainda funciona; **não** é obrigatório.

## 5. O que esperar na tela / no report

Mínimo: `IA_LIVRE_BOOT_OK`, `IA_LIVRE_OBS_OK`, `IA_LIVRE_BAREMETAL_REPORT_OK` no arquivo da ESP.

Path metal **sem** BlockIO (ESP-only): pode aparecer `B_BLOCK_METAL=no_gguf_metal_io` — bloqueio **honesto** (E48).

## 6. O que **não** esperar

| Não espere | Por quê |
|------------|---------|
| Hipótese A vs B “comprovada” | Veredito ainda `INCONCLUSIVO` / `BLOQUEIO_FINAL` |
| `METAL_OK` só por gravar USB | Precisa do **report** ESP (ou serial) sem QEMU/OVMF |
| `METAL_OK` a partir de vídeo/foto | Fora do gate |
| Desktop / Wi-Fi / apps | Fora do escopo do SO mínimo |
| GGUF TinyLlama completo no stick default | Opt-in `FULL_GGUF` |
| Rede/autonomia no guest | Continuam no **host** (ADR 0001) |

## 7. Evidência

Padrão: report ESP — ver §4 e [`docs/evidence/boot-metal/`](evidence/boot-metal/).  
Serial legado: [`boot-hardware-real.md`](boot-hardware-real.md).

## Release (mantenedores)

```bash
./scripts/prepare-baremetal-release.sh
# Saída típica: build/release/… + SHA256SUMS
# Depois: git tag vX.Y.Z && gh release create vX.Y.Z \
#   build/release/ia-livre-esp.tar.gz build/release/SHA256SUMS …
```

Procedimento completo no script e em [`boot-hardware-real.md`](boot-hardware-real.md).
