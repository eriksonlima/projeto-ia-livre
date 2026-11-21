# Active context

## Foco atual

- **Etapa 19** `em_andamento` — Memória model-aware + scheduler por fases (impl. mínima) — **outro agente** (`cursor-agent-principal` no lease); **não** editar aqui
- **Etapa 20** `pendente` — Runtime falando o contrato nativo (B14) — branch `etapa-b14-runtime-contrato` / worktree `projeto-ia-livre-b14`
- Issue [#20](https://github.com/eriksonlima/projeto-ia-livre/issues/20); Spec: `specs/runtime-contrato-nativo/`
- Lease global **não** claimado por B14 (ocupado pela E19)

## Mudanças recentes (Etapa 20 / esta branch)

- Promovido B14 → Etapa 20 `pendente` (não segunda `em_andamento`)
- Spec + Tasks 1–3 feitas: docs + shim host `runtime-contract/` + gate `verify-runtime-contract`
- Task 4 bloqueada até E19 mergear contrato no kernel

## Próximo passo

- Aguardar E19 `feita`/merge → desbloquear Task 4 (QEMU + `MEM_SCHED_OK`/`TYPED_*`)
- Só então considerar subir Etapa 20 a `em_andamento` (com lease liberado)

## Notas

- Shim host ≠ Linha B; sem `TOKENS_PER_S`; hipótese **não** comprovada
- Sem editar `kernel/` nesta branch enquanto E19 trabalha
