---
name: verificar-agent-autonomia
description: >-
  Roda o gate de autonomia E7+v1 (make verify-agent): TOOL/MEMORY/AGENT_OK
  + MEMORY_POLICY_OK + TOOLS_USED≥2. Use ao validar agent/ ou Etapas 7/24.
disable-model-invocation: true
---

# Verificar autonomia (E7 + v1)

## Quando

Após alterar `agent/`, `scripts/verify-agent.sh` ou docs de autonomia; antes de declarar fatia pronta.

## Pré-requisitos

- `./scripts/fetch-model.sh` já rodado (GGUF em `models/`)
- `LIBCLANG_PATH` / `BINDGEN_EXTRA_CLANG_ARGS` se necessário (ver `AGENTS.md`)
- `PATH` com `$HOME/.cargo/bin` e `$HOME/.local/bin`
- Runtime buildável (`cargo build -p ia-livre-runtime`) — o agente consome via subprocesso

## Comandos

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
test -f docs/desenho-autonomia-v1.md
make verify-agent
grep -q 'IA_LIVRE_MEMORY_POLICY_OK' agent/src/main.rs
grep -q 'IA_LIVRE_TOOLS_USED' agent/src/main.rs
```

Sucesso: `GATE_OK: autonomia v1` com `MEMORY_POLICY_OK`, `RUNTIME_USED=1`, `TOOLS_USED`≥2, `TOOL_OK`, `MEMORY_OK`, `AGENT_OK`.

Timeout: `VERIFY_AGENT_TIMEOUT=600 make verify-agent`.

## Não fazer

- Não substituir `make verify` / `verify-runtime` / `verify-node`
- Não exigir QEMU/UEFI nem o nó P2P neste gate
