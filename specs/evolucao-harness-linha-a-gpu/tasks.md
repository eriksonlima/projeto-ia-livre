# Tasks — Evolução do harness (Linha A otimizada / perfil GPU)

Uma task = uma fatia.

- [ ] Task 1 — Metodologia «Linux otimizado» na Linha A
  - **Pronto quando:** existe documentação (doc dedicado `docs/harness-perfis-a-otimizada-gpu.md` **ou** seção equivalente em `docs/harness-linha-a-b.md`, path fixado na fatia) que: (1) distingue **A pragmática** (harness v1 atual, sem campanha de tuning) de **A otimizada** (perfil nomeado); (2) lista checklist mínimo repetível de «Linux otimizado» (ex. governor/performance, afinidade/`isolcpus` ou isolamento de ruído, notas de carga do sistema); (3) preserva carga canônica (TinyLlama Q4_K_M, prompt, `n-predict=32`, marcadores `HARNESS_*`); (4) deixa explícito que otimizar A **não** prova a hipótese A vs B. Sem inventar números de B. Sem GPU manager. Sem gate novo nesta fatia (só metodologia). README avaliado (`readme-por-fatia`).

- [ ] Task 2 — Metodologia perfil GPU espelhado A/B
  - **Pronto quando:** a mesma doc (ou seção irmã) descreve o perfil GPU do harness: (1) Linha A host com mesma carga canônica + offload (`--n-gpu-layers` > 0, CUDA canônico / Vulkan alternativa per ADR 0002); (2) fronteira clara vs métricas Etapa 8 (`runtime-inferencia-gpu-metricas.md`) e vs GPU manager (ADR 0006 — não implementar); (3) espelho em B **condicionado** a caminho GGUF/acelerador real — até lá, GPU-B = roadmap de medição **sem** inventar `TOKENS_PER_S`/load GGUF no proxy; (4) marcadores sugeridos (`HARNESS_ACCEL=…`) sem obrigar script se não houver execução. Hipótese não comprovada. README reavaliado.

- [ ] Task 3 — Pontes (harness / architecture) e decisão de gate
  - **Pronto quando:** `docs/harness-linha-a-b.md` aponta os perfis (deixando de tratar «GPU fora / A sem tuning» como fim da história, sem invalidar o v1); `docs/architecture.md` registra evolução metodológica do harness com prova **ainda aberta**; pontes mínimas em docs E8/ADR 0002 e/ou `runtime-nativo-linha-b.md` se necessário; **decisão de gate explícita:** (a) se houver execução real dos perfis nesta etapa → script + verificação documentada em AGENTS; **ou** (b) default — gate permanece `make verify-harness` (A CPU + B proxy) e perfis são só metodologia/roadmap de medição. Sem regressão do gate atual. Sem declarar hipótese comprovada. Sem GPU manager. README reavaliado; etapa pronta para revisão (não marcar `feita` aqui).
