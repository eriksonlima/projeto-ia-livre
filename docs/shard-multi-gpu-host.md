# Shard multi-GPU host executado (Etapa 41)

Caminho **host** que **executa** placement/shard pipeline/layer mínimo **além** do stub E25 (`SHARD_DOC` só documentado).  
**≠** `host_stub` (E25) · **≠** `native` (E38) · **≠** offload single-GPU E8 como «manager entregue».  
Além do shard (placement dual Weights+Kv): Etapa 69 — [`multi-gpu-completo-host.md`](multi-gpu-completo-host.md).

Spec: [`specs/shard-multi-gpu-host/`](../specs/shard-multi-gpu-host/).  
Stub: [`gpu-manager-prototipo-host.md`](gpu-manager-prototipo-host.md).  
Desenho: [`desenho-gpu-manager-multi-gpu.md`](desenho-gpu-manager-multi-gpu.md).

## Identidade

| Marcador | Valor |
|----------|--------|
| `IA_LIVRE_GPU_MGR` | **`host_shard_exec`** |

## Plano canônico (TinyLlama ~22L)

Com ≥2 devices:

```
IA_LIVRE_GPU_SHARD_MODE=pipeline_layer
IA_LIVRE_GPU_SHARD_PLAN=0:0-10,1:11-21
```

Por device tocado: `IA_LIVRE_GPU_SHARD_DEVICE=<id>` + `IA_LIVRE_GPU_SHARD_RANGE=<lo>-<hi>`.

## Execução mínima «real»

Por GPU no plano: selecionar o device (`nvidia-smi -i <id>` query verificável) e emitir range.  
**Não** exige GGUF nem `TOKENS_PER_S`. Inferência multi-GPU completa = fora.

## Skip (honesto)

| Condição | Marcador | Exit |
|----------|----------|------|
| `VERIFY_GPU_SHARD_SKIP=1` | `IA_LIVRE_GPU_SHARD_SKIP` (motivo `forced`) | 0 |
| GPU indetectável | `IA_LIVRE_GPU_SHARD_SKIP` (`no_gpu`) | 0 |
| `DEVICES < 2` | `IA_LIVRE_GPU_SHARD_SKIP` (`need_2_devices`) | 0 |
| `DEVICES ≥ 2` + ok | `IA_LIVRE_GPU_SHARD_EXEC_OK` | 0 |

**Proibido:** `EXEC_OK` com 1 GPU; inventar `DEVICES≥2`.

## Gate

```bash
./scripts/run-gpu-shard-host.sh
make verify-gpu-shard-host
# CI: VERIFY_GPU_SHARD_SKIP=1 make verify-gpu-shard-host
```

Stub E25 (`make verify-gpu-manager`) e E8 (`make verify-runtime-gpu`) **inalterados**.
