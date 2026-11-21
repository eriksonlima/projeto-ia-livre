# Progress

## O que funciona

- Gates de produto; ADRs 0001–0007; LICENSE Apache-2.0
- Etapas 1–19 feitas (E19: typed Weights/KvCache + Prefill/Decode + `MEM_SCHED_OK`)
- **Etapa 20 (branch):** shim host `ia-livre-runtime-contract` + `make verify-runtime-contract` (GATE_OK); docs `runtime-contrato-nativo.md`

## Bloqueios

- Hipótese A vs B **não** comprovada (B ainda = proxy; sem GGUF canônico em B)
- Task 4 (integração QEMU) desbloqueada após E19 em `main` — em andamento

## Por etapa

- 1–19: feitas
- 20: `pendente` → claim/`em_andamento` (B14 / #20) — Tasks 1–3 ok; Task 4 a completar
- Backlog Abertas: B15+ (#21+)

## Etapa 19 — Memória model-aware + scheduler (impl. mínima)

- **Status:** feita
- **Funciona:** typed Weights/KvCache + Prefill/Decode quantum + `make verify` (MEM_SCHED_OK)
- **Não:** GGUF em B; prova da hipótese; ABI; runtime falando contrato (B14 / Etapa 20)
