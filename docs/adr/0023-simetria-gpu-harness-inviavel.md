# ADR 0023 — Simetria GPU A/B no harness inviável até passthrough

- Status: aceita
- Data: 2026-11-21

## Contexto

Etapa 56 oferece `A_gpu` (host CUDA/Vulkan) + Linha B no QEMU **sem** acelerador guest → veredito `INCONCLUSIVO` por **assimetria** de accel. Etapa 64 pede corrida com o **mesmo** perfil de aceleração. GPU real no guest (PCI/pass-through) é B60 / backlog — ainda não existe.

## Decisão

1. **Simetria GPU** (A e B com `ACCEL=cuda|vulkan` reais) é **inviável** no gate atual até haver device GPU no caminho B (B60).
2. Perfil simétrico realizável agora: **`sym_cpu`** — A e B com `HARNESS_ACCEL=cpu`, gate `make verify-harness-sym-cpu`.
3. E56 / `verify-harness-gpu` permanece **assimétrico** honesto (`VERDICT_REASON` com assimetria); **não** é simetria GPU.
4. **Proibido** emitir `HARNESS_ACCEL=cuda|vulkan` na Linha B sem device real.
5. Pilar 1 / ADR 0022 intactos — esta ADR **não** reabre `COMPROVA`.

## Rejeitado

- Fingir ACCEL GPU em B.
- Tratar E56 como “simetria GPU”.
- Exigir passthrough nesta etapa.

## Consequências

- Docs: [`../harness-perfis-a-otimizada-gpu.md`](../harness-perfis-a-otimizada-gpu.md).
- Reabertura de simetria GPU: evidência B60 (`GPU_REAL_SRC=pci_passthrough` ou equiv.) + corrida A/B mesmo accel.
