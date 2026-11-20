# Progress

## O que funciona

- Docs + ADR 0001 + ADR 0002 (GPU host via llama.cpp)
- Kernel: `make verify`
- Runtime CPU: `make verify-runtime` (com `--n-gpu-layers` default 0 + marcadores ACCEL)
- Nó Rede IA Livre: `make verify-node`
- Ambiente de autonomia: `make verify-agent`
- Etapas 1–7 feitas; Etapa 8 em andamento (Task 1 feita)
- Processo de backlog: `BACKLOG.md` + rule/command/skill
- Processo README por fatia: `.cursor/rules/readme-por-fatia.mdc`

## Bloqueios

- Nenhum no produto; espelho `gh` do backlog é best-effort
- Host tem GTX 1050; `nvcc` pode faltar para feature `cuda` — Vulkan como alternativa (ADR 0002)

## Por etapa

- Etapas 1–7: feitas
- Etapa 8: `em_andamento` (Issue #8); Tasks 1–2 feitas; Task 3 aberta
- Backlog aberto: B3 (harness Linha A vs B); B2 promovido/arquivado
