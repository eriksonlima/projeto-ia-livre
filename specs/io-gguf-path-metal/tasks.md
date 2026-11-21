# Tasks — I/O GGUF no path metal (Etapa 63)

Uma task = uma fatia.

- [x] Task 1 — Contrato além de `no_gguf_metal_io`: FAT32/QEMU + marcadores A (loader full / geração mínima SFS) vs B (ADR 0023); critérios medidos; pontes ADR 0017 / `gguf-baremetal-midia.md`
- [x] Task 2 — Implementar ramo preferido: ESP/img FAT32 + `model.gguf` + loader SFS full (e/ou geração mínima subset) **ou**, com evidência, ADR nova + bloqueio honesto
- [x] Task 3 — Gate `verify-metal-infer` (A ou B) + `AGENTS.md` / pontes (bridge se marcador mudar); regressão `make verify`; README avaliado; sem `METAL_OK` / sem BlockIO-as-metal
