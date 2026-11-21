# Protótipo mínimo — GPU manager (host stub)

**Nível:** primeiro stub verificável (Etapa 25 / B19).  
**Não** é GPU manager do SO IA Livre. **Não** prova hipótese A vs B.  
**Não** toca `kernel/`.

Desenho: [`desenho-gpu-manager-multi-gpu.md`](desenho-gpu-manager-multi-gpu.md) · ADR [`0006`](adr/0006-gpu-manager-multi-gpu.md).  
Host single-GPU (Etapa 8): ADR [`0002`](adr/0002-aceleracao-gpu-host-llama-cpp.md) · `make verify-runtime-gpu`.

## Fronteira host vs nativo

| Aspecto | Este stub (host) | Caminho nativo (futuro) |
|---------|------------------|-------------------------|
| Onde | Linux `std` — `scripts/gpu-manager-stub.sh` | Kernel IA Livre (mecanismos) pós-ExitBoot |
| Identidade | `IA_LIVRE_GPU_MGR=host_stub` | Futuro: mecanismos kernel ≠ este marcador |
| Enum | Contagem via `nvidia-smi -L` (ou 0) | Enum de aceleradores no SO |
| Placement | Hint fixo documentado (`device0\|weights`) | Afinidade Weights/KvCache + fase |
| Shard | **Só documentado** (`pipeline_layer`) | Pipeline/layer sharding real |
| Inferência | Continua no runtime (ADR 0002); stub **não** offload | Runtime continua dono dos kernels |

**Confusão a evitar:** offload `--n-gpu-layers` / `IA_LIVRE_ACCEL` (Etapa 8) **≠** este stub **≠** manager nativo Linha B.

## Superfície do stub (marcadores)

Emitidos por `./scripts/gpu-manager-stub.sh`:

```
IA_LIVRE_GPU_MGR=host_stub
IA_LIVRE_GPU_DEVICES=<N>           # 0 se indetectável; N≥1 se nvidia-smi -L listar
IA_LIVRE_GPU_PLACE_HINT=device0|weights
IA_LIVRE_GPU_SHARD_DOC=pipeline_layer
IA_LIVRE_GPU_MGR_OK
```

Sem GPU / CI: o **gate** (`make verify-gpu-manager`) imprime `IA_LIVRE_GPU_MGR_SKIP` e exit 0 — **sem** fingir multi-GPU nem `IA_LIVRE_ACCEL≠cpu`.

## Shard (documentado, não executado)

Estratégia preferida do ADR 0006: **pipeline / layer sharding**.  
Este protótipo **não** particiona camadas entre GPUs; só declara `IA_LIVRE_GPU_SHARD_DOC=pipeline_layer`.  
Fora: tensor parallel, expert parallel, clusters/RDMA.

## O que não está implementado

- Mecanismos no `kernel/` (enum nativo, afinidade pós-ExitBoot)
- Multi-GPU real / shard em código
- Mudança da semântica Etapa 8 (`verify-runtime-gpu` / `IA_LIVRE_GPU_SKIP`)
- Integração no harness A vs B
- ABI/syscalls; driver in-kernel

## Como rodar / verificar

```bash
./scripts/gpu-manager-stub.sh
make verify-gpu-manager
# Skip CI: VERIFY_GPU_MANAGER_SKIP=1 make verify-gpu-manager
```

Detalhe: `AGENTS.md` → Gate do GPU manager stub host (Etapa 25).
