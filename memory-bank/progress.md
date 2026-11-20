# Progress

## O que funciona

- Docs + ADR 0001 + ADR 0002 (GPU host via llama.cpp)
- Kernel: `make verify` (ainda só `IA_LIVRE_BOOT_OK` até Task 3 da E10)
- Runtime CPU: `make verify-runtime`
- Runtime GPU: `make verify-runtime-gpu` (`IA_LIVRE_ACCEL` ≠ `cpu`; skip `IA_LIVRE_GPU_SKIP`)
- Nó Rede IA Livre: `make verify-node`
- Ambiente de autonomia: `make verify-agent`
- Harness A vs B: `make verify-harness` (A ok + B skip)
- Etapas 1–9 feitas; Etapa 10 em andamento
- Processo de backlog: `BACKLOG.md` + rule/command/skill
- Processo README por fatia: `.cursor/rules/readme-por-fatia.mdc`
- Contrato E10: `docs/kernel-alem-do-boot.md` (Task 1)

## Bloqueios

- Nenhum no produto; espelho `gh` do backlog é best-effort
- Host de referência: CUDA Toolkit (`nvcc`) ausente → prova Vulkan (ADR 0002)
- Linha B do harness: stub até runtime nativo no IA Livre (B5)

## Por etapa

- Etapas 1–9: feitas
- Etapa 10: em_andamento — Task 1 feita; Tasks 2–3 abertas
- Backlog Abertas: B5 (#11), B6 (#12)
