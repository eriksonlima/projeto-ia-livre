# Active context

## Foco atual

- Etapa **63** `em_andamento` (B57 / #63) — I/O GGUF path metal
- Spec: `specs/io-gguf-path-metal/`
- Task 1 **feita** (contrato `docs/gguf-path-metal-io.md`)
- Próxima: Task 2 — FAT32 `.img` + loader `esp_sfs_full` **ou** ADR 0023

## Próximo passo

- Implementar ramo A (preferido): SFS full via FAT32 img; runner ESP-only sem `fat:rw:`

## Notas

- Lease: cursor-agent-a326036c · E63
- ≠ METAL_OK; ≠ BlockIO-as-metal
