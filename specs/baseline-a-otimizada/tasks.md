# Tasks — Baseline Linha A otimizada (CPU) no gate comparável (Etapa 34)

Uma task = uma fatia.

- [ ] Task 1 — Script `scripts/run-harness-line-a-optimized.sh`: governor performance (skip com `GOVERNOR_SKIP` se sem permissão), `--threads N` (default `nproc - 1`, override `IA_LIVRE_HARNESS_N_THREADS`), `taskset` opt-in (`TASKSET_OK/SKIP`), leitura de temperatura (`THERMAL_OK/SKIP`); emite `IA_LIVRE_HARNESS_PROFILE=A_otimizada` + `IA_LIVRE_HARNESS_THREADS=N` + `IA_LIVRE_HARNESS_LINE=A` + `IA_LIVRE_HARNESS_OK` + métricas honestas; `run-harness-line-a.sh` inalterado
- [ ] Task 2 — Integração no harness comparável: `run-harness-a-b-comparable.sh` aceita `IA_LIVRE_HARNESS_A_PROFILE=A_otimizada` → chama novo script (default = A_default); lógica de veredito inalterada; Makefile: target `verify-harness-a-otimizada` (chama `run-harness-line-a-optimized.sh`; exige `HARNESS_OK` + `PROFILE=A_otimizada`); `make verify-harness-comparable` preservado verde
- [ ] Task 3 — Docs + gate final: `docs/harness-perfis-a-otimizada-gpu.md` atualizado (metodologia → executável verificável; script/variável env documentados); `docs/harness-a-b-comparavel.md` menciona A_otimizada como opt-in; `AGENTS.md` cobre novo script/gate; corrida `IA_LIVRE_HARNESS_A_PROFILE=A_otimizada make verify-harness-comparable` passa com `INCONCLUSIVO` honesto; README avaliado
