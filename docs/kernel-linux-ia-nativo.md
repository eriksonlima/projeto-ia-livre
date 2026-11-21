# Kernel Linux IA-nativo

Ver ADR [`0028`](adr/0028-kernel-linux-ia-nativo.md).

## Defconfig alvo (mínimo)

```
CONFIG_HUGETLBFS=y
CONFIG_TRANSPARENT_HUGEPAGE=y
CONFIG_CGROUPS=y
CONFIG_MEMCG=y
CONFIG_CFS_BANDWIDTH=y
CONFIG_VIRTIO_PCI=y
CONFIG_NET_9P=y
CONFIG_9P_FS=y
```

Default do produto: **kernel stock Debian** na ISO. Build custom = opt-in futuro.

Gate: `make verify-kernel-linux-ia`.
