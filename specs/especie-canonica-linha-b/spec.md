# Spec — Espécie canônica Linha B (22L × n_predict=32)

## Resultado visível

**Espécie canônica na Linha B** (`PREFILL_LAYERS=22` × `N_PREDICT=32`) no instrumento `make verify-harness-comparable`, com veredito ∈ {`COMPROVA`,`REFUTA`,`INCONCLUSIVO`} **sem** reason de teto/subset — **ou**, se não houver **caminho novo** de perf que desbloqueie o guest no timeout, **ADR nova (0021)** declarando espécie canônica **inviável no gate atual**, comparable permanece `INCONCLUSIVO`/teto, **sem** emitir `COMPROVA`, com ponte explícita para **B58** (bloqueio final da hipótese).

Esta etapa **não** inventa `TOKENS_PER_S`, **não** conta host como B e **não** relaxa o Pronto quando com fraude.

## Contexto fixo (não reinventar)

- **E59 / ADR [`0020`](../../docs/adr/0020-runtime-native-passo-intermediario-inviavel.md):** passo intermediário **N≥8** (e, por extrapolação, `n_predict`≥8 e **22L×32**) **já inviável** no guest QEMU **600 s** após otimização ~7–10% (fused matvec). Ganho ≪ ordem de magnitude.
- **ADR [`0016`](../../docs/adr/0016-veredito-limpo-harness-a-b.md):** teto operacional 2L × `n_predict=1`; reason limpo `E45_perf_ceiling_below_canonical_*`; `COMPROVA`/`REFUTA` só com espécie = A.
- **E44/E45:** Decode + `TOKENS_PER_S` medidos no guest; espécie subset; comparable `INCONCLUSIVO`.
- **Contratos:** [`docs/runtime-native-perf-especie.md`](../../docs/runtime-native-perf-especie.md), [`docs/harness-a-b-comparavel.md`](../../docs/harness-a-b-comparavel.md), [`docs/runtime-nativo-linha-b.md`](../../docs/runtime-nativo-linha-b.md).
- **Backlog:** esta etapa = **B54**; se canônico continuar inviável → ponte **B58** (bloqueio final documentado da hipótese) — **fora** desta etapa além da ponte documental.
- **Proibido:** inventar tokens; `COMPROVA` com subset; fingir 22L×32; host-as-B; METAL_OK / GPU guest completo / node / agent.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A — Caminho novo → canônico no comparable** | Novo caminho de perf (ex.: SIMD guest real, GPU guest, outro desenho) que faça **22L×32** caber no timeout; `verify-harness-comparable` com B canônico + veredito sem reason de teto/subset | **Só se houver caminho novo concreto** — **irrealista** reaproveitando só o ganho E59 (~7–10%) |
| **B — Inviável canônico honesto** | Sem caminho novo nesta fatia: ADR **0021** declara 22L×32 inviável no gate atual (ancora em 0020/0016); comparable **permanece** `INCONCLUSIVO` + reason de teto; **não** emite `COMPROVA`; ponte B58; **não** afrouxa o Pronto quando inventando espécie | **Desfecho esperado / aceitável** |
| **C — Fraude** | Forçar 22L×32 no gate sem caber; inventar tokens; `COMPROVA` com subset; remover reason de teto sem evidência; contar host como B | **Rejeitada** |

### Escolha: **B esperado; A só com caminho novo**

Dado ADR 0020, **não** se espera cumprir A com mais micro-otimização do mesmo hot path. A só entra se a Task 1 identificar e a implementação trouxer um **caminho qualitativamente novo** (não “mais 10%”).

| Peça | Escolha nesta etapa |
|------|---------------------|
| Alvo A | B guest `PREFILL_LAYERS=22` + `N_PREDICT=32` + `LOAD_KIND=gguf` + `TOKENS_PER_S` medidos; comparable sem reason teto/subset |
| Sucesso A | `make verify-harness-comparable` verde com espécie canônica em B; veredito ∈ {COMPROVA,REFUTA,INCONCLUSIVO} por **margem R**, não por teto |
| Sucesso B | ADR **0021** + doc/ponte: canônico inviável no gate atual; ADR 0020 permanece; comparable ainda INCONCLUSIVO/teto; **proibido** COMPROVA; ponte B58 |
| Alinhamento ROADMAP | “ADR 0020 permanece se inviável sem novo caminho” = autoriza desfecho B; preferir **ADR 0021** (canônico) além de 0020 (passo intermediário) para não misturar decisões |
| Hipótese global | **Aberta** após B; fechamento terminal só via **B58** (fora desta etapa) |

