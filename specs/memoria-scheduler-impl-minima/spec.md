# Spec — Memória model-aware + scheduler por fases (impl. mínima)

## Resultado visível

No UEFI/QEMU pós-ExitBoot: allocator tipado Weights/KvCache, hints Prefill/Decode, quantum Prefill>Decode, marcadores COM1, `make verify` exige `IA_LIVRE_MEM_SCHED_OK`. Sem GGUF; sem prova da hipótese; sem ABI/multi-tenant/GPU.

## Contexto

ADR 0003, `docs/desenho-memoria-scheduler-nativo.md`, `docs/memoria-scheduler-impl-minima.md`.

## Decisão

Ordem: EXIT_BOOT_OK → MEM_SCHED → NATIVE_BENCH. QUANTUM_PREFILL=8, QUANTUM_DECODE=2. Weights=128, KvCache=256.

## Critérios de aceite

- Doc + pontes; serial completa; regressão EXIT/NATIVE_BENCH; make verify; AGENTS; sem GGUF/hipótese.

## Etapa

Etapa 19 — Issue #19 — `specs/memoria-scheduler-impl-minima/`.
