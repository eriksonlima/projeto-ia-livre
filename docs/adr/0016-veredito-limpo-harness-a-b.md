# ADR 0016 — Veredito limpo A vs B (espécie canônica vs teto)

- Status: aceita
- Data: 2026-11-21

## Contexto

E44 entregou geração real em B (`LOAD_KIND=gguf`, `TOKENS_PER_S` medidos) com espécie **subset** (2L × `n_predict=1`). O comparable emitia `INCONCLUSIVO` / `E44_subset_generate_not_canonical_species_*`. Etapa 45 pede veredito **limpo**: ∈ {COMPROVA, REFUTA, INCONCLUSIVO} **sem** reason de proxy, `no_gguf_full_prefill`, ou “subset-espécie” E44.

Prefill 22L×16 permanece inviável no QEMU (ADR 0014; host ~250 s). Expandir para 22L × `n_predict=32` no prazo do gate **não** é realista sem nova otimização de ordem de magnitude.

## Decisão

1. **Preferência (canônico):** `PREFILL_LAYERS=22` + `n_predict=32` → veredito por margem R=B/A (COMPROVA / REFUTA / INCONCLUSIVO).
2. **Teto honesto (fallback E45):** após tentativa/documentação de expansão + otimização release, se o máximo viável no gate for &lt; canônico →  
   `VERDICT=INCONCLUSIVO`  
   `VERDICT_REASON=E45_perf_ceiling_below_canonical`  
   (opcional sufixo `_layers=N_npredict=M` informativo).
3. **Reasons proibidos** no gate E45+:  
   - `E44_subset_generate_not_canonical_species*`  
   - `E43_no_gguf_prefill_22l*` / `no_gguf_full_prefill*`  
   - `E44_b_proxy_sem_gguf_generate` (B deve gerar)  
   - fraude de tokens
4. **Não** forçar `COMPROVA`/`REFUTA` com espécie desigual.
5. Microbench `PROXY=*` pode coexistir com `LOAD_KIND=gguf`.

### Evidência de teto (Task 2)

| Tentativa | Resultado |
|-----------|-----------|
| 22L×16 prefill QEMU debug | timeout 600 s (E43) |
| 2L×16 host release | ~7 s |
| Extrapolação 22L×16 host | ~250 s |
| Guest release E44 (2L×2 + decode 1) | verify ~267 s |
| Conclusão | 22L×32 no gate 600 s **inviável**; teto operacional permanece subset documentado |

## Consequências

- Comparable limpo aceita `E45_perf_ceiling_below_canonical` como INCONCLUSIVO honesto.
- Ampliar espécie além do teto = etapa/backlog futuro (otimização SIMD/GPU guest).
- Hipótese A vs B **não** comprovada nem refutada nesta etapa.

## Ponte — Etapa 59 (otimizar teto)

Contrato de medição + alvos intermediários (N≥8 / `n_predict`≥8) ou ADR **0020** inviável pós-otimização: [`../runtime-native-perf-especie.md`](../runtime-native-perf-especie.md).  
Esta ADR **não** é reescrita: E59 mede/otimiza; B54 é quem pode tornar a espécie canônica no comparable.