### Critério de “caminho novo” (só então A)

Cumpre A somente se **pelo menos um** for verdadeiro com evidência **no guest** (não só host):

1. Técnica **nova** vs E59 (ex. SIMD/vetorização guest efetiva, offload GPU guest, redesign que mude ordem de magnitude), **e**
2. Medição mostrando 22L×32 (ou progresso que **prove** caber 22L×32) **dentro** do timeout do gate comparable/harness B, **e**
3. Comparable emite espécie canônica em B **sem** reason de teto/subset.

> Reafirmar ADR 0020 sem ADR canônica **não** fecha E60. Inventar espécie **não** fecha. Ampliar N no kernel sem caber no timeout **não** fecha.

### Critério de “inviável canônico” (cair em B)

Só com:

1. Task 1: decisão documentada de que **não** há caminho novo nesta fatia (ou tentativa A falhou), ancorada em ADR 0020 + extrapolação 22L×32, **e**
2. Task 2: ADR **0021** com tabela de evidência (herda E59/0020; deixa explícito que canônico é **mais** difícil que N≥8), **e**
3. Docs/AGENTS/comparable: hipótese aberta; reason de teto **permanece**; ponte B58; sem COMPROVA.

**Não** é B válido: remover reason de teto “para passar o Pronto quando”; marcar etapa feita fingindo A; declarar hipótese terminalmente fechada (isso é B58).

### Rejeitado (explícito)

- Inventar `TOKENS_PER_S` / forçar `COMPROVA` / declarar hipótese comprovada ou **terminalmente** refutada nesta etapa.
- Contar Linha A / host `ia-livre-runtime` / microbench host E59 como evidência de B guest canônico.
- METAL_OK, USB, GPU guest completo, node, agent.
- Relaxar espécie A (n_predict/layers) para “facilitar” o par.
- Tratar ADR 0020 sozinha como se já fosse “espécie canônica resolvida” sem ADR/docs de E60.

## Fora de escopo

- **B58** — bloqueio final da hipótese (só ponte documental aqui)
- METAL_OK / USB / bare-metal físico
- GPU guest completo / multi-GPU nativo / accel simétrica A↔B
- Node, agent, bridges (exceto menção documental)
- Nova stack llama.cpp no kernel
- Mudar checklist de margem R do comparable (salvo se A realmente comparar canônico)

## Critérios de aceite

- [ ] Decisão A vs B documentada (contrato E60); sem caminho novo → caminho B explícito
- [ ] **A:** comparable com B 22L×32 sem reason teto/subset **ou** **B:** ADR 0021 inviável canônico + 0020 permanece + comparable INCONCLUSIVO/teto + ponte B58
- [ ] Sem `TOKENS_PER_S` inventado; sem `COMPROVA` fingido
- [ ] `AGENTS.md` / docs / glossário atualizados conforme desfecho; README avaliado (`readme-por-fatia`)
- [ ] Pronto para marcar Etapa 60 `feita` após gate da fatia + revisor — **sem** fraude no Pronto quando

## Riscos e rollback

- **Risco:** pressão por cumprir “sem reason de teto” sem caber 22L×32 → **proibido**; desfecho B + ADR 0021.
- **Risco:** confundir inviável E60 com bloqueio final B58 → ponte clara; hipótese permanece aberta até B58.
- **Risco:** tentar “mais um fused” como se fosse caminho novo → rejeitar; exige ordem de magnitude / técnica nova.
- **Rollback:** manter teto 2L×1 e ADR 0020; docs/ADR 0021 da decisão permanecem se B.

## Etapa do roadmap

- **Etapa 60** — Espécie canônica Linha B (22L × n_predict=32) (`em_andamento`)
- Issue: [#60](https://github.com/eriksonlima/projeto-ia-livre/issues/60) (ex-B54)
- Spec: `specs/especie-canonica-linha-b/`
- Pronto quando: `make verify-harness-comparable` com B `PREFILL_LAYERS=22` + `N_PREDICT=32` + veredito ∈ {COMPROVA,REFUTA,INCONCLUSIVO} **sem** reason de teto/subset; sem fingir COMPROVA; ADR 0020 permanece se inviável sem novo caminho.

> **Desfecho preferido (A):** canônico no comparable sem reason de teto — só com caminho novo.  
> **Desfecho aceitável (B, esperado):** ADR 0021 + comparable ainda INCONCLUSIVO/teto + ponte B58 — etapa cumprida **honestamente** sem fraude nem COMPROVA.
