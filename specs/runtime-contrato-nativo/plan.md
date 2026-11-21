# Plan — Runtime falando o contrato nativo

## Abordagem

1. **Documentar** a superfície runtime↔kernel/shim alinhada ao ADR 0003, separando: (a) marcadores **candidatos** do provedor E19 no kernel; (b) marcadores do **consumidor** host (`CONTRACT_*`); (c) harness B proxy vs evidência de contrato.
2. **Implementar shim host** (crate `runtime-contract`) que simula alloc tipado + `set_phase` Prefill→Decode e emite marcadores — verificável sem QEMU/E19.
3. **Gate** `verify-runtime-contract` + pontes honestas no harness/docs; não alterar o significado de Linha B proxy.
4. **Adiar** integração QEMU até E19 entregar `MEM_SCHED_OK` / `TYPED_*` observáveis.

## Ordem das fatias

Task 1 → Task 2 → Task 3 → Task 4 (bloqueada).

## Fronteira com Etapa 19

| Camada | Dono | Esta etapa |
|--------|------|------------|
| Allocator tipado + hints no `kernel/` | E19 / B13 | **Não editar** |
| Consumidor / shim host | E20 / B14 | Implementar |
| Harness B proxy E12 | Existente | Preservar; documentar vs contrato |
| Serial QEMU com contrato real | E20 Task 4 | Só após E19 |

## Verificação

- Task 1: checklist doc + pontes
- Task 2–3: `cargo build -p ia-livre-runtime-contract` + `make verify-runtime-contract`; regressão `make verify-harness` (quando GGUF/QEMU disponíveis)
- Task 4: `make verify` com marcadores E19 (quando desbloqueada)
