# ADR 0020 — Passo intermediário N≥8 / n_predict≥8 inviável no gate guest (pós-otimização E59)

- Status: aceita
- Data: 2026-11-21

## Contexto

Etapa 59 exigia medição + otimização em `runtime-native/` para caber o **passo intermediário** (N≥8 layers e/ou `n_predict`≥8) **ou** 22L×32 no timeout do gate guest (**600 s**), **ou** declarar inviável com evidência pós-otimização.

ADR [`0016`](0016-veredito-limpo-harness-a-b.md) já estabelecia teto operacional 2L×`n_predict=1` e inviabilidade de 22L×32 **sem** ordem de magnitude. E59 tentou o ganho.

Contrato de medição: [`../runtime-native-perf-especie.md`](../runtime-native-perf-especie.md).

## Decisão

1. **Inviável no guest (gate 600 s):** após otimização concreta (fused Q4 dequant+dot; dispatch Q4/Q6; evidência ~7–10% host), o passo intermediário **N≥8** (e, por extrapolação, `n_predict`≥8 e 22L×32) **não** cabe no timeout do guest QEMU.
2. **Teto guest permanece** `PREFILL_LAYERS_GUEST=2` × `N_PREDICT_GUEST=1` (E44/E45).
3. **Host ≠ prova B:** microbench host `IA_LIVRE_NATIVE_PERF_HOST_MS_8L1≈2031` mostra que N=8 é factível no Linux host — **não** conta como evidência de Linha B guest.
4. **Hipótese A vs B** permanece **aberta** / comparable `INCONCLUSIVO` (teto E45). **Proibido** `COMPROVA` com subset.
5. **B54** (espécie canônica no comparable) continua dependente de ganho ≫10× (SIMD guest / GPU guest / outro caminho) — esta ADR **não** fecha B54 nem declara bloqueio **terminal** da hipótese global (só do passo intermediário **no gate atual** pós-E59).

### Evidência (pós-otimização)

| Item | Valor |
|------|--------|
| Otimização | fused `dot_block_q4_k` + matvec sem `wrow`; Q4/Q6 dispatch |
| Ganho host (wall teste decode) | ~1,91 s → ~1,78 s (~7%); prefill ~10% |
| Host 2L×1 / 8L×1 (só compute pós-warm) | ~646 ms / ~2031 ms |
| Guest `make verify` 2L (histórico) | ~267 s |
| Extrapolação guest 8L | ~800 s ≫ 600 s |
| Ordem de magnitude? | **Não** — ganho ≪10× |

## Consequências

- Gate E59 (`verify-runtime-native-perf`) valida esta ADR + marcadores de evidência no doc/teste — **sem** exigir N≥8 no QEMU.
- Comparable / harness B: espécie guest inalterada; reason de teto E45 permanece válido.
- Próximo: B54 só se houver caminho novo de perf; senão backlog de SIMD/GPU guest (B59/B60).
