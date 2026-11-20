# Active context

## Foco atual

- Etapa 8 — Aceleração além de CPU (GPU) (`em_andamento`, Issue #8)
- Spec: `specs/aceleracao-gpu/`
- Tasks 1–2 feitas; próxima: Task 3 (gate `verify-runtime-gpu` + skip)

## Mudanças recentes

- Task 2: caminho GPU real via **Vulkan** (CUDA inviável sem `nvcc` no host)
- Prova: `IA_LIVRE_ACCEL=vulkan`, ~54.7 tok/s, offload 23/23 (GTX 1050)
- Docs: `docs/runtime-inferencia-gpu-metricas.md`; AGENTS Como rodar GPU; nota ADR 0002
- README Task 2: considerado; não atualizado

## Próximo passo

- Task 3: `scripts/verify-runtime-gpu.sh` + `make verify-runtime-gpu` + política skip + AGENTS Como verificar

## Notas

- Vulkan SDK user-space: `~/.local/opt/1.3.296.0` (não versionado)
- Não promover B3 sem confirmação
