# Tasks — Harness A vs B comparável (prova ou refutação da hipótese)

Uma task = uma fatia. Ordem: 1 → 2 → 3.

- [x] Task 1 — Metodologia comparável + critérios de veredito (doc)
  - **Objetivo:** Documentar pré-condição de comparabilidade A/B, critérios `COMPROVA` / `REFUTA` / `INCONCLUSIVO` + limites, marcadores `VERDICT`/`VERDICT_REASON` e proibições (sem métricas falsas; sem tratar proxy como prova).
  - **Fora de escopo:** Script/gate; carga GGUF em B; editar `kernel/` / Etapa 19; GPU manager; marcar Etapa 22 `feita`.
  - **Pronto quando:** `docs/harness-a-b-comparavel.md` (ou equivalente inequívoco) cobre o conteúdo acima; ponte em `docs/harness-linha-a-b.md`; README avaliado (`readme-por-fatia`).

- [x] Task 2 — Script de corrida A vs B + relatório honesto
  - **Objetivo:** Orquestrar Linha A + Linha B e emitir relatório com veredito + reason, honesto com B proxy ou B GGUF quando existir.
  - **Fora de escopo:** Gate `verify-harness-comparable`; implementar GGUF em B (só consumir B15); inventar `TOKENS_PER_S` / equivalência PROXY↔tokens; editar `kernel/`.
  - **Pronto quando:** script documentado (ex. `scripts/run-harness-a-b-comparable.sh`) roda A e B, emite `IA_LIVRE_HARNESS_VERDICT=` + `VERDICT_REASON=`; com B proxy → `INCONCLUSIVO` obrigatório; com B GGUF comparável aplica critério da Task 1; Como rodar parcial/completo em `AGENTS.md`; README reavaliado.

- [x] Task 3 — Gate/verify documentado + pontes AGENTS/README
  - **Objetivo:** Gate verificável do instrumento comparável + pontes finais em `AGENTS.md` / docs / README.
  - **Fora de escopo:** Reescrever metodologia da Task 1; implementar B14/B15; editar `kernel/` / `AGENT_CLAIM` / Etapa 19; marcar ROADMAP Etapa 22 `feita` (agente principal após gate + revisor).
  - **Pronto quando:** `make verify-harness-comparable` (ou extensão documentada equivalente) exige veredito ∈ {COMPROVA, REFUTA, INCONCLUSIVO} + reason; passa com `INCONCLUSIVO` honesto se B=proxy; falha se `COMPROVA` sem comparabilidade ou tokens inventados em proxy; timeout documentado; `AGENTS.md` cobre verificar; `make verify-harness` v1 não regride; README reavaliado.
