# Progress

## O que funciona

- Gates de produto; ADRs 0001–0007; LICENSE Apache-2.0
- Etapas 1–19 feitas
- **Etapa 20:** shim host `ia-livre-runtime-contract` + `verify-runtime-contract`; harness B com `HARNESS_CONTRACT_*` (MEM_SCHED E19) + proxy preservado

## Bloqueios

- Hipótese A vs B **não** comprovada (B ≠ GGUF canônico; B15+)

## Por etapa

- 1–19: feitas
- 20: Tasks 1–4 feitas — fechar como `feita`
- Backlog Abertas / branches paralelas: B15–B19 (não duplicar)

## Etapa 20 — Runtime falando o contrato nativo

- **Status:** fechando
- **Funciona:** host_shim + QEMU evidencia MEM_SCHED via harness B
- **Não:** GGUF em B; prova da hipótese; GPU manager
