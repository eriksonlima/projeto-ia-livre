# Progress

## O que funciona

- Kernel UEFI QEMU + BlockIO Linha B (subset) + gates principais
- Runtime/node/agent host; harness comparable `INCONCLUSIVO` / pilar 1 `BLOQUEIO_FINAL` (ADR 0022)
- Bare-metal artefato + guia USB; `METAL_OK` SKIP neste host (E62)
- **E63:** I/O GGUF path metal — `esp_sfs_full` (FAT32 + SFS); `make verify-metal-infer` full

## Bloqueios

- Espécie canônica / COMPROVA — ADR 0020–0022
- `METAL_OK` — precisa log PC real
- B55 adiada enquanto 0021 vigorar

## Roadmap

- 1–63 feitas; sem `em_andamento` até promoção
