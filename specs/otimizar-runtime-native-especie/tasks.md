# Tasks — Otimizar runtime-native (SIMD/teto) para espécie canônica

Uma task = uma fatia.

- [x] Task 1 — Baseline + alvo: doc de medição (host e/ou QEMU release) do teto 2L×`n_predict=1` vs passo intermediário (N≥8 / `n_predict`≥8) e canônico 22L×32; contrato E59 + ponte ADR 0016; reservar ADR 0020 para inviável
- [x] Task 2 — Otimização concreta em `runtime-native` (SIMD/unroll/quant path/matvec/etc.) com evidência de ganho **ou** tentativa honesta documentada (antes/depois); sem inventar `TOKENS_PER_S`
- [ ] Task 3 — Gate/marcadores: prova do passo N≥8 e/ou `n_predict`≥8 (ou 22L×32) no timeout **ou** ADR 0020 inviável pós-otimização; `AGENTS.md`/`Makefile` se couber; comparable sem COMPROVA fingido; README avaliado

## Critério de pronto da etapa (espelho ROADMAP)

Medição documentada (passo intermediário N≥8 / `n_predict`≥8 **ou** 22L×32 no timeout do gate) **ou** ADR nova pós-otimização declara inviável com evidência; sem fingir `COMPROVA`; hipótese permanece aberta até B54.
