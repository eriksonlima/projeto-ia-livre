# Tasks — GPU real no caminho nativo (além de `synthetic`)

Etapa 55 · Spec: `specs/gpu-real-nativo/`

Uma task = uma fatia.

- [ ] Task 1 — Criar `docs/gpu-real-nativo.md` + pontes (E38/E25/E41); fixar marcadores `GPU_REAL_*` / `GPU_NEED_GPU`, política de skip e nomes do gate; pré-anunciar em `AGENTS.md`; ADR só se a fronteira `SRC=host` vs PCI for estrutural
- [ ] Task 2 — Implementar path B (detecção host + `SRC=host` + placement mínimo + `GPU_REAL_OK` ou skip `need_gpu`); documentar A (PCI/pass-through) e implementar probe guest só se não quebrar CI/E38 synthetic
- [ ] Task 3 — Adicionar `make verify-gpu-native-real` + greps em `AGENTS.md`; anti-fraude (sem `REAL_OK` com só synthetic; sem multi-GPU fingido); confirmar regressão E38/E25/E41; avaliar README
