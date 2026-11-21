# Plan — Shard multi-GPU host executado (além do stub)

## Abordagem

Materializar no **host** a primeira execução mínima de pipeline/layer sharding, **sem** tocar o kernel e **sem** confundir com offload single-GPU (E8) nem manager nativo (E38).

1. **Contrato + skip (Task 1)** — `docs/shard-multi-gpu-host.md`: marcadores, política de skip (`need_2_devices`), execução mínima aceitável, fronteiras. Estabilizar nomes (`IA_LIVRE_GPU_MGR=host_shard_exec`, `IA_LIVRE_GPU_SHARD_SKIP`). Pontes em stub/desenho. **Sem** gate novo ainda.
2. **Executor (Task 2)** — Entrypoint host: detecta `N` devices; se `N≥2`, calcula plano canônico (22 camadas → duas faixas), para cada device emite `SHARD_DEVICE`/`SHARD_RANGE` e executa prova mínima (CUDA device select + alloc/init **ou** caminho Vulkan equivalente; alternativa aceitável: duas invocações controladas com `CUDA_VISIBLE_DEVICES` documentadas no contrato). Se `N<2`, emite só `IA_LIVRE_GPU_SHARD_SKIP`. **Não** emitir `TOKENS_PER_S`. Stub `gpu-manager-stub.sh` **inalterado** em comportamento E25.
3. **Gate + pontes (Task 3)** — `scripts/verify-gpu-shard-host.sh` + `make verify-gpu-shard-host`: com ≥2 GPUs exige `SHARD_EXEC_OK` + plano; caso contrário exige `SHARD_SKIP` e exit 0. `AGENTS.md` + grep de marcadores; README avaliado. Confirmar `verify-gpu-manager` e `verify-runtime-gpu` verdes.

Ordem: 1 → 2 → 3. Task 1 pode fechar só com doc + esqueleto de script comentado; preferência: doc + assinatura de marcadores no esqueleto.

## Arquivos prováveis

- `docs/shard-multi-gpu-host.md` (novo)
- `docs/gpu-manager-prototipo-host.md`, `docs/desenho-gpu-manager-multi-gpu.md` (pontes)
- `scripts/gpu-shard-host.sh` e/ou `scripts/run-gpu-shard-host.sh` (executor)
- `gpu-shard-host/` (crate opcional no workspace) **ou** extensão mínima em `runtime/` — **proibido** `kernel/`
- `scripts/verify-gpu-shard-host.sh`, `Makefile` (alvo novo)
- `Cargo.toml` (membro opcional do workspace)
- `AGENTS.md`, opcionalmente `README.md`
- **Intocados salvo ponte:** `scripts/gpu-manager-stub.sh`, `scripts/verify-gpu-manager.sh`, `kernel/`

## Dependências

- E25 feita — stub e gate baseline.
- E8 — política `IA_LIVRE_GPU_SKIP`; não regressir.
- CUDA Toolkit ou Vulkan SDK **somente** no caminho de execução com ≥2 GPUs; skip cobre CI sem hardware.
- GGUF **não** obrigatório para o gate de shard (execução mínima por device); se Task 2 optar por tocar runtime, manter opt-in e sem métricas de geração.

## Verificação

- **Skip path:** `VERIFY_GPU_SHARD_SKIP=1 make verify-gpu-shard-host` → `IA_LIVRE_GPU_SHARD_SKIP`, exit 0.
- **Host 1 GPU:** gate → `IA_LIVRE_GPU_SHARD_SKIP` (motivo 2 devices), exit 0; **ausência** de `SHARD_EXEC_OK`.
- **Host ≥2 GPUs:** `./scripts/run-gpu-shard-host.sh` (ou nome fixado) → `SHARD_EXEC_OK` + `SHARD_PLAN` + ≥2 pares device/range.
- **Regressão:** `make verify-gpu-manager`, `make verify-runtime-gpu` (ou skips canônicos E8).
- **Negativo:** grep no gate/doc — sem exigir `TOKENS_PER_S`; sem `IA_LIVRE_GPU_MGR=native` no executor host.
- Checklist `AGENTS.md` → Como verificar (Task 3).