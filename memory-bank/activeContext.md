# Active context

## Foco atual

- **Etapa 19** `em_andamento` — Memória model-aware + scheduler por fases (impl. mínima)
- Issue [#19](https://github.com/eriksonlima/projeto-ia-livre/issues/19); Project: https://github.com/users/eriksonlima/projects/1
- Spec alvo: `specs/memoria-scheduler-impl-minima/` (a gerar)
- Lease: `cursor-agent-principal` em `AGENT_CLAIM.md`

## Mudanças recentes

- Promovido B13 → Etapa 19 (promoção autônoma após “continuar”)
- Labels issue #19: `roadmap` + `status:em_andamento` (removido `backlog`); item no Project V2

## Próximo passo

- Especificar + fatiar Etapa 19; implementar tasks uma a uma com gate `make verify`

## Notas

- Sem GGUF; sem prova da hipótese; sem ABI estável/multi-tenant/GPU manager
- ADR 0003 + `docs/desenho-memoria-scheduler-nativo.md`

## Paralelo (esta branch)

- **Etapa 22** `pendente` — B16 Harness A vs B comparável (Issue #22)
- Branch/worktree: `etapa-b16-harness-comparavel` / `projeto-ia-livre-b16`
- Spec: `specs/harness-a-b-comparavel/` (tasks 1–3 feitas)
- Gate: `make verify-harness-comparable` → `VERDICT=INCONCLUSIVO` (B ainda proxy; aguarda B15)
- **Não** claimou lease da Etapa 19; **não** promoveu a `em_andamento`

