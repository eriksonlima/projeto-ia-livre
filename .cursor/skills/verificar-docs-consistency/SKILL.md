---
name: verificar-docs-consistency
description: >-
  Roda make verify-docs-consistency (architecture/product/glossário/README).
  Use após editar docs/architecture.md, product-context, glossario ou README.
disable-model-invocation: true
---

# Verificar consistência documental

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
make verify-docs-consistency
```

Sucesso: `IA_LIVRE_CONSISTENCY_OK` / `GATE_OK: docs consistency`.

Contrato: [`docs/glossario.md`](../../../docs/glossario.md), [`docs/architecture.md`](../../../docs/architecture.md).
