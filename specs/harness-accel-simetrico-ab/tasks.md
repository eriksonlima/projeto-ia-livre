# Tasks — Accel GPU simétrica A/B no harness

Etapa 64 · Spec: `specs/harness-accel-simetrico-ab/`

Uma task = uma fatia.

- [ ] Task 1 — ADR 0023 (simetria GPU inviável até B60) + atualizar `docs/harness-perfis-a-otimizada-gpu.md` (+ ponte comparable/glossário): perfil `sym_cpu`; E56 = assimétrico; anti-fraude ACCEL em B
- [ ] Task 2 — Runner/agregação `sym_cpu` (A+B `ACCEL=cpu`) + alinhar `verify-harness-gpu` (reason assimetria / skip; falha se ACCEL GPU em B)
- [ ] Task 3 — Gate opt-in `make verify-harness-sym-cpu` (nome fixado) + `AGENTS.md`; regressões harness; README avaliado
