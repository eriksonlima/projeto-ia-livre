# Active context

## Foco atual

- Etapa 8 — Aceleração além de CPU (GPU) (`em_andamento`, Issue #8)
- Spec: `specs/aceleracao-gpu/`
- Task 1 feita; próxima: Task 2 (caminho GPU real + métricas)

## Mudanças recentes

- B2 promovido → Etapa 8; backlog atualizado; issue #8 em Project (Em andamento)
- Spec `specs/aceleracao-gpu/` (ADR CUDA/Vulkan, `--n-gpu-layers`, gate GPU com skip)
- Task 1: ADR 0002, features Cargo, flag CLI, marcadores; `make verify-runtime` ok
- README Task 1: considerado; não atualizado (ponte AGENTS)

## Próximo passo

- Task 2: build com feature GPU, inferência `--n-gpu-layers` > 0, métricas GPU, AGENTS Como rodar GPU

## Notas

- Host: GTX 1050 + driver 535 (CUDA 12.2 no driver); `nvcc` pode estar ausente → tentar CUDA; se inviável, Vulkan (ADR 0002)
- Não promover B3 sem confirmação
