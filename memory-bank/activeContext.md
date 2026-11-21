# Active context

## Foco atual

- **Etapa 22** `em_andamento` — Harness A vs B comparável (prova ou refutação)
- Issue [#22](https://github.com/eriksonlima/projeto-ia-livre/issues/22)
- Spec: `specs/harness-a-b-comparavel/`
- Branch/worktree: `etapa-b16-harness-comparavel` / `projeto-ia-livre-b16`
- Lease: `cursor-agent-principal` (E22)

## Mudanças recentes

- E21 feita (bloqueio `no_gguf_path`); merge main → b16 em andamento
- Tasks 1–3 da E22 já existiam na branch; validar gate pós-merge

## Próximo passo

- Resolver merge; `make verify-harness` + `make verify-harness-comparable`
- Fechar E22 se veredito INCONCLUSIVO honesto (B=proxy) cumprir Pronto quando

## Notas

- Com B=proxy / `no_gguf_path`, veredito deve ser INCONCLUSIVO — não COMPROVA/REFUTA
- Não claimar 23–25
