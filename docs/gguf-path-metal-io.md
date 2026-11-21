# I/O GGUF no path metal (Etapa 63)

Ponte: ADR [`0017`](adr/0017-path-metal-sfs-vs-blockio.md) · [`gguf-baremetal-midia.md`](gguf-baremetal-midia.md) · [`boot-hardware-real.md`](boot-hardware-real.md).  
Spec: [`../specs/io-gguf-path-metal/`](../specs/io-gguf-path-metal/).

> **Não** é `METAL_OK` (E62). **Não** prova hipótese A vs B. **Não** trata BlockIO como metal.

## Problema herdado (E48)

| Fato | Valor |
|------|--------|
| Path metal | SimpleFileSystem / ESP (`IA_LIVRE_GGUF_PATH=esp_sfs`) |
| Desfecho E48 | `IA_LIVRE_B_BLOCK_METAL=no_gguf_metal_io` |
| Causa | QEMU `fat:rw:<dir>` ≈ FAT16 (~516 MiB) &lt; TinyLlama (~638 MiB); kernel SFS só lê prefixo `gguf.hdr` |
| Prova BlockIO | `GGUF_NATIVE_LOADER=blockio_full` — Linha B / harness; **≠** metal |

ADR 0017 já previa **QEMU FAT32** / PC como caminho para I/O full. Esta etapa tenta esse caminho (ou documenta inviabilidade medida).

## Ambiente de prova (QEMU-espelho)

| Peça | Requisito |
|------|-----------|
| Modelo | `./scripts/fetch-model.sh` → `models/tinyllama-….Q4_K_M.gguf` |
| ESP com GGUF | `IA_LIVRE_BAREMETAL_FULL_GGUF=1` (+ `IA_LIVRE_BAREMETAL_IMG_MB` ≥ ~700) |
| Mídia | Preferir **imagem FAT32** (`build/ia-livre-esp.img` via `mtools`/`mkfs.vfat -F 32`) — **não** `fat:rw:` directory (FAT16) |
| Deps host | QEMU/OVMF; `mtools` + `dosfstools` para `.img` |
| Memória guest | QEMU `-m` suficiente para stage SFS→RAM (documentar no runner; tipicamente ≥1–2G se carga full) |
| PC físico | Opt-in; **não** exige `METAL_OK` |

## Caminhos de desfecho

### A — I/O full / geração mínima (preferido)

Leitura SFS de `\\IA_LIVRE\\model.gguf` (completo ou bytes necessários ao subset) → RAM tipada → (opcional) `runtime-native` subset.

**Marcadores obrigatórios (serial):**

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_GGUF_PATH=esp_sfs` | Path metal (≠ `blockio`) |
| `IA_LIVRE_GGUF_NATIVE_LOADER=esp_sfs_full` | Loader SFS full (≠ `blockio_full`, ≠ `esp_header`) |
| `IA_LIVRE_GGUF_MAGIC_OK` | Magic GGUF lido via SFS |
| `IA_LIVRE_GGUF_HEADER_OK` | Header válido no path SFS |

**Opcional (geração mínima subset):**

| Marcador | Regra |
|----------|--------|
| `IA_LIVRE_RUNTIME_NATIVE_LOAD_KIND=gguf` | Só se pesos vieram do path SFS |
| `IA_LIVRE_RUNTIME_NATIVE_TOKENS_PER_S_MILLI=` | **Medido** no path SFS; **proibido** copiar do BlockIO |

**Proibido no desfecho A:**

- `IA_LIVRE_B_BLOCK_METAL=no_gguf_metal_io` como único desfecho (pode coexistir só se substituído/supersedido por progresso documentado — preferir **ausência**)
- `IA_LIVRE_GGUF_PATH=blockio` / `GGUF_NATIVE_LOADER=blockio_full` como prova desta etapa
- `IA_LIVRE_BAREMETAL_METAL_OK` fabricado
- `TOKENS` sem loop real no path SFS

### B — Bloqueio honesto (fallback)

Só após **tentativa medida** de FAT32 + `FULL_GGUF` (e/ou limites pós-Exit / OOM / timeout documentados).

| Peça | Exigência |
|------|-----------|
| ADR | Nova (sugerida `0023`) — motivo estável; **≠** “ainda não tentamos FAT32” |
| Marcador | `IA_LIVRE_B_BLOCK_METAL=` com valor **novo** ou motivo explícito documentado no ADR (não reutilizar só o texto E48 sem avanço) |
| Gate | Prova o bloqueio B; **falha** se houver `TOKENS` / `METAL_OK` fabricados |
| Path | Continua `GGUF_PATH=esp_sfs` (ou fail SFS honesto) — **nunca** fingir BlockIO |

Critérios medidos mínimos para aceitar B:

1. Artefato FAT32 com `model.gguf` presente (ou evidência de falha ao gerar img).
2. Corrida QEMU ESP-only **sem** BlockIO raw.
3. Log/serial + nota de falha (tamanho, `LOADER_FAIL`, OOM, timeout) anexada ao ADR.

## Relação com gates

| Gate | Papel |
|------|--------|
| `make verify` | BlockIO — regressão; **não** é prova metal |
| `make verify-metal-infer` | E63: prova **A ou B** (Task 3); baseline E48 permanece até o ramo novo verde |
| `make verify-baremetal` | Artefato / SKIP `METAL_OK` — independente |
| Bridge E49 | Se `B_BLOCK_METAL` mudar, atualizar `metal_block` (Task 3) |

## Regressão e honestidade

- BlockIO `blockio_full` permanece canônico para harness Linha B.
- Pilar 1 (`BLOQUEIO_FINAL` / ADR 0022) **intocado**.
- E62 `METAL_OK` **intocado**.
