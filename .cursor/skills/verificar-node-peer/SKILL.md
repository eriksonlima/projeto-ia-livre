---
name: verificar-node-peer
description: >-
  Roda o gate do nó Rede IA Livre v1 (Etapas 6/23): make verify-node
  confirma PEER_OK, MSG_OK, IDENT_OK e PING_OK entre dois processos.
  Use ao validar mudanças em node/ ou no script verify-node.
disable-model-invocation: true
---

# Verificar nó Rede IA Livre v1

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
test -f scripts/verify-node.sh && test -f docs/rede-ia-livre-v1.md
make verify-node
grep -q 'IA_LIVRE_IDENT_OK' node/src/session.rs
grep -q 'IA_LIVRE_PING_OK' node/src/session.rs
```

Sucesso: `GATE_OK: nó Rede IA Livre v1 — PEER_OK + MSG_OK + IDENT_OK + PING_OK`.

Timeout: `VERIFY_NODE_TIMEOUT=60 make verify-node`.

## Manual (dois terminais)

```bash
cargo run -p ia-livre-node -- --tcp-port 7400 --node-id alice
cargo run -p ia-livre-node -- --tcp-port 7401 --node-id bob --peer 127.0.0.1:7400
```

Esperado em ambos: `IA_LIVRE_PROTO=v1`, `IA_LIVRE_IDENT_OK`, `IA_LIVRE_PEER_OK`, `IA_LIVRE_MSG_OK`, `IA_LIVRE_PING_OK`.

## Pronto quando

- `make verify-node` exit 0
- Marcadores `PEER_OK`, `MSG_OK`, `IDENT_OK`, `PING_OK` presentes

## Notas

- Contrato: `docs/rede-ia-livre-v1.md`
- Fallback documentado: `--peer host:port` se UDP falhar (usado no gate)
- `--node-id` é apelido; âncora = PeerId ed25519
- Não exige QEMU, GGUF nem runtime de inferência
- Gates do kernel/runtime permanecem separados
