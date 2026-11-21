# Spec — Bloqueio final documentado da hipótese A/B

## Resultado visível

**Bloqueio terminal** da hipótese de pesquisa Linha A vs Linha B no **gate atual**, documentado em ADR/doc: espécie canônica e o caminho guest pós-E59/E60 são **terminalmente** inviáveis **ou** há **critérios explícitos de reabertura** — e o instrumento comparable permanece **honesto** (`INCONCLUSIVO` / reason de teto ou reason terminal), **sem** `COMPROVA` fingido.

O **pilar 1** do checklist E58 (`docs/prototipo-objetivo-atingido.md`) passa a refletir esse desfecho: “atingido” via **bloqueio final documentado** (não via vitória da hipótese). Glossário, product-context e notas do comparable/harness alinham a linguagem **operacional** (ADR 0020/0021) vs **terminal** (esta etapa).

Esta etapa **não** expande espécie no guest, **não** inventa `TOKENS_PER_S` e **não** prova nem refuta a hipótese por métrica.

## Contexto fixo (não reinventar)

- **E59 / ADR [`0020`](../../docs/adr/0020-runtime-native-passo-intermediario-inviavel.md):** passo intermediário **N≥8** inviável no guest QEMU (timeout) após ~7–10% — **teto operacional**, não fechamento da hipótese.
- **E60 / ADR [`0021`](../../docs/adr/0021-especie-canonica-linha-b-inviavel.md):** 22L×32 inviável no gate atual; comparable `INCONCLUSIVO`/teto; hipótese **aberta** até **B58** (= esta etapa).
- **E58:** checklist dos 3 pilares; pilar 1 “atingido” = `COMPROVA`/`REFUTA` canônico **ou** bloqueio honesto **final** documentado.
- **ADR [`0016`](../../docs/adr/0016-veredito-limpo-harness-a-b.md):** teto 2L×1; `COMPROVA`/`REFUTA` só com espécie = A.
- **Contratos:** [`docs/prototipo-objetivo-atingido.md`](../../docs/prototipo-objetivo-atingido.md), [`docs/harness-a-b-comparavel.md`](../../docs/harness-a-b-comparavel.md), [`docs/runtime-native-perf-especie.md`](../../docs/runtime-native-perf-especie.md).
- **Backlog:** esta etapa = **B58** promovida → Etapa 61 · Issue [#64](https://github.com/eriksonlima/projeto-ia-livre/issues/64).
- **Proibido:** inventar tokens; `COMPROVA` com subset; fingir 22L×32; host-as-B; expandir espécie guest “para fechar”; celebrar hipótese comprovada.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A — ADR 0022 terminal + reabertura** | Nova ADR **0022** distingue inviabilidade **operacional** (0020/0021) de **bloqueio terminal** do pilar 1 no gate atual; lista critérios explícitos que **reabrem** a hipótese (caminho novo de perf / mudança de methodology documentada); checklist pilar 1 → atingido via bloqueio final; comparable honesto | **Escolhida (desfecho esperado)** |
| **B — Só estender 0021** | Acrescentar “terminal” em 0021 sem ADR nova | **Aceitável só se** a distinção operacional vs terminal ficar inequívoca; preferir **0022** para não misturar “canônico inviável no gate” com “pilar 1 fechado” |
| **C — Caminho reaberto sem fechar** | Documentar só critérios de reabertura **sem** declarar bloqueio terminal do pilar 1 | **Só se** Task 1 identificar caminho novo concreto **já** em curso; caso contrário **não** cumpre o Pronto quando do ROADMAP |
| **D — Fraude** | Emitir `COMPROVA`; remover reason de teto; expandir espécie no guest sem caber; celebrar hipótese | **Rejeitada** |

### Escolha: **A (esperado); B só se 0022 for redundante; C só com caminho novo real**

| Peça | Escolha nesta etapa |
|------|---------------------|
| ADR | Preferir **`docs/adr/0022-*.md`** — bloqueio **terminal** do pilar 1 / hipótese no gate atual; ponte 0020+0021+0016; **critérios de reabertura** explícitos |
| Checklist E58 | Pilar 1: estado = **bloqueio final documentado** (atingido via bloqueio, **não** via COMPROVA/REFUTA) |
| Instrumento | Comparable permanece `INCONCLUSIVO` + reason de teto **ou** reason terminal documentado; **proibido** COMPROVA |
| Reabertura | Critérios mínimos (ex.): SIMD/GPU guest efetivo **ou** redesign freestanding com evidência de 22L×32 no timeout **ou** mudança documentada de methodology/timeout + nova etapa — **não** “mais 10%” no mesmo hot path |
| Hipótese de pesquisa | **Não** comprovada nem refutada por métrica; **fechada no pilar 1** como bloqueio terminal **até** reabertura |
| Alinhamento ROADMAP | Cumpre “terminalmente inviável **ou** caminho reaberto explícito” via A (terminal + critérios) |

### Critério de “bloqueio terminal” (cair em A)

Só com:

1. ADR **0022** (ou extensão inequívoca de 0021 se B) que declare: inviabilidade **não** é só teto operacional — o **pilar 1** do checklist fecha por bloqueio final no gate atual, **e**
2. Tabela/ponte 0020 (N≥8) → 0021 (canônico) → 0022 (terminal pilar 1), **e**
3. Critérios de **reabertura** listados (sem os quais a hipótese permanece fechada no checklist), **e**
4. Checklist + glossário + comparable/product-context alinhados; gate documental confere; **sem** COMPROVA.

**Não** é A válido: só repetir 0021 sem marcar pilar 1; fingir COMPROVA; expandir guest.

### Critério de “caminho reaberto” (C — raro)

Só se Task 1 documentar **caminho novo concreto** (mesma barra de E60) **e** o ROADMAP/checklist deixarem explícito que o bloqueio terminal **não** se aplica ainda — com critérios e próxima etapa. Sem evidência de caminho novo → **A**.

### Rejeitado (explícito)

- Inventar `TOKENS_PER_S` / forçar `COMPROVA` / declarar hipótese **comprovada** ou **refutada por margem R**.
- Contar host / E59 microbench como prova A vs B.
- Expandir espécie guest (22L×32) sem caber no timeout.
- METAL_OK, USB, GPU guest completo, node, agent (exceto menção documental).
- Tratar 0020/0021 sozinhas como se o pilar 1 já estivesse “atingido” sem ADR/docs de E61.

## Fora de escopo

- Implementar SIMD/GPU guest / redesign do motor (só critérios de reabertura)
- Expandir espécie no guest / re-corrida quieta decisiva (B55)
- METAL_OK / USB / bare-metal físico
- Node, agent, bridges (exceto ponte documental)
- Mudar margem R do comparable para facilitar COMPROVA
- Celebrar “protótipo objetivo atingido” global (pilares 2/3 independentes; só pilar 1 fecha aqui)

## Critérios de aceite

- [ ] ADR **0022** (preferida) **ou** extensão inequívoca de 0021: bloqueio **terminal** vs operacional + critérios de reabertura + ponte 0020/0021
- [ ] `docs/prototipo-objetivo-atingido.md` pilar 1 atualizado (atingido via bloqueio final); glossário + product-context + comparable/harness notes
- [ ] Instrumento comparable honesto: sem `COMPROVA` fingido; reason teto/terminal documentado
- [ ] Gate documental estendido (`verify-prototipo-objetivo` e/ou `verify-runtime-native-perf`) + `AGENTS.md`; README avaliado
- [ ] Pronto para marcar Etapa 61 `feita` após gate + revisor — **sem** fraude

## Riscos e rollback

- **Risco:** confundir “inviável no gate” (0021) com “pilar 1 atingido” sem ADR terminal → exigir 0022 (ou texto inequívoco) + checklist.
- **Risco:** pressão por COMPROVA para “fechar pesquisa” → **proibido**; fechar via bloqueio.
- **Risco:** reabertura vaga (“quando melhorar”) → critérios concretos e auditáveis.
- **Rollback:** manter 0020/0021 e INCONCLUSIVO/teto; docs E61 da decisão permanecem se A.

## Etapa do roadmap

- **Etapa 61** — Bloqueio final documentado da hipótese A/B (`em_andamento`)
- Issue: [#64](https://github.com/eriksonlima/projeto-ia-livre/issues/64) (ex-B58)
- Spec: `specs/bloqueio-final-hipotese-ab/`
- Pronto quando: ADR/doc declara espécie/hipótese **terminalmente** inviável no gate atual (ou caminho reaberto explícito); instrumento comparable honesto; checklist E58 pilar 1 atualizado; sem fingir COMPROVA.

> **Desfecho preferido (A):** ADR 0022 + pilar 1 atingido via bloqueio final + reabertura explícita + comparable honesto.  
> **Desfecho raro (C):** caminho reaberto documentado sem fechar terminal — só com evidência de caminho novo.
