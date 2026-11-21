# Spec — Re-corrida harness A vs B com geração real (veredito limpo)

## Resultado visível

**Veredito limpo** em `make verify-harness-comparable`: Linha B **gera** (`LOAD_KIND=gguf`, `TOKENS_PER_S` medidos) e o instrumento emite `VERDICT` ∈ {`COMPROVA`, `REFUTA`, `INCONCLUSIVO`} **sem** `VERDICT_REASON` de proxy, `no_gguf_full_prefill` / legado E33, nem **subset-espécie** (`E44_subset_generate_not_canonical_species_*`). Metodologia quieta (Etapa 28) preservada.

**Preferência:** espécie canônica B = **22 layers** + **`n_predict=32`** (prompt/carga alinhados à Linha A) → veredito por **margem** de `TOKENS_PER_S` (R), como no contrato atual — **sem** reason de subset.

**Realismo (obrigatório):** Prefill 22L×16 já inviável mesmo em release no host (~250s; QEMU pior — ADR 0014/0015). Se 22L×32 permanecer inviável **após** otimização/documentação nesta etapa: fallback honesto — (i) ampliar `PREFILL_LAYERS` / pos / `n_predict` ao **máximo viável no gate**, **ou** (ii) `INCONCLUSIVO` com reason **novo** (ex. `E45_perf_ceiling_below_canonical`) que **não** seja proxy/legado/subset; docs de “veredito limpo” aceitam esse reason **somente** se ADR declarar teto honesto.

## Contexto fixo (não reinventar)

- **E44 desfecho:** Decode greedy subset `PREFILL_LAYERS=2` × `n_predict=1`; `LOAD_KIND=gguf`; `TOKENS_PER_S` medidos; `PROFILE=release`; comparable `INCONCLUSIVO` / `E44_subset_generate_not_canonical_species_layers=2_npredict=1`; ADR 0015; sem `B_BLOCK` no sucesso.
- **Motor:** `runtime-native/`; kernel glue/serial; build UEFI release.
- **ADRs:** [`0013`](../../docs/adr/0013-geracao-canonica-fatiada-linha-b.md), [`0014`](../../docs/adr/0014-prefill-22l-kv-linha-b.md), [`0015`](../../docs/adr/0015-decode-tokens-linha-b.md).
- **Contratos:** [`docs/harness-a-b-comparavel.md`](../../docs/harness-a-b-comparavel.md), [`docs/harness-corrida-quieta.md`](../../docs/harness-corrida-quieta.md), [`docs/harness-linha-a-b.md`](../../docs/harness-linha-a-b.md), [`docs/runtime-nativo-linha-b.md`](../../docs/runtime-nativo-linha-b.md).
- **Proibido:** inventar tokens; forçar `COMPROVA`; host-as-B; microbench-as-tokens.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A — Espécie canônica 22L×32** | Otimizar + expandir Prefill/Decode até 22 layers e `n_predict=32` no guest QEMU; comparable por margem R | **Preferida** |
| **B — Máximo viável + reason E45** | Se A inviável após tentativa documentada: maximizar layers/pos/`n_predict` no gate **ou** `INCONCLUSIVO` + `E45_perf_ceiling_below_canonical` (nome fixado no ADR); atualizar definição de “veredito limpo” para aceitar **só** esse reason de teto | **Fallback aceitável** |
| **C — Fraude** | Manter reason subset/proxy; inventar `TOKENS_PER_S`; forçar `COMPROVA`; fingir espécie canônica com 2L×1 | **Rejeitada** |

### Escolha: **A preferida; B só com evidência de inviabilidade**

| Peça | Escolha nesta etapa |
|------|---------------------|
| Objetivo | Veredito limpo no comparable (sem reason proxy / `no_gguf_*` legado / subset-espécie E44) |
| Espécie preferida | 22L + `n_predict=32` + prompt canônico + `ACCEL=cpu` |
| Sucesso forte | `VERDICT` ∈ {COMPROVA, REFUTA, INCONCLUSIVO} por margem R; reason de margem/empate — **não** subset |
| Sucesso parcial | Máximo N layers/pos/`n_predict` viável + métricas reais; se ainda ≠ canônica → reason **E45** de teto (ADR), **não** `E44_subset_*` |
| Quiet | Protocolo [`harness-corrida-quieta.md`](../../docs/harness-corrida-quieta.md) intacto |
| ADR | **0016** (sugerido): veredito limpo; critério canônico vs teto; proibições |
| Hipótese | **Proibido** forçar `COMPROVA` |

