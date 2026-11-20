# Kernel pós-Boot Services (Etapa 11)

Handoff mínimo: sair de UEFI Boot Services com **mapa preservado** e **memória utilizável**, provável na serial do QEMU.  
Não é inferência no núcleo (ADR 0001). Não é Linha B (backlog B5).

Pré-requisito: Etapa 10 — [`kernel-alem-do-boot.md`](kernel-alem-do-boot.md).

## Decisão de desenho

| Peça | Escolha |
|------|---------|
| Saída | `boot::exit_boot_services(LOADER_DATA)` (uefi 0.33) |
| Pré-exit I/O | Serial UEFI / ConOut (marcadores Etapa 10 + `EXIT_BOOT_BEGIN`) |
| Pós-exit I/O | **UART 16550 COM1 `0x3F8`** bare-metal (mesma `-serial stdio`) |
| Mapa pós-exit | `MemoryMapOwned` retornado pela API |
| Memória | Reprovar bump no bloco `AllocatePages` da Etapa 10 **após** o exit |
| MMU / heap geral | **Fora** |

**Rejeitado:** emitir `EXIT_BOOT_OK` só antes do exit; usar Serial UEFI depois do exit.

Spec: [`specs/kernel-pos-boot-services/`](../specs/kernel-pos-boot-services/).

## Marcadores serial

### Pré-exit (caminho UEFI)

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_BOOT_OK` … `ALLOC_OK` | Regressão Etapa 4/10 |
| `IA_LIVRE_EXIT_BOOT_BEGIN` | Última linha UEFI antes de `exit_boot_services` |

### Pós-exit (somente COM1)

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_EXIT_MAP_PAGES=<n>` | Páginas Conventional no mapa owned |
| `IA_LIVRE_EXIT_MAP_OK` | Mapa pós-exit iterado |
| `IA_LIVRE_EXIT_MEM_OK` | Bump write/read após o exit |
| `IA_LIVRE_EXIT_BOOT_OK` | ExitBoot + base estável ok |

Em falha: **não** emitir `IA_LIVRE_EXIT_BOOT_OK`.

## Valores de prova

| Item | Valor |
|------|--------|
| UART | COM1 `0x3F8`, 115200 8N1 |
| Bloco bump | 2 × 4 KiB `LOADER_DATA` (Etapa 10), reprovado **após** exit |

### Exemplo de serial (host de referência)

```
IA_LIVRE_BOOT_OK
IA_LIVRE_MEM_CONVENTIONAL_PAGES=…
IA_LIVRE_MEM_MAP_OK
IA_LIVRE_ALLOC_BYTES=64
IA_LIVRE_ALLOC_OK
IA_LIVRE_EXIT_BOOT_BEGIN
IA_LIVRE_EXIT_MAP_PAGES=…
IA_LIVRE_EXIT_MAP_OK
IA_LIVRE_EXIT_MEM_OK
IA_LIVRE_EXIT_BOOT_OK
```

Linhas pós-`EXIT_BOOT_BEGIN` vêm da UART COM1 (podem incluir `\r` antes de `\n`).

## Como observar

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
make build
make run      # serial: Etapa 10 → EXIT_BOOT_BEGIN → marcadores EXIT_* via COM1
make verify   # exige BOOT/MEM/ALLOC + EXIT_BOOT_OK (e EXIT_MAP/MEM); VERIFY_TIMEOUT default 45s
```

## Fora de escopo

- Inferência / GGUF / llama.cpp no UEFI
- Runtime Linha B (`HARNESS_B_SKIP`)
- MMU completa, heap buddy/slab, filesystem, rede, GPU, scheduler
