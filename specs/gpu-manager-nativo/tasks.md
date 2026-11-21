# Tasks — GPU manager nativo (mecanismos kernel ↔ runtime)

Etapa 38 · Spec: `specs/gpu-manager-nativo/`

Uma task = uma fatia.

- [x] Task 1 — Criar `docs/gpu-manager-nativo.md` + pontes (desenho E16, stub E25, MEM_SCHED E19) e pré-anunciar marcadores `IA_LIVRE_GPU_MGR=native` em `AGENTS.md`
- [x] Task 2 — Implementar enum sintética, afinidade Weights/KvCache e placement Prefill/Decode pós-`MEM_SCHED_OK` em `kernel/` (módulo dedicado) com emissão COM1; ponte opcional em `runtime-native/`
- [x] Task 3 — Estender `scripts/verify-boot.sh` + `AGENTS.md` (gate aditivo, greps E38) e confirmar `make verify` verde sem regressão de `verify-gpu-manager` / harness / `TOKENS_PER_S`