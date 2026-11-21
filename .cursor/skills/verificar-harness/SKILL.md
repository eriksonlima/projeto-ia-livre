---
name: verificar-harness
description: >-
  Roda o gate do harness Linha A vs B (make verify-harness): A = GGUF no host;
  B = proxy QEMU + HARNESS_CONTRACT_* + CONTRACT_READY + bloqueio GGUF honesto
  (B_BLOCK/no_gguf_path). Use ao validar harness, run-harness-line-*.sh ou docs
  runtime-nativo / harness / contrato. Não prova a hipótese.
disable-model-invocation: true
---

# Verificar harness Linha A vs Linha B

## Quando

Após alterar `scripts/run-harness-line-a.sh`, `scripts/run-harness-line-b.sh`, `scripts/verify-harness.sh`, `docs/harness-linha-a-b.md`, `docs/runtime-nativo-linha-b.md`, `docs/runtime-contrato-nativo.md` ou marcadores `NATIVE_BENCH_*` / `MEM_SCHED_*` no kernel.

## Pré-requisitos

- GGUF canônico (`./scripts/fetch-model.sh`) — Linha A
- QEMU/OVMF (Linha B)
- `PATH` com Cargo; `LIBCLANG_PATH` se necessário

## Comandos

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
make verify-harness
```

Sucesso esperado: `GATE_OK: harness — A (GGUF) ok + B (proxy + CONTRACT_READY + GGUF bloqueado) ok — hipótese NÃO comprovada`.

B deve incluir: `CONTRACT_READY=1`, `GGUF_TARGET_*`, `GGUF_NATIVE_LOADER=absent`, `B_BLOCK=no_gguf_path` (ou legado), `GGUF_STATUS=blocked`, `LOAD_KIND=proxy` — **sem** `TOKENS_PER_S` / `LOAD_S` / `LOAD_KIND=gguf`.

Timeout: `VERIFY_HARNESS_TIMEOUT=600 make verify-harness`.

## Não fazer

- Não tratar B como TinyLlama / emitir `TOKENS_PER_S` ou `LOAD_S` em B
- Não fingir `LOAD_KIND=gguf` ou `HARNESS_MODEL=` TinyLlama em B
- Não declarar hipótese comprovada
- Não confundir com `make verify` (só kernel) ou `make verify-runtime` / `verify-runtime-contract` (shim host)
