# Tasks — Shard multi-GPU host executado (além do stub)

Uma task = uma fatia. Ordem: 1 → 2 → 3.  
**Restrição global:** não editar `kernel/`; não quebrar `make verify-gpu-manager` / `make verify-runtime-gpu`; não fingir multi-GPU nem `TOKENS_PER_S`.

- [ ] Task 1 — Contrato host shard + política de skip
  - **Escopo:** criar `docs/shard-multi-gpu-host.md` (identidade `host_shard_exec`, marcadores, plano canônico 22→2 faixas, execução mínima aceitável, tabela de skip, fronteira vs E25/E38/E8). Atualizar pontes em `docs/gpu-manager-prototipo-host.md` e `docs/desenho-gpu-manager-multi-gpu.md`. Esboço de `scripts/run-gpu-shard-host.sh` (ou nome único) que imprime marcadores esperados em modo `--dry-doc` **ou** comentários alinhados ao contrato — sem exigir GPU nesta task.
  - **Fora:** implementação CUDA/Vulkan completa; `kernel/`; alterar stub E25; harness; inferência com métricas.
  - **Pronto quando:** doc existe com **decisão de skip** explícita (`N<2` → `IA_LIVRE_GPU_SHARD_SKIP`); marcadores listados; pontes E25/desenho atualizadas; README avaliado (`readme-por-fatia`).

- [ ] Task 2 — Executor: plano pipeline/layer + prova mínima por GPU
  - **Escopo:** implementar entrypoint host que (a) enumera GPUs, (b) se `≥2`, monta `IA_LIVRE_GPU_SHARD_PLAN` estável, (c) por device emite `IA_LIVRE_GPU_SHARD_DEVICE` + `IA_LIVRE_GPU_SHARD_RANGE` e executa prova mínima real (seleção de device + operação verificável — ver spec), (d) se `&lt;2`, emite apenas `IA_LIVRE_GPU_SHARD_SKIP` com motivo. Identidade `IA_LIVRE_GPU_MGR=host_shard_exec`. `gpu-manager-stub.sh` permanece doc-only.
  - **Fora:** `TOKENS_PER_S`; tensor parallel; exigir GGUF no caminho feliz; editar `kernel/`; mudar semântica `verify-runtime-gpu`.
  - **Pronto quando:** em máquina com ≥2 GPUs (ou `VERIFY_GPU_SHARD_FORCE=1` com política documentada), script/binário emite `IA_LIVRE_GPU_SHARD_EXEC_OK` + plano; com 1 GPU emite `IA_LIVRE_GPU_SHARD_SKIP` sem `EXEC_OK`; compilação workspace (se crate novo) ok; stub E25 ainda emite `SHARD_DOC` sem execução.

- [ ] Task 3 — Gate `verify-gpu-shard-host` + AGENTS
  - **Escopo:** `scripts/verify-gpu-shard-host.sh` + `make verify-gpu-shard-host` validando marcadores conforme doc (exec **ou** skip honesto). `AGENTS.md` (Como rodar / verificar / estrutura). Reavaliar README. Garantir regressão documentada de `verify-gpu-manager` e `verify-runtime-gpu`.
  - **Fora:** marcar etapa `feita` (agente principal + revisor); harness; nativo kernel.
  - **Pronto quando:** gate passa com ≥2 GPUs (`SHARD_EXEC_OK`) **ou** skip (`SHARD_SKIP`, exit 0); `VERIFY_GPU_SHARD_SKIP=1` coberto; `AGENTS.md` descreve caminho; critérios de `spec.md` checáveis; etapa pronta para revisor (não marcar `feita` nesta task).