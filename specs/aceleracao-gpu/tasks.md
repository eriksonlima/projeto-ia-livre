# Tasks — Aceleração além de CPU (GPU)

Uma task = uma fatia.

- [x] Task 1 — ADR da escolha de backend (CUDA canônico / Vulkan alternativa) + features Cargo opcionais no `runtime/` + flag CLI `--n-gpu-layers` (default 0) e marcadores de aceleração; default CPU e docs parciais em `AGENTS.md` / `architecture.md`
  - **Pronto quando:** ADR 0002 existe; `cargo build -p ia-livre-runtime` (sem feature GPU) sucede; `--n-gpu-layers` parseado; fallback CPU documentado; `make verify-runtime` não regride; README avaliado (`readme-por-fatia`).
  - **Feito:** ADR 0002; features `cuda`/`vulkan`; CLI + `IA_LIVRE_ACCEL`/`IA_LIVRE_N_GPU_LAYERS`; architecture + AGENTS parciais; `make verify-runtime` GATE_OK; README considerado (não atualizado — ponte AGENTS).

- [ ] Task 2 — Caminho GPU real no host (build com feature do backend) + inferência com offload + métricas comparáveis às da Etapa 5 documentadas
  - **Pronto quando:** comando documentado com `--n-gpu-layers` > 0 emite `IA_LIVRE_INFER_OK` + métricas + `IA_LIVRE_ACCEL=` ≠ `cpu` no host com GPU; doc de métricas GPU preenchida; Como rodar GPU em `AGENTS.md`; CPU default intacto.

- [ ] Task 3 — Gate `make verify-runtime-gpu` / script com política de skip sem GPU (CI) + `AGENTS.md` → Como verificar completo
  - **Pronto quando:** gate GPU passa com GPU; skip canônico (`IA_LIVRE_GPU_SKIP` ou equivalente) documentado sem GPU; gates CPU/existentes não regridem; README reavaliado; etapa pronta para revisão (não marcar `feita` aqui).
