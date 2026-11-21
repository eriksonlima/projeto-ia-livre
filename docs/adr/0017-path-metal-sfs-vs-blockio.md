# ADR 0017 — Path metal (SimpleFileSystem/ESP) ≠ BlockIO QEMU

- Status: aceita
- Data: 2026-11-21

## Contexto

Etapa 48 pede inferência mínima no **path metal** (ESP/`model.gguf` via SimpleFileSystem) ou bloqueio honesto. O harness QEMU atual prova geração via **BlockIO** raw (`GGUF_NATIVE_LOADER=blockio_full`, E26–E44). Confundir os dois seria fraude de path.

## Decisão

1. **Dois loaders distintos:**
   - `blockio_full` — disco raw QEMU; prova Linha B / harness; **≠** metal.
   - `esp_header` / SFS — volume FAT da ESP; caminho metal/USB; marcador `IA_LIVRE_GGUF_PATH=esp_sfs` (ou equivalente).
2. **QEMU-espelho com GGUF completo na FAT:** inviável no default FAT16 (~516 MiB) vs TinyLlama ~638 MiB (já documentado E27). Ampliar a FAT32 só para CI desta etapa é opcional futuro — **não** requisito do Pronto quando se o bloqueio for honesto.
3. **Fallback Etapa 48:** quando só há prefixo ESP / SFS sem modelo completo carregável →  
   `IA_LIVRE_B_BLOCK_METAL=no_gguf_metal_io`  
   Gate prova o bloqueio; **proibido** `TOKENS_PER_S` / `METAL_OK` neste caminho.
4. Geração mínima no path SFS permanece desejável se I/O full for viável (PC com FAT32 ou QEMU FAT32 futuro).

## Rejeitado

- Tratar serial BlockIO como prova metal.
- Inventar `TOKENS_PER_S` ou `METAL_OK`.

## Consequências

- Gate aditivo `verify-metal-infer` (ESP-only) ≠ `verify` / `verify-harness`.
- E46 `METAL_OK` permanece independente.
