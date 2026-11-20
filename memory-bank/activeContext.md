# Active context

## Foco atual

- Processo: backlog → roadmap (mínima interrupção)
- Etapa do roadmap: nenhuma `em_andamento` (Etapas 1–8 **feitas**)
- Spec ativa: nenhuma (última: `specs/aceleracao-gpu/`, Tasks 1–3 feitas)

## Mudanças recentes

- Etapa 8: aceleração GPU no host (`runtime/` features cuda/vulkan, `--n-gpu-layers`, ADR 0002)
- Prova efetiva: **Vulkan** (CUDA sem toolkit no host); `IA_LIVRE_ACCEL=vulkan`
- Gate: `make verify-runtime-gpu` (+ skip `IA_LIVRE_GPU_SKIP`)
- B2 arquivado; Abertas: B3 (harness Linha A vs B)
- README Tasks 1–3: considerado; não atualizado (capa aponta AGENTS)

## Próximo passo

- Sob pedido “continuar” / confirmação: promover o topo do `BACKLOG.md` (B3 — harness Linha A vs B) para o roadmap + issue; depois especificar.

## Notas

- Promoção exige confirmação explícita; não inventar Etapa 9 sozinho
- Vulkan SDK user-space (`~/.local/opt/1.3.296.0`) não versionado no git
