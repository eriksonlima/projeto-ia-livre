# Progress

## O que funciona

- Docs + ADR 0001 + ADR 0002
- Kernel: `make verify` → BOOT/MEM/ALLOC + ExitBoot (`EXIT_BOOT_OK`) via COM1 (Etapas 4/10/11)
- Runtime CPU/GPU, nó, agent, harness (A ok + B skip)
- Etapas 1–11 feitas

## Bloqueios

- Linha B do harness: stub até runtime nativo (B5)
- CUDA Toolkit ausente no host de referência → Vulkan (ADR 0002)

## Por etapa

- Etapas 1–11: feitas
- Backlog Abertas (topo): B5 (#11), B6 (#12), B8–B12 (#14–#18)
