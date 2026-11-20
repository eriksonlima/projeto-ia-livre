# Progress

## O que funciona

- Docs + ADR 0001 + ADR 0002 (GPU host via llama.cpp)
- Kernel: `make verify` → `BOOT_OK` + `MEM_MAP_OK` + `ALLOC_OK` (Etapa 10)
- Runtime CPU: `make verify-runtime`
- Runtime GPU: `make verify-runtime-gpu` (`IA_LIVRE_ACCEL` ≠ `cpu`; skip `IA_LIVRE_GPU_SKIP`)
- Nó Rede IA Livre: `make verify-node`
- Ambiente de autonomia: `make verify-agent`
- Harness A vs B: `make verify-harness` (A ok + B skip)
- Etapas 1–10 feitas
- Processo de backlog + README por fatia

## Bloqueios

- Nenhum no produto; espelho `gh` do backlog é best-effort
- Host de referência: CUDA Toolkit (`nvcc`) ausente → prova Vulkan (ADR 0002)
- Linha B do harness: stub até runtime nativo (B5); ExitBoot ainda não (B7)

## Por etapa

- Etapas 1–10: feitas
- Backlog Abertas (topo primeiro): B7 (#13), B5 (#11), B6 (#12), B8–B12 (#14–#18)
