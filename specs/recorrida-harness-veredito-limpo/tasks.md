# Tasks — Re-corrida harness A vs B com geração real (veredito limpo)

Uma task = uma fatia.

- [ ] Task 1 — ADR 0016 + definição de “veredito limpo” (canônico 22L×32 vs teto `E45_perf_ceiling_below_canonical`); reasons proibidos; pontes docs/`AGENTS.md`
- [ ] Task 2 — Expandir espécie B (layers / pos / `n_predict`) + otimização até máximo viável no gate (meta 22L×32); medições; sem inventar tokens
- [ ] Task 3 — Comparable limpo: `VERDICT` por margem ou reason E45 ADR-only; rejeitar proxy / `no_gguf_*` legado / `E44_subset_*`; quieta preservada; docs + README avaliado

## Pronto quando (etapa)

`make verify-harness-comparable` com B gerando; veredito ∈ {COMPROVA, REFUTA, INCONCLUSIVO} **sem** reason de proxy / `no_gguf_full_prefill` / subset-espécie; metodologia quieta preservada.
