# Spec — Otimizar runtime-native (SIMD/teto) para espécie canônica

## Resultado visível

**Progresso de performance honesto** no motor Linha B (`runtime-native/`): medição documentada do teto atual (subset E44: **2L × `n_predict=1`**) versus um **passo intermediário** (`PREFILL_LAYERS`/`N` ≥ **8** e/ou `n_predict` ≥ **8**) **ou** espécie canônica (**22L × `n_predict=32`**) **dentro do timeout do gate** — **ou**, após tentativa de otimização, **ADR nova** que declare inviável com evidência.

Esta etapa **desbloqueia / mede** o caminho até a espécie canônica; **não** fecha B54 nem muda o comparable para `COMPROVA` com subset.

## Contexto fixo (não reinventar)

- **ADR [`0016`](../../docs/adr/0016-veredito-limpo-harness-a-b.md):** 22L×32 inviável no gate **600 s** sem otimização de **ordem de magnitude**; teto operacional pós-E45 = subset documentado; reason limpo de teto `E45_perf_ceiling_below_canonical`.
- **E44:** Decode greedy + `TOKENS_PER_S` **medidos** no guest QEMU; espécie **2L × n_predict=1**; `LOAD_KIND=gguf`; comparable `INCONCLUSIVO` / subset-espécie (ou E45 teto).
- **Motor:** `runtime-native/` (`attn`, `ffn`, `kv`, `decode`); kernel = glue/serial; perfil release (`IA_LIVRE_KERNEL_PROFILE=release`).
- **ADRs relacionados:** [`0014`](../../docs/adr/0014-prefill-22l-kv-linha-b.md), [`0015`](../../docs/adr/0015-decode-tokens-linha-b.md), [`0010`](../../docs/adr/0010-runtime-nativo-freestanding-linha-b.md) / [`0001`](../../docs/adr/0001-separacao-camadas-e-p2p.md).
- **Contratos:** [`docs/runtime-nativo-linha-b.md`](../../docs/runtime-nativo-linha-b.md), [`docs/harness-a-b-comparavel.md`](../../docs/harness-a-b-comparavel.md).
- **Backlog destino:** **B54** = espécie canônica no comparable (COMPROVA/REFUTA possíveis) — **fora** desta etapa.
- **Proibido:** inventar `TOKENS_PER_S`; fingir `COMPROVA`; declarar hipótese comprovada; host-as-B como prova de guest.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A — Otimizar + passo intermediário (ou canônico)** | Baseline medido → otimização concreta (SIMD / unroll / quant path / matvec / etc.) → evidência de ganho → gate prova N≥8 / `n_predict`≥8 **ou** 22L×32 no timeout | **Preferida** |
| **B — Inviável pós-otimização** | Após tentativa documentada + medição: ADR nova declara que o passo intermediário (e/ou canônico) permanece inviável no gate; hipótese **aberta** até B54 | **Fallback aceitável** |
| **C — Fraude** | Inventar métricas; fingir COMPROVA; declarar hipótese fechada; pular otimização sem medição; contar host como B | **Rejeitada** |

### Escolha: **A preferida; B só com evidência pós-otimização**

| Peça | Escolha nesta etapa |
|------|---------------------|
| Onde | `runtime-native/` (hot path Prefill/Decode/Q4_K/matvec); kernel só se glue/marcadores |
| Baseline | Documentar tempo/espécie atual (host unitário e/ou QEMU release) — teto 2L×1 |
| Alvo mínimo de progresso | Passo intermediário: **N≥8 layers** **e/ou** **`n_predict`≥8** com geração real + métricas medidas **no timeout do gate** |
| Alvo forte (opcional) | 22L × `n_predict=32` no mesmo timeout — desbloqueia caminho B54, **sem** exigir veredito COMPROVA aqui |
| Otimizações candidatas | SIMD (alvo host/`x86_64` onde aplicável), unroll, dequant Q4_K mais barato, matvec, reduzir cópias, flags release já existentes |
| Sucesso A | Medição antes/depois + gate/marcadores do passo intermediário (ou canônico) |
| Sucesso B | ADR **0020** (sugerido) pós-otimização: inviável com tabela de evidência; **sem** inventar ganho |
| Comparable / hipótese | Permanece **INCONCLUSIVO** / aberta até B54; **proibido** COMPROVA com subset |
| ADR contrato etapa | Doc de medição + ADR 0020 **ou** extensão documentada de 0016 apontando E59 (preferir ADR nova se inviável; se A ok, doc contrato + ponte 0016 basta) |

