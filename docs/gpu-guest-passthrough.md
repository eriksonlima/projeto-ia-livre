# GPU real no guest — PCI/pass-through (Etapa 65)

Ponte: [`gpu-real-nativo.md`](gpu-real-nativo.md) (E55 `SRC=host`) · [`gpu-manager-nativo.md`](gpu-manager-nativo.md) (E38 synthetic) · ADR [`0023`](adr/0023-simetria-gpu-harness-inviavel.md).

> **≠** `SRC=host` (E55). **≠** `KIND=synthetic` (E38). **≠** stub E25. Sem `TOKENS` / `COMPROVA`.

## Objetivo

Evidência de GPU **no guest** via PCI/VFIO pass-through **ou** skip honesto (`need_gpu` / `need_vfio`).

## Marcadores

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_GPU_REAL_SRC=pci_passthrough` | Origem = pass-through guest |
| `IA_LIVRE_GPU_REAL_OK` | Sucesso com evidência VFIO/guest |
| `IA_LIVRE_GPU_NEED_GPU=need_gpu` | Sem GPU no host |
| `IA_LIVRE_GPU_NEED_GPU=need_vfio` | GPU pode existir, mas VFIO/IOMMU/binding ausente |
| `IA_LIVRE_GPU_VFIO_GROUPS=` | Contagem de grupos VFIO (quando detectável) |

## Evidência mínima para `REAL_OK` + `pci_passthrough`

Pelo menos um de:

1. Device sob driver `vfio-pci` **e** `/dev/vfio/<group>` presente; **ou**
2. Log serial guest documentado com enum PCI GPU real (não synthetic) + `SRC=pci_passthrough`.

**Não** basta: `nvidia-smi` no host sozinho; fixture E38 synthetic; `SRC=host`.

## Skip (CI / este host)

| Condição | Marcador | Exit |
|----------|----------|------|
| `VERIFY_GPU_GUEST_SKIP=1` | `need_vfio` (ou `need_gpu`) | 0 |
| Sem GPU host | `need_gpu` | 0 |
| GPU host sem VFIO/IOMMU | `need_vfio` | 0 |

## Gate

```bash
make verify-gpu-guest-passthrough
```

Sucesso A: `SRC=pci_passthrough` + `REAL_OK`.  
Sucesso B (honesto): `NEED_GPU=need_gpu|need_vfio` **sem** `REAL_OK`.

## Relação com harness

ADR 0023: simetria GPU no harness só após esta evidência (ou equivalente) existir. Até lá: `sym_cpu` / E56 assimétrico.
