# Tasks — Shard multi-GPU host executado (além do stub)

Uma task = uma fatia. Ordem: 1 → 2 → 3.  
**Restrição global:** não editar `kernel/`; não quebrar `make verify-gpu-manager` / `make verify-runtime-gpu`; não fingir multi-GPU nem `TOKENS_PER_S`.

- [x] Task 1 — Contrato host shard + política de skip
- [x] Task 2 — Executor: plano pipeline/layer + prova mínima por GPU
- [x] Task 3 — Gate `verify-gpu-shard-host` + AGENTS