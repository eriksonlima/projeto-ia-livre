# Active context

## Foco atual

- **Etapa 21** `em_andamento` → fechando — Carga GGUF canônica na Linha B (mínimo honesto)
- Issue [#21](https://github.com/eriksonlima/projeto-ia-livre/issues/21); Project: https://github.com/users/eriksonlima/projects/1
- Spec: `specs/carga-gguf-linha-b/`
- Branch: `etapa-b15-gguf-linha-b` (mergeada com `origin/main` pós E19/E20)
- Lease: `cursor-agent-principal` em `AGENT_CLAIM.md` (E21)

## Mudanças recentes

- Claim E21 + status `em_andamento` no ROADMAP/GitHub
- Tasks 3–4: `CONTRACT_READY=1` + alvos `GGUF_TARGET_*` + bloqueio final `B_BLOCK=no_gguf_path`
- Gates: `make verify` + `make verify-harness` OK (sem inventar TOKENS_PER_S; hipótese não comprovada)

## Próximo passo

- Marcar Etapa 21 `feita`, liberar lease, mergear branch em main
- Em seguida Etapa 22 (B16 harness comparável) se coerente — branch `etapa-b16-harness-comparavel`

## Notas

- Desfecho E21 = **bloqueio honesto** (não carga GGUF real)
- Proxy E12 permanece instrumento mínimo do harness B
- Não claimar Etapas 23–25 em paralelo com a mesma `em_andamento`
