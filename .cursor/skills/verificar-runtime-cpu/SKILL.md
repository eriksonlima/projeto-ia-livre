---
name: verificar-runtime-cpu
description: Roda o gate do runtime de inferência CPU (make verify-runtime / IA_LIVRE_INFER_OK + métricas). Use ao validar mudanças em runtime/ ou na Etapa 5+.
disable-model-invocation: true
---

# Verificar runtime CPU

## Quando

Após alterar `runtime/`, `scripts/verify-runtime.sh` ou o modelo canônico; antes de declarar fatia da Etapa 5 pronta.

## Pré-requisitos

- `./scripts/fetch-model.sh` já rodado (GGUF em `models/`)
- `LIBCLANG_PATH` / `BINDGEN_EXTRA_CLANG_ARGS` se necessário (ver `AGENTS.md`)
- `PATH` com `$HOME/.cargo/bin` e `$HOME/.local/bin`

## Comandos

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
make verify-runtime
```

Sucesso: linha contendo `GATE_OK: runtime CPU` e marcadores `IA_LIVRE_INFER_OK`, `IA_LIVRE_LOAD_S=`, `IA_LIVRE_TOKENS_PER_S=`.

Timeout: `VERIFY_RUNTIME_TIMEOUT=600 make verify-runtime`.

## Não fazer

- Não substituir `make verify` do kernel
- Não exigir GPU ou QEMU neste gate
