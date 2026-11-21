# Tasks — Espécie canônica Linha B (22L × n_predict=32)

Uma task = uma fatia.

- [ ] Task 1 — Decisão A vs B + contrato E60: ancorar em ADR 0020 (N≥8 já inviável); documentar que 22L×32 exige caminho **novo** (não +10%); reservar ADR 0021; ponte comparable + B58; sem expandir espécie no guest
- [ ] Task 2 — Desfecho: **B (esperado)** ADR 0021 inviável canônico no gate atual + docs/glossário/comparable INCONCLUSIVO/teto + ponte B58 + AGENTS se couber **ou** **A** caminho novo + B 22L×32 no `verify-harness-comparable` sem reason teto/subset; sem inventar tokens / sem COMPROVA fingido; README avaliado
- [ ] Task 3 — Só se Task 2 deixar lacuna: alinhar gate/`Makefile`/`AGENTS.md` ao desfecho (exige ADR 0021 **ou** marcadores canônicos); comparable honesto; senão no-op na fatia

## Critério de pronto da etapa (espelho ROADMAP)

`make verify-harness-comparable` com B `PREFILL_LAYERS=22` + `N_PREDICT=32` + veredito ∈ {COMPROVA,REFUTA,INCONCLUSIVO} **sem** reason de teto/subset; sem fingir COMPROVA; ADR 0020 permanece se inviável sem novo caminho.

> **Leitura honesta:** sem caminho novo, o cumprimento é via **ADR 0021** (canônico inviável) + 0020 + comparable ainda INCONCLUSIVO/teto + ponte B58 — **não** via fraudar espécie ou COMPROVA.
