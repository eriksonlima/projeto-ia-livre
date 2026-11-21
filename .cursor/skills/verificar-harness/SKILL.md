---
name: verificar-harness
description: >-
  Roda gates do harness A vs B: verify-harness (A GGUF + B proxy/BlockIO stub) e,
  sob protocolo quieto, verify-harness-comparable (VERDICT). Use ao validar harness
  ou docs runtime-nativo / corrida-quieta. Não prova a hipótese.
disable-model-invocation: true
---

# Verificar harness Linha A vs Linha B

## Quando

Após alterar `scripts/run-harness-line-*.sh`, `scripts/verify-harness*.sh`, `docs/harness-*.md`, `docs/runtime-nativo-linha-b.md` ou marcadores `NATIVE_BENCH_*` / `MEM_SCHED_*` / `GGUF_*` no kernel.

## Pré-requisitos

- GGUF canônico (`./scripts/fetch-model.sh`)
- QEMU/OVMF (Linha B); preferir **um gate por vez** — [`docs/harness-corrida-quieta.md`](../../../docs/harness-corrida-quieta.md)
- `PATH` com Cargo; `LIBCLANG_PATH` se necessário

## Comandos

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

# Harness v1 (A + B)
make verify-harness

# Comparável + VERDICT (Etapa 22/28) — sob protocolo quieto
make verify-harness-comparable
```

Sucesso `verify-harness`: `GATE_OK` com B `GGUF_NATIVE_LOADER=blockio_full`, `GGUF_STATUS=layout_ok`, `B_BLOCK=no_gguf_forward`, `LOAD_KIND=proxy` — **sem** `TOKENS_PER_S` / `LOAD_S` em B.

Sucesso `verify-harness-comparable` (estado atual): `VERDICT=INCONCLUSIVO` + reason `…E29_no_gguf_forward`.

Preflight quieto: aviso se QEMU/`verify-*` concorrente; `IA_LIVRE_HARNESS_QUIET_STRICT=1` falha; `IA_LIVRE_HARNESS_QUIET_FORCE=1` override.

Timeouts: `VERIFY_HARNESS_TIMEOUT` / `VERIFY_HARNESS_COMPARABLE_TIMEOUT`.

## Não fazer

- Não inventar `TOKENS_PER_S` / `LOAD_KIND=gguf` em B
- Não declarar hipótese comprovada sob `no_gguf_infer_engine`
- Não rodar vários gates/QEMU/runtime em paralelo na mesma medição
- Não confundir com `make verify` (kernel) ou `verify-runtime` / `verify-runtime-contract`
