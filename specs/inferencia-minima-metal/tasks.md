# Tasks — Inferência mínima no metal (Etapa 48)

- [x] Task 1 — ADR 0017 + contrato BlockIO ≠ SFS + marcadores
- [x] Task 2 — ESP-only → `B_BLOCK_METAL=no_gguf_metal_io` (geração SFS full inviável FAT16)
- [x] Task 3 — `make verify-metal-infer` + pontes AGENTS; regressão implícita

## Desfecho

Caminho B: bloqueio honesto `no_gguf_metal_io`; gate ESP-only ok; sem TOKENS fingidos; sem METAL_OK.