### Definição de “veredito limpo” (contrato)

Um veredito é **limpo** se **todas** forem verdadeiras:

1. B gera de fato (`LOAD_KIND=gguf`, `TOKENS_PER_S` medidos no guest).
2. `VERDICT` ∈ {`COMPROVA`, `REFUTA`, `INCONCLUSIVO`}.
3. `VERDICT_REASON` **não** contém: proxy / `E44_b_proxy*` / `no_gguf_full_prefill` / `no_gguf_prefill_22l` / legado E33 / `E44_subset_generate_not_canonical_species*`.
4. Se espécie = canônica (22L + n_predict=32): reason é margem/empate/parse — checklist de espécie ok.
5. Se espécie &lt; canônica: reason **somente** o identificador ADR de teto (ex. `E45_perf_ceiling_below_canonical`) **e** o ADR afirma que aquele N é o máximo honesto exercitado no gate — docs de comparable atualizados para aceitar **só** esse caso.

### Critério de “inviável” (cair em B)

Só **depois** de:

1. Contrato ADR 0016 + definição de veredito limpo (Task 1), **e**
2. Tentativa documentada de expandir espécie / otimizar custo (Task 2) com medição, **e**
3. Evidência de timeout/perf/correção que impede 22L×32 no gate (mesmo com release + timeout documentado uma vez).

**Não** é inviável: pular expansão; manter 2L×1 sem tentativa; emitir reason subset “porque é mais fácil”.

### Rejeitado (explícito)

- Inventar `TOKENS_PER_S` / forçar `COMPROVA`.
- Aceitar `E44_subset_*` / proxy / `no_gguf_*` legado como “limpo”.
- Contar host `ia-livre-runtime` como evidência B.
- Quebrar protocolo quieto (corridas concorrentes sem `QUIET`).
- GPU guest; bare-metal; alterar carga canônica da Linha A.

## Fora de escopo

- Nova stack de inferência / llama.cpp no kernel
- Metal / USB / ESP além do path QEMU
- Node, agent, multi-GPU nativo
- Mudar checklist de margem R (1.05 / 0.95) salvo correção documental mínima
- Provar hipótese por narrativa sem métricas

## Critérios de aceite

- [ ] ADR 0016 (+ docs): preferência canônica; fallback teto E45; definição de veredito limpo; proibições
- [ ] Espécie B expandida ao máximo viável **ou** 22L×32 alcançado; evidência registrada
- [ ] `make verify-harness-comparable`: B gerando; `VERDICT` ∈ {COMPROVA, REFUTA, INCONCLUSIVO}; reason **limpo** (margem ou `E45_perf_ceiling_*` ADR-only)
- [ ] Reasons proxy / `no_gguf_full_prefill` / subset-espécie E44 **ausentes** no caminho de sucesso desta etapa
- [ ] Metodologia quieta preservada (`harness-corrida-quieta` + scripts)
- [ ] `AGENTS.md` cobre o desfecho; README avaliado (`readme-por-fatia`)
- [ ] Pronto para marcar Etapa 45 `feita` após gate + revisor

## Riscos e rollback

- **Risco:** 22L×32 impossível no QEMU mesmo com release — Task 2 maximiza N; Task 3/4 reason E45 + docs.
- **Risco:** pressão por `COMPROVA` → margem R + proibição explícita.
- **Risco:** “veredito limpo” ambíguo → ADR lista reasons permitidos vs proibidos.
- **Rollback:** restaurar comparable E44 (`E44_subset_*`); ADR/docs da tentativa E45 permanecem.

## Etapa do roadmap

- **Etapa 45** — Re-corrida harness A vs B com geração real (veredito limpo) (`em_andamento`)
- Issue: [#45](https://github.com/eriksonlima/projeto-ia-livre/issues/45) (ex-B39)
- Spec: `specs/recorrida-harness-veredito-limpo/`
- Pronto quando: `make verify-harness-comparable` com B gerando; veredito ∈ {COMPROVA, REFUTA, INCONCLUSIVO} **sem** reason de proxy / `no_gguf_full_prefill` / subset-espécie; metodologia quieta preservada.

> **Desfecho preferido:** espécie 22L + n_predict=32; veredito por margem; reason limpo.  
> **Desfecho aceitável:** máximo viável documentado **ou** `INCONCLUSIVO` + `E45_perf_ceiling_below_canonical` (ADR) — cumpre “veredito limpo” **sem** fraude nem reason legado/subset.
