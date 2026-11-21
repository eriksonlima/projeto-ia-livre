# GGUF canônico em mídia bare-metal (Etapa 36)

Ponte: [`boot-hardware-real.md`](boot-hardware-real.md) · ADR [`0011`](adr/0011-boot-imagem-esp-baremetal.md).  
Spec: [`../specs/gguf-baremetal-midia/`](../specs/gguf-baremetal-midia/).

> **Não** prova A vs B. **Não** emite `TOKENS_PER_S`. QEMU BlockIO ≠ path em PC.

## Modelo canônico

| Campo | Valor |
|-------|--------|
| Arquivo host | `models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf` (~638 MiB) |
| Obter | `./scripts/fetch-model.sh` |
| Na ESP (opt-in) | `IA_LIVRE/model.gguf` |
| Prefixo legado | `IA_LIVRE/gguf.hdr` (4 KiB) — **distinto** do modelo completo |

## Modos de entrega

| Modo | Quando | O que |
|------|--------|--------|
| **(a) ESP/tar completo** | `IA_LIVRE_BAREMETAL_FULL_GGUF=1` | Copia o GGUF para `build/baremetal-esp/IA_LIVRE/model.gguf` + tar; gate `BAREMETAL_GGUF_OK` |
| **(b) USB / path doc** | Sem flag (default) | Operador coloca `model.gguf` na mídia; loader via `EFI_SIMPLE_FILE_SYSTEM_PROTOCOL` (documentado abaixo) |

Default do gate (`make verify-baremetal`) **não** exige o GGUF completo (evita ~638 MiB em CI).

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
./scripts/fetch-model.sh

# Default — só artefato EFI + gguf.hdr opcional
make baremetal-esp
make verify-baremetal   # IMAGE_OK; sem BAREMETAL_GGUF_OK

# Opt-in — modelo completo na árvore/tar
IA_LIVRE_BAREMETAL_FULL_GGUF=1 make baremetal-esp
IA_LIVRE_BAREMETAL_FULL_GGUF=1 make verify-baremetal   # + BAREMETAL_GGUF_OK
```

Imagem FAT (`.img`): com `FULL_GGUF=1` use `IA_LIVRE_BAREMETAL_IMG_MB` ≥ ~700 (default 64 é insuficiente).

## Path I/O UEFI (modo b / loader)

Protocolo: **`EFI_SIMPLE_FILE_SYSTEM_PROTOCOL`** (antes de `ExitBootServices`).

1. Localizar handle com SimpleFileSystem (volume FAT da ESP/USB).
2. `OpenVolume` → abrir `\\IA_LIVRE\\model.gguf` (ou path documentado).
3. Ler magic `GGUF` + tamanho; opcionalmente prefixo/header para prova.
4. Se ausente: marcador honesto de skip/fail — **não** fingir carga completa.

Em QEMU o caminho canônico de prova completa continua sendo o disco raw BlockIO (`build/gguf-canon.gguf`) das Etapas 26/27 — **não** confundir com a ESP bare-metal.

## Glue loader (contrato)

Pseudocódigo (kernel glue; motor permanece em `runtime-native` — ADR 0001):

```text
on_boot_services:
  locate SimpleFileSystem handles
  for each volume:
    try open "\\IA_LIVRE\\model.gguf"
    if ok and magic == GGUF:
      emit GGUF_LOADER=esp_file / BYTES=…
      (optional) read header / stage for later
      return
  if only gguf.hdr present:
    emit loader=esp_header (legado E26)
  else:
    emit SKIP=no_gguf_on_esp   # honesto
```

Implementação completa do stage pós-ExitBoot do arquivo ESP → RAM tipada é **fora** do mínimo desta etapa se o artefato + doc já cumprem o Pronto quando; avanço de glue serial pode seguir em fatia futura sem inventar tokens.

## Limites honestos

| Limite | Nota |
|--------|------|
| Artefato ≠ boot metal | `IMAGE_OK` / `GGUF_OK` ≠ `METAL_OK` |
| Sem TOKENS_PER_S | Modelo na mídia ≠ inferência |
| Secure Boot | EFI não assinado |
| Espaço USB | ~700 MiB+ livres para modo (a) |
| BlockIO QEMU | Path de prova GGUF guest; distinto da ESP |

## Relação com gates

| Gate | GGUF completo |
|------|----------------|
| `make verify` (QEMU) | BlockIO `gguf-canon` |
| `make verify-baremetal` | Só com `FULL_GGUF=1` → `BAREMETAL_GGUF_OK` |
| Metal | E35 evidência serial; GGUF na mídia é pré-requisito de I/O, não prova de boot |
