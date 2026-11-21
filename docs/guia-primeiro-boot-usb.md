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
| PC físico + serial | Boot real | evidência → `METAL_OK` (opt-in) |

## Pré-requisitos

- PC x86-64 com firmware UEFI
- Pendrive (será **apagado**)
- Cabo USB-UART (ou serial) no **COM1** do guest, **115200 8N1**
- Host Linux com Rust, QEMU/OVMF (só se for buildar), `gh` opcional para Release

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

## 4. Serial

- **115200 8N1**, UART COM1 (como no QEMU `-serial stdio`).
- No host: `picocom -b 115200 /dev/ttyUSB0` (ajuste o device).
- Sem serial: só confirmação visual de que o firmware carregou o EFI — **não** basta para `METAL_OK`.

## 5. O que esperar na serial

Mínimo de sucesso no metal (E46):

- `IA_LIVRE_BOOT_OK`

Ideal (fluxo mais completo):

- `IA_LIVRE_EXIT_BOOT_OK` e marcadores posteriores, se o hardware/caminho permitir

Path metal **sem** BlockIO (ESP-only): pode aparecer `B_BLOCK_METAL=no_gguf_metal_io` — bloqueio **honesto**, não geração fingida (E48).

## 6. O que **não** esperar

| Não espere | Por quê |
|------------|---------|
| Hipótese A vs B “comprovada” | Veredito ainda `INCONCLUSIVO` |
| `METAL_OK` só por gravar USB | Precisa log real sem QEMU/OVMF |
| Desktop / Wi-Fi / apps | Fora do escopo do SO mínimo |
| GGUF TinyLlama completo no stick default | Opt-in `FULL_GGUF` |
| Rede/autonomia no guest | Continuam no **host** (ADR 0001) |

## 7. Evidência (opcional)

Se capturar serial em PC real: formate conforme [`boot-hardware-real.md`](boot-hardware-real.md) e deixe em `docs/evidence/boot-metal/`. Gate: `IA_LIVRE_BAREMETAL_SKIP=0` + `IA_LIVRE_BAREMETAL_EVIDENCE=… make verify-baremetal`.

## Release (mantenedores)

```bash
./scripts/prepare-baremetal-release.sh
# Saída típica: build/release/… + SHA256SUMS
# Depois: git tag vX.Y.Z && gh release create vX.Y.Z \
#   build/release/ia-livre-esp.tar.gz build/release/SHA256SUMS …
```

Procedimento completo no script e em [`boot-hardware-real.md`](boot-hardware-real.md).
