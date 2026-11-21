# GPU real no caminho nativo (Etapa 55)

Além da enum **sintética** E38. Contrato: GPU **real** (host path documentado ou PCI/pass-through opt-in) **ou** skip `need_gpu` honesto.

ADR 0006 / [`gpu-manager-nativo.md`](gpu-manager-nativo.md). **≠** stub E25 (`host_stub`). **≠** shard E41.

## Fronteiras

| Etapa | Identidade | GPU |
|-------|------------|-----|
| E25 | `GPU_MGR=host_stub` | Host stub |
| E38 | `GPU_MGR=native` + `KIND=synthetic` | QEMU default |
| E41 | `host_shard_exec` | Multi-GPU host |
| **E55** | `GPU_REAL_*` | Real **host** (`SRC=host`) **ou** `NEED_GPU` |
| **E65** | `GPU_REAL_*` guest | `SRC=pci_passthrough` + `REAL_OK` **ou** `need_vfio`/`need_gpu` — [`gpu-guest-passthrough.md`](gpu-guest-passthrough.md) |

`synthetic` + `GPU_MGR_OK` **não** conta como sucesso E55/E65. `SRC=host` **não** conta como sucesso E65.

## Marcadores

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_GPU_REAL_SRC=host\|pci_passthrough` | Origem da evidência real |
| `IA_LIVRE_GPU_REAL_DEVICES=` | Contagem (≥1 no sucesso) |
| `IA_LIVRE_GPU_REAL_PLACE_HINT=` | Placement mínimo (1 device) |
| `IA_LIVRE_GPU_REAL_OK` | Sucesso com GPU real |
| `IA_LIVRE_GPU_NEED_GPU` | Skip honesto (sem GPU / env) |

Âncora E38: log/fixture com `GPU_MGR=native` (synthetic permanece no `make verify`).

## Skip

| Variável | Efeito |
|----------|--------|
| `VERIFY_GPU_REAL_SKIP=1` | Força `NEED_GPU`, exit 0 |
| Sem `nvidia-smi` / 0 GPUs | `NEED_GPU=need_gpu`, exit 0 |

## Gate

```bash
make verify-gpu-native-real
```

Com GPU: exige `GPU_REAL_OK` + `SRC=host|pci_passthrough`.  
Sem GPU: `GPU_NEED_GPU` exit 0.  
Anti-fraude: falha se `REAL_OK` com só `KIND=synthetic`; sem multi-GPU fingido.

## Limites

- Sem driver vendor no kernel; sem `TOKENS_PER_S`; sem exigir pass-through no CI.
- PCI guest = opt-in documentado (`SRC=pci_passthrough`).
