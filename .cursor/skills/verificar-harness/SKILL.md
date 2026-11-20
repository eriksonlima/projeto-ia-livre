---
name: verificar-harness
description: >-
  Roda o gate do harness Linha A vs B (make verify-harness): A = GGUF no host;
  B = proxy QEMU pós-ExitBoot. Use ao validar harness, run-harness-line-*.sh
  ou docs runtime-nativo-linha-b / harness-linha-a-b. Não prova a hipótese.
disable-model-invocation: true
---

# Verificar harness Linha A vs Linha B

## Quando

Após alterar `scripts/run-harness-line-a.sh`, `scripts/run-harness-line-b.sh`, `scripts/verify-harness.sh`, `docs/harness-linha-a-b.md`, `docs/runtime-nativo-linha-b.md` ou o microbenchmark `NATIVE_BENCH_*` no kernel.

## Pré-requisitos

- GGUF canônico (`./scripts/fetch-model.sh`)
- QEMU/OVMF (Linha B)
- `PATH` com Cargo; `LIBCLANG_PATH` se necessário

## Comandos

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
make verify-harness
```

Sucesso: `GATE_OK: harness — A (GGUF) ok + B (proxy QEMU) ok — hipótese NÃO comprovada`.

Timeout: `VERIFY_HARNESS_TIMEOUT=600 make verify-harness`.

## Não fazer

- Não tratar B como TinyLlama / emitir `TOKENS_PER_S` em B
- Não declarar hipótese comprovada
- Não confundir com `make verify` (só kernel) ou `make verify-runtime`
