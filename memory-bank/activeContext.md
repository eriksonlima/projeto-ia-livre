# Active context

## Foco atual

- **Etapa 20** — Runtime falando o contrato nativo (B14) — Task 4 concluída; fechando etapa
- Issue [#20](https://github.com/eriksonlima/projeto-ia-livre/issues/20)
- Spec: `specs/runtime-contrato-nativo/` (Tasks 1–4 feitas)

## Mudanças recentes

- Task 4: harness B observa `MEM_SCHED_*`/`TYPED_*`, reemite `HARNESS_CONTRACT_*`, preserva proxy
- Gates: `make verify`, `make verify-runtime-contract`, `make verify-harness` OK
- Hipótese **não** comprovada

## Próximo passo

- Marcar Etapa 20 `feita`, liberar lease, merge em `main`; não duplicar promoções B15+ (paralelo)

## Notas

- Shim host ≠ Linha B; B = proxy + evidência contrato; sem `TOKENS_PER_S`
