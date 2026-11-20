---
name: verificar-agent-autonomia
description: >-
  Roda o gate do ambiente de autonomia (make verify-agent /
  IA_LIVRE_TOOL_OK + MEMORY_OK + AGENT_OK). Use ao validar mudanças em agent/
  ou na Etapa 7+.
disable-model-invocation: true
---

# Verificar ambiente de autonomia

## Quando

Após alterar `agent/`, `scripts/verify-agent.sh` ou o contrato em `docs/ambiente-autonomia-prototipo.md`; antes de declarar fatia da Etapa 7 pronta.

## Pré-requisitos

- `./scripts/fetch-model.sh` já rodado (GGUF em `models/`)
- `LIBCLANG_PATH` / `BINDGEN_EXTRA_CLANG_ARGS` se necessário (ver `AGENTS.md`)
- `PATH` com `$HOME/.cargo/bin` e `$HOME/.local/bin`
- Runtime buildável (`cargo build -p ia-livre-runtime`) — o agente consome via subprocesso

## Comandos

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
make verify-agent
```

Sucesso: linha contendo `GATE_OK: autonomia` e marcadores `IA_LIVRE_TOOL_OK`, `IA_LIVRE_MEMORY_OK`, `IA_LIVRE_AGENT_OK`.

Timeout: `VERIFY_AGENT_TIMEOUT=600 make verify-agent`.

## Não fazer

- Não substituir `make verify` / `verify-runtime` / `verify-node`
- Não exigir QEMU/UEFI nem o nó P2P neste gate
