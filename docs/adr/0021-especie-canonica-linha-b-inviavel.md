# ADR 0021 — Espécie canônica Linha B (22L × n_predict=32) inviável no gate atual

- Status: aceita
- Data: 2026-11-21

## Contexto

Etapa 60 (B54) pede espécie canônica no comparable: B com `PREFILL_LAYERS=22` + `N_PREDICT=32` e veredito ∈ {COMPROVA, REFUTA, INCONCLUSIVO} **sem** reason de teto/subset.

Pré-condição: ADR [`0020`](0020-runtime-native-passo-intermediario-inviavel.md) (E59) — após otimização ~7–10%, o passo **N≥8** já é inviável no guest QEMU (timeout 600 s). A espécie canônica (22L×32) é **≥ ordem de magnitude** mais cara que N=8.

Sem **caminho novo** de perf (SIMD guest / GPU guest / redesign do motor / timeout honesto + hardware dedicado documentado), forçar 22L×32 no gate seria fraude ou timeout eterno.

## Decisão

1. **Espécie canônica inviável** no gate guest atual (600 s, QEMU release, motor pós-E59).
2. Teto guest permanece **2L × `n_predict=1`** (E44/E45/0020).
3. Comparable permanece **`INCONCLUSIVO`** com reason de teto (`E45_perf_ceiling_below_canonical_*`) — **proibido** `COMPROVA`/`REFUTA` com espécie desigual.
4. **Não** é bloqueio terminal da **hipótese de pesquisa** do projeto: isso fica para **B58** (backlog) — documentação de bloqueio final explícito do pilar 1, se a comunidade aceitar fechar sem espécie canônica.
5. Caminhos futuros que **reabriam** A: SIMD/GPU guest (B59/B60 do backlog), redesign freestanding, ou mudança documentada de methodology/timeout — exigiriam **nova** etapa, não reabrir esta ADR sem evidência.

### Evidência encadeada

| Fonte | Conclusão |
|-------|-----------|
| ADR 0016 | 22L×32 inviável sem ordem de magnitude |
| ADR 0020 / E59 | N≥8 inviável pós +~10% |
| Extrapolação | 22L×32 ≫ N=8 ≫ timeout |

## Consequências

- Etapa 60 cumpre via desfecho **B** (esta ADR), não via comparable canônico.
- Pilar 1 do checklist E58 permanece **INCONCLUSIVO** (não “atingido”).
- Próximo produto sensato: B58 (bloqueio final) **ou** B56 (metal) enquanto perf guest não tiver caminho novo; B55 (re-corrida quieta) depende de espécie canônica — **adiada**.