### Definição de “passo intermediário” (contrato)

Cumpre o Pronto quando da etapa se **pelo menos um** for verdadeiro **com evidência**:

1. **Progresso medido no gate:** guest (preferido) ou harness B emite espécie com `PREFILL_LAYERS`/`N` ≥ **8** **ou** `N_PREDICT`/`n_predict` ≥ **8**, com `LOAD_KIND=gguf` e `TOKENS_PER_S` **medidos** (loop real), **dentro** do timeout configurado do gate usado na prova; **ou**
2. **Canônico no timeout:** 22L × `n_predict=32` no mesmo sentido; **ou**
3. **Inviável honesto:** ADR nova pós-otimização declara inviável o passo (1) e/ou (2) com medições (baseline + tentativa + teto residual).

> Ampliar só docs sem medição **não** conta. Ampliar N sem otimização tentada/medida **não** conta como desfecho B.

### Critério de “inviável” (cair em B)

Só **depois** de:

1. Baseline + alvo documentados (Task 1), **e**
2. Tentativa concreta de otimização em `runtime-native` com evidência (Task 2) — ganho medido **ou** tentativa honesta sem ganho suficiente, **e**
3. Gate/ADR (Task 3) registrando que N≥8 / `n_predict`≥8 (e 22L×32 se tentado) **não** cabem no timeout após a tentativa.

**Não** é inviável: pular SIMD/otimização; só reafirmar ADR 0016 sem nova evidência; inventar “ordem de magnitude” sem números.

### Rejeitado (explícito)

- Inventar `TOKENS_PER_S` / forçar `COMPROVA` / declarar hipótese comprovada.
- Mudar veredito comparable para COMPROVA/REFUTA com espécie ainda ≠ canônica.
- Contar Linha A / host `ia-livre-runtime` como evidência de B guest.
- GPU guest / accel simétrica; METAL_OK / USB; B54 completo nesta etapa.
- Alterar carga canônica da Linha A para “facilitar” B.

## Fora de escopo

- **B54** — espécie canônica no comparable com COMPROVA/REFUTA por margem
- METAL_OK / USB / bare-metal físico
- GPU guest / multi-GPU nativo / accel simétrica A↔B
- Node, agent, bridges (exceto menção documental se marcadores mudarem)
- Mudar checklist de margem R do comparable
- Nova stack (llama.cpp no kernel)

## Critérios de aceite

- [ ] Doc de medição (baseline teto 2L×1 vs alvo intermediário/canônico) + ponte ADR 0016 / contrato E59
- [ ] Otimização concreta em `runtime-native` com evidência de ganho **ou** tentativa honesta documentada (antes/depois)
- [ ] Gate/marcadores: prova N≥8 e/ou `n_predict`≥8 (ou 22L×32) no timeout **ou** ADR nova de inviável pós-otimização
- [ ] Sem `TOKENS_PER_S` inventado; sem `COMPROVA` fingido; hipótese permanece aberta até B54
- [ ] `AGENTS.md` / `Makefile` atualizados se houver gate novo ou extensão; README avaliado (`readme-por-fatia`)
- [ ] Pronto para marcar Etapa 59 `feita` após gate + revisor

## Riscos e rollback

- **Risco:** SIMD freestanding/UEFI limitado → medir em host `cargo test` + guest release; documentar assimetria.
- **Risco:** ganho &lt; ordem de magnitude → desfecho B (ADR inviável) ainda cumpre a etapa.
- **Risco:** pressão por COMPROVA → proibição explícita; comparable permanece INCONCLUSIVO até B54.
- **Rollback:** restaurar teto 2L×1 nos gates; docs/ADR da tentativa permanecem.

## Etapa do roadmap

- **Etapa 59** — Otimizar runtime-native (SIMD/teto) para espécie canônica (`em_andamento`)
- Issue: [#59](https://github.com/eriksonlima/projeto-ia-livre/issues/59) (ex-B53)
- Spec: `specs/otimizar-runtime-native-especie/`
- Pronto quando: medição documentada (passo intermediário N≥8 / `n_predict`≥8 **ou** 22L×32 no timeout do gate) **ou** ADR nova pós-otimização declara inviável com evidência; sem fingir `COMPROVA`; hipótese permanece aberta até B54.

> **Desfecho preferido:** passo N≥8 e/ou `n_predict`≥8 (ou canônico) medido no gate após otimização.  
> **Desfecho aceitável:** ADR pós-otimização com inviável evidenciado — etapa cumprida **sem** fraude nem B54 prematuro.
