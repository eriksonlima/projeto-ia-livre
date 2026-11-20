# Progress

## O que funciona

- Docs + ADR 0001 + ADR 0002 (GPU host via llama.cpp)
- Kernel: `make verify`
- Runtime CPU: `make verify-runtime`
- Runtime GPU: `make verify-runtime-gpu` (`IA_LIVRE_ACCEL` ≠ `cpu`; skip `IA_LIVRE_GPU_SKIP`)
- Nó Rede IA Livre: `make verify-node`
- Ambiente de autonomia: `make verify-agent`
- Harness A vs B: `make verify-harness` (A ok + B skip)
- Etapas 1–9 feitas
- Processo de backlog: `BACKLOG.md` + rule/command/skill
- Processo README por fatia: `.cursor/rules/readme-por-fatia.mdc`

## Bloqueios

- Nenhum no produto; espelho `gh` do backlog é best-effort
- Host de referência: CUDA Toolkit (`nvcc`) ausente → prova Vulkan (ADR 0002)
- Linha B do harness: stub até runtime nativo no IA Livre

## Por etapa

- Etapas 1–9: feitas
- Backlog Abertas: vazio (B1→E7, B2→E8, B3→E9)
