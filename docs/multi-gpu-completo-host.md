# Multi-GPU host completo além do shard (Etapa 69)

Além de E41 (`host_shard_exec` / `pipeline_layer`).  
Ponte: [`shard-multi-gpu-host.md`](shard-multi-gpu-host.md) · [`desenho-gpu-manager-multi-gpu.md`](desenho-gpu-manager-multi-gpu.md) · ADR [`0006`](adr/0006-gpu-manager-multi-gpu.md).

> **≠** stub E25 · **≠** shard-only E41 · **≠** native/guest · **≠** `TOKENS_PER_S`.

## Identidade

| Marcador | Valor |
|----------|--------|
| `IA_LIVRE_GPU_MGR` | **`host_multi`** |
| Modo | `weights_kv_place` |

## Além do shard E41

E41 prova faixas de **camadas** (`0:0-10,1:11-21`).  
E69 prova **placement dual** Weights → device0, KvCache → device1 (afinidade Prefill/Decode do desenho), com query `nvidia-smi -i` por device.

Plano canônico (≥2 devices):

```
IA_LIVRE_GPU_MULTI_MODE=weights_kv_place
IA_LIVRE_GPU_MULTI_PLAN=W:0,K:1
```

Por papel: `IA_LIVRE_GPU_MULTI_DEVICE=<id>` + `IA_LIVRE_GPU_MULTI_PLACE=Weights|KvCache`.

## Skip

| Condição | `MULTI_SKIP_REASON` | Exit |
|----------|---------------------|------|
| `VERIFY_GPU_MULTI_SKIP=1` | `forced` | 0 |
| Sem GPU | `no_gpu` | 0 |
| `DEVICES < 2` | `need_2_devices` | 0 |

Skip **não** emite `MULTI_EXEC_OK`.

## Gate

```bash
make verify-gpu-multi
```

Anti-fraude: falha se `MULTI_EXEC_OK` com &lt;2 devices ou `MGR=host_stub`/`host_shard_exec` como único sucesso.  
E41 / E25 / E8 intactos.

## Limites

- Sem inferência llama multi-GPU full.
- Sem fingir 2 papéis no mesmo device único.
