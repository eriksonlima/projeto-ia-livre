# Active context

## Foco atual

- Etapa 19 **feita** (MEM_SCHED no kernel; `make verify` OK)
- **Etapa 20** — Runtime falando o contrato nativo (B14) — branch `etapa-b14-runtime-contrato` / worktree `projeto-ia-livre-b14`
- Issue [#20](https://github.com/eriksonlima/projeto-ia-livre/issues/20); Spec: `specs/runtime-contrato-nativo/`
- Tasks 1–3 feitas (shim host + `verify-runtime-contract`); Task 4 desbloqueada (E19 em `main`)

## Mudanças recentes

- Merge `origin/main` (E19) na branch B14
- E19: Weights/KvCache + Prefill/Decode + gate MEM_SCHED_OK
- Spec + Tasks 1–3: docs + shim `runtime-contract/` + gate host

## Próximo passo

- Claim Etapa 20 → `em_andamento` → Task 4 (QEMU observa `MEM_SCHED_*` / `TYPED_*`; harness B honesto)

## Notas

- Shim host ≠ Linha B; sem `TOKENS_PER_S`; hipótese **não** comprovada
