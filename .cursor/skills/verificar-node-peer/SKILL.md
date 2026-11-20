---
name: verificar-node-peer
description: >-
  Roda o gate do protótipo ia-livre-node (Etapa 6): make verify-node
  confirma IA_LIVRE_PEER_OK e IA_LIVRE_MSG_OK entre dois processos.
  Use ao validar mudanças em node/ ou no script verify-node.
disable-model-invocation: true
---

# Verificar nó Rede IA Livre

## Quando usar

Após alterar `node/`, `scripts/verify-node.sh` ou a doc do protocolo; antes de declarar fatia do nó pronta.

## Pré-requisitos

- Rust no host; crate `node/` no workspace
- `export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"`
- Preferir `CARGO_TARGET_DIR` apontando para `./target` do repo (evitar binário stale)

## Comandos (gate)

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
cd /caminho/para/projeto-ia-livre

test -d node && test -f node/Cargo.toml && test -f node/src/main.rs
test -f scripts/verify-node.sh && test -f docs/rede-ia-livre-prototipo.md
make verify-node
grep -q 'IA_LIVRE_PEER_OK' node/src/main.rs
grep -q 'IA_LIVRE_MSG_OK' node/src/main.rs
```

Sucesso: `GATE_OK: nó Rede IA Livre — PEER_OK + MSG_OK`.

Timeout: `VERIFY_NODE_TIMEOUT=60 make verify-node`.

## Manual (dois terminais)

```bash
cargo run -p ia-livre-node -- --tcp-port 7400 --node-id alice
cargo run -p ia-livre-node -- --tcp-port 7401 --node-id bob --peer 127.0.0.1:7400
```

Esperado em ambos: `IA_LIVRE_PEER_OK` e `IA_LIVRE_MSG_OK`.

## Pronto quando

- `make verify-node` exit 0
- Marcadores `IA_LIVRE_PEER_OK` e `IA_LIVRE_MSG_OK` presentes

## Notas

- Fallback documentado: `--peer host:port` se UDP falhar (usado no gate)
- Não exige QEMU, GGUF nem runtime de inferência
- Gates do kernel/runtime permanecem separados
