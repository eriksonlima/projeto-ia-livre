# Kernel além do boot (Etapa 10)

Primeiro **mecanismo de memória** no kernel IA Livre sob UEFI Boot Services.  
Não é inferência no núcleo (ADR 0001). Não é Linha B / runtime nativo (backlog B5).

## Decisão de desenho

| Peça | Escolha |
|------|---------|
| Ambiente | UEFI Boot Services (mesmo QEMU/OVMF da Etapa 4) |
| Mecanismo A | Mapa de memória UEFI + resumo na serial |
| Mecanismo B | `AllocatePages` + bump allocator trivial sobre o bloco |
| `ExitBootServices` | **Fora** desta etapa |
| Inferência / GGUF | **Proibido** no kernel |
| Carregamento ESP | Fora do mínimo desta etapa |

Spec: [`specs/kernel-alem-do-boot/`](../specs/kernel-alem-do-boot/).

## Marcadores serial (canônicos)

Ordem sugerida (ajuda o gate):

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_BOOT_OK` | Boot UEFI ok (regressão Etapa 4) |
| `IA_LIVRE_MEM_CONVENTIONAL_PAGES=<n>` | Páginas Conventional Memory vistas no mapa |
| `IA_LIVRE_MEM_MAP_OK` | Mapa obtido e processado |
| `IA_LIVRE_ALLOC_BYTES=<n>` | Bytes comprometidos na prova (`n` > 0) |
| `IA_LIVRE_ALLOC_OK` | Páginas + bump (write/read) concluíram |

Em falha de mapa ou alloc: **não** emitir o `*_OK` correspondente (gate vermelho).

## Valores de prova (fixados)

| Item | Valor |
|------|--------|
| Páginas `AllocatePages` | **2** × 4 KiB (`PROOF_PAGES` em `kernel/src/main.rs`) |
| Bytes do bump (write/read) | **64** (`BUMP_PROOF_BYTES`) |
| Tipo UEFI do bloco | `LOADER_DATA` |
| Allocator global | Não — bump local sobre o bloco |

### Exemplo de serial (host de referência)

```
IA_LIVRE_BOOT_OK
IA_LIVRE_MEM_CONVENTIONAL_PAGES=53292
IA_LIVRE_MEM_MAP_OK
IA_LIVRE_ALLOC_BYTES=64
IA_LIVRE_ALLOC_OK
```

`MEM_CONVENTIONAL_PAGES` varia com a RAM do QEMU; o gate exige a presença da linha e dos `*_OK`.

## Como observar

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
make build
make run      # serial no stdio — procurar os marcadores acima
make verify   # exige BOOT_OK + MEM_MAP_OK + ALLOC_OK (+ páginas/bytes); VERIFY_TIMEOUT default 45s
```

## Fora de escopo

- Inferência, GGUF, llama.cpp no UEFI
- Runtime Linha B / substituir `IA_LIVRE_HARNESS_B_SKIP`
- `ExitBootServices`, MMU completa, heap geral
- Filesystem, rede, GPU, scheduler

## Relação com outras docs

- Arquitetura (camada 1): [`architecture.md`](architecture.md)
- ADR kernel × runtime: [`adr/0001-separacao-camadas-e-p2p.md`](adr/0001-separacao-camadas-e-p2p.md)
- Harness A vs B (instrumento; B ainda stub): [`harness-linha-a-b.md`](harness-linha-a-b.md)
