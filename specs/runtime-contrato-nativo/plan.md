# Plan — Runtime falando o contrato nativo

## Abordagem

1. **Documentar** a superfície runtime↔kernel/shim alinhada ao ADR 0003, separando: (a) marcadores **candidatos** do provedor E19 no kernel; (b) marcadores do **consumidor** host (`CONTRACT_*`); (c) harness B proxy vs evidência de contrato.
2. **Implementar shim host** (crate `runtime-contract`) que simula alloc tipado + `set_phase` Prefill→Decode e emite marcadores — verificável sem QEMU/E19.
3. **Gate** `verify-runtime-contract` + pontes honestas no harness/docs; não alterar o significado de Linha B proxy.
4. **Integrar** QEMU: harness B observa `MEM_SCHED_*`/`TYPED_*` e reemite `HARNESS_CONTRACT_*` (proxy preservado).

## Ordem das fatias

Task 1 → Task 2 → Task 3 → Task 4.

## Fronteira com Etapa 19

| Camada | Dono | Esta etapa |
|--------|------|------------|
| Allocator tipado + hints no `kernel/` | E19 / B13 | **Não editar** (só observar) |
| Consumidor / shim host | E20 / B14 | Implementar |
| Harness B proxy E12 | Existente | Preservar + evidência contrato |
| Serial QEMU com contrato real | E20 Task 4 | Feito via `run-harness-line-b.sh` |

## Verificação

- Task 1: checklist doc + pontes
- Task 2–3: `cargo build -p ia-livre-runtime-contract` + `make verify-runtime-contract`
- Task 4: `make verify` + `make verify-runtime-contract` + `make verify-harness` (B com `HARNESS_CONTRACT_*`)
