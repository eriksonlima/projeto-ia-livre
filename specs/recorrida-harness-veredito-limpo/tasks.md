# Tasks — Re-corrida harness A vs B com geração real (veredito limpo)

Uma task = uma fatia.

- [x] Task 1 — ADR 0016 + definição de “veredito limpo”
- [x] Task 2 — Expansão: evidência de teto (22L×32 inviável; guest permanece 2L×1 medido E44); sem inventar tokens
- [x] Task 3 — Comparable limpo: `E45_perf_ceiling_below_canonical_*`; rejeitar reasons E44_subset / proxy-only; README avaliado (sem mudança capa)

## Desfecho

- `VERDICT=INCONCLUSIVO` / `E45_perf_ceiling_below_canonical_layers=2_npredict=1`
- B continua gerando (`LOAD_KIND=gguf` + `TOKENS_PER_S`)
- Hipótese **não** comprovada (teto perf)
