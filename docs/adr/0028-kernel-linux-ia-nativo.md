# ADR 0028 — Kernel Linux IA-nativo (defconfig/patches mínimos)

- Status: aceita
- Data: 2026-11-21

## Contexto

ADR 0027 define produto = Linux IA-nativo. A imagem bootável (E82–E85) usa kernel **Debian stock**. Customização (defconfig/patches model-aware) vem **depois** da imagem (architecture.md).

## Decisão

1. Manter **kernel Debian** (ou upstream LTS empacotado) como default da ISO/live.
2. Documentar defconfig **alvo** (não build CI obrigatório nesta etapa):
   - `CONFIG_HUGETLBFS=y`, `CONFIG_TRANSPARENT_HUGEPAGE=y`
   - cgroup v2, `CONFIG_CFS_BANDWIDTH`
   - virtio / 9p para lab QEMU
3. Patches “model-aware” (scheduler/memória) ficam **fora** do gate de produto até existir farm de build reproduzível.
4. Gate E94: evidencia ADR + defconfig doc **ou** `OUTCOME=deferred_stock_kernel` — **sem** fingir boot de kernel custom.

## Consequências

- Produto utilizável sem compilar kernel.
- Evolução futura: pacote `.deb`/UKI custom com ADR de revisão.
- Hipótese A/B / Linha B permanecem arquivadas.
