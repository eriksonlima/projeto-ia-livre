# Plan — Protocolo Rede IA Livre v1 (impl. em node/)

## Abordagem

Três fatias **verticais** até o Pronto quando da Etapa 23. Base: crate `node/` da Etapa 6. Ambiente fixo: **host Linux** + TCP/UDP + crates crypto leves. **Não** puxar libp2p. **Não** tocar kernel/runtime/agent além de pontes documentais do nó.

Ordem: identidade+HELLO → IDENT+MSG/ACK → PING/PONG+docs/gate.

### Task 1 — Identidade ed25519 + HELLO UDP assinado

1. Adicionar dependência ed25519 (ex. `ed25519-dalek` + `rand` / `sha2` se o fingerprint exigir).
2. Gerar ou carregar chave (path documentado, fora do git); derivar `PeerId` (forma única fixada).
3. Emitir `HELLO v1 …` assinado no anúncio UDP; validar sig + PeerId≡fingerprint na recepção; dial só após HELLO válido (além do caminho `--peer`).
4. Emitir marcadores úteis (`IA_LIVRE_PEER_ID=…`, opcional `IA_LIVRE_PROTO=v1`); manter `--node-id` como apelido.
5. Atualizar doc parcial (framing HELLO v1 + identidade) em `docs/rede-ia-livre-prototipo.md` ou doc v1 com ponte.
6. `cargo build -p ia-livre-node` sucede; smoke manual possível; gate completo pode ainda depender das Tasks 2–3 se IDENT ainda não existir — se Task 1 quebrar `verify-node`, documentar e restaurar caminho mínimo ou adiar breaking até Task 2.

Critério parcial: chave+PeerId+HELLO assinado no código e documentados; HELLO inválido não autentica peer.

### Task 2 — IDENT no TCP + sessão MSG/ACK

1. Após connect/accept: handshake `IDENT` mútuo (PeerId, pubkey, nonce, sig) antes de MSG.
2. Só então fluxo de prova `MSG ola-rede-ia-livre` / `ACK …` e marcadores `IA_LIVRE_PEER_OK` / `IA_LIVRE_MSG_OK` (e opcional `IA_LIVRE_IDENT_OK`).
3. `--peer` continua dialando e completando IDENT+MSG (caminho do gate).
4. Doc: tabela IDENT + fluxo canônico; rejeição se IDENT falhar.

Critério parcial: dois processos com `--peer` completam IDENT + MSG/ACK; marcadores PEER_OK + MSG_OK presentes.

### Task 3 — PING/PONG + docs finais + gate

1. Após sessão autenticada: pelo menos um ciclo `PING`/`PONG` (marcador `IA_LIVRE_PING_OK` opcional mas preferível).
2. Estender ou preservar `scripts/verify-node.sh` / `make verify-node`; documentar qualquer check novo.
3. Fechar `AGENTS.md` (Como rodar / Como verificar), doc do protocolo v1, pontes no desenho (checklist “entra no próximo protótipo” → feito), README avaliado.
4. Não marcar Etapa 23 `feita` aqui — agente principal após gate + revisor.

Critério parcial: `make verify-node` verde; PING/PONG documentados; independência do SO explícita.

### Defaults canônicos (orientação)

| Item | Valor |
|------|-------|
| TCP A / B | `7400` / `7401` |
| UDP | `7410` |
| Mensagem de prova | `ola-rede-ia-livre` |
| Timeout gate | 45s (`VERIFY_NODE_TIMEOUT`) |
| Versão protocolo | `v1` |
| PeerId | hex da pubkey ed25519 (preferência) — fixar na Task 1 |

### Notas de implementação (orientação, não código)

- Preferir módulos mínimos em `node/src/` (`identity`, `proto`, `discover`, `session`) se `main.rs` crescer demais; não obrigatório se a fatia caber.
- Chave: ex. `build/node-keys/<apelido>.key` ou `--key-file`; criar dir sob `build/` (já gitignored).
- Assinatura HELLO/IDENT: mensagem canônica concatenada documentada (evita ambiguidade de whitespace).
- Gate: manter dois processos + `--peer` no B; logs em tempfile; cleanup com `trap`.
- Não adicionar features GPU/QEMU ao nó.

## Arquivos prováveis

- `node/Cargo.toml` — deps ed25519 (+ rand/sha2/hex se necessário)
- `node/src/main.rs` e/ou módulos sob `node/src/`
- `docs/rede-ia-livre-prototipo.md` e/ou `docs/rede-ia-livre-v1.md`
- `docs/desenho-protocolo-rede-ia-livre.md` — checklist implementação (ponte)
- `scripts/verify-node.sh`
- `Makefile` — só se o alvo `verify-node` precisar ajuste
- `AGENTS.md` — Como rodar / Como verificar do nó
- `README.md` — só se a capa ficar enganosa
- `specs/protocolo-rede-v1/tasks.md` — marcar fatias

Não editar como entrega: `kernel/`, `runtime/`, `agent/`, harness, `AGENT_CLAIM.md`, `ROADMAP.md` / `BACKLOG.md` (atualização de status = agente principal).

## Dependências

- Etapas 6 e 14 feitas (protótipo + ADR 0004 / desenho).
- Host: Rust estável; loopback para o gate.
- Sem QEMU, GGUF, cmake/libclang para o nó.
- Sem depender do SO IA Livre.
- Coordenação: Etapa 19 pode estar `em_andamento` noutro agente — trabalhar só na branch desta etapa e nos arquivos do nó/docs P2P.

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
cargo build -p ia-livre-node
make verify-node
# Doc / contratos
grep -qE 'ed25519|PeerId|IDENT|PING' docs/rede-ia-livre-prototipo.md docs/rede-ia-livre-v1.md 2>/dev/null || \
  grep -qE 'ed25519|PeerId|IDENT|PING' docs/rede-ia-livre-prototipo.md
grep -q 'IA_LIVRE_PEER_OK' node/src/main.rs
grep -q 'IA_LIVRE_MSG_OK' node/src/main.rs
# Sem libp2p
! grep -qi 'libp2p' node/Cargo.toml
```

Gate da etapa = checklist da spec + `make verify-node` verde. Gates kernel/runtime/agent/harness **permanecem** e não são substituídos.
