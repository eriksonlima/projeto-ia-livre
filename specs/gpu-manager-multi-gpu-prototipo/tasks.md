# Tasks — GPU manager / multi-GPU (protótipo mínimo)

Uma task = uma fatia. Ordem: 1 → 2 → 3.  
**Restrição global:** não editar `kernel/`, `node/`, `agent/`; não quebrar `make verify-runtime-gpu` / `IA_LIVRE_GPU_SKIP`.

- [x] Task 1 — Contrato do stub host + superfície mínima (enum / placement) sem `kernel/`
  - **Escopo:** criar `docs/gpu-manager-prototipo-host.md` (fronteira host vs nativo; alinhamento ADR 0006; shard pipeline/layer **documentado**; o que não está implementado). No host (`runtime/` preferido): emitir marcadores estáveis de identidade do stub + enum (ex. `IA_LIVRE_GPU_MGR=…`, `IA_LIVRE_GPU_DEVICES=…`) e hint de afinidade/placement (ex. `IA_LIVRE_GPU_PLACE_HINT=…`); CPU default e Etapa 8 intactos. Ponte mínima no desenho/ADR 0006 (“primeiro stub = host”). Sem gate novo ainda.
  - **Fora:** `kernel/`; multi-GPU real; RDMA/tensor parallel; alterar semântica de skip GPU; harness A vs B.
  - **Pronto quando:** doc do protótipo existe e declara host ≠ nativo; stub host emite enum + placement (grepável); `cargo build -p ia-livre-runtime` (default) sucede; `make verify-runtime` não regride; nenhum arquivo em `kernel/`; README avaliado (`readme-por-fatia`).
  - **Feito:** doc + `scripts/gpu-manager-stub.sh` (sem editar `runtime/` — evita colisão B14); pontes ADR/desenho; README considerado (não atualizado — ponte AGENTS). `runtime/` inalterado.

- [x] Task 2 — Caminho verificável com skip honesto (gate novo ou extensão não regressiva)
  - **Escopo:** preferir `scripts/verify-gpu-manager.sh` + `make verify-gpu-manager` que valida marcadores do stub quando GPU detectável e, sem GPU/CI, imprime skip canônico (ex. `IA_LIVRE_GPU_MGR_SKIP` ou reuso documentado de `IA_LIVRE_GPU_SKIP`) com exit 0 — **sem** fingir aceleração nem exigir ≥2 GPUs. Alternativa: extensão mínima de `verify-runtime-gpu.sh` que preserve 100% o comportamento Etapa 8. Documentar política de skip no doc do protótipo.
  - **Fora:** clusters/RDMA; prova A vs B; quebrar `verify-runtime-gpu`; implementação nativa no kernel.
  - **Pronto quando:** comando `make` documentável passa com GPU (marcadores presentes) **ou** skip honesto sem GPU; `make verify-runtime-gpu` continua correto (GATE_OK ou `IA_LIVRE_GPU_SKIP`); sem falso `IA_LIVRE_ACCEL≠cpu` / device count inventado.
  - **Feito:** `verify-gpu-manager.sh` + Makefile; GATE_OK com GPU; skip `IA_LIVRE_GPU_MGR_SKIP`; `VERIFY_RUNTIME_GPU_SKIP=1` → `IA_LIVRE_GPU_SKIP` preservado.

- [x] Task 3 — Pontes AGENTS / architecture + fecho documental da etapa
  - **Escopo:** `AGENTS.md` (Como rodar / Como verificar / Estrutura) aponta doc + gate/stub; atualizar `docs/architecture.md` e pontes do desenho se ainda disserem “só doc, zero stub”; README reavaliado; checklist do Pronto quando da Etapa 25 coberta nos docs.
  - **Fora:** código novo além de ajustes de ponte; marcar etapa `feita` (agente principal + revisor); tocar `kernel/`.
  - **Pronto quando:** `AGENTS.md` descreve o caminho verificável e a fronteira host≠nativo; pontes ADR/desenho/architecture honestas; README considerado; critérios de aceite da `spec.md` checáveis; etapa pronta para revisão (não marcar `feita` aqui).
  - **Feito:** AGENTS gate/estrutura; architecture + desenho/ADR; README considerado (não atualizado).
