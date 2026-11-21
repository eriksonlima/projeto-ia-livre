# Plan — Rede IA Livre além de v1 (descoberta WAN mínima)

## Abordagem

Três fatias **verticais** até o Pronto quando da Etapa 39. Base: `node/` v1 (E23). Ambiente: **host Linux** + loopback para o gate. **Não** puxar libp2p/DHT. **Não** tocar kernel/runtime/agent/harness.

Ordem: contrato bootstrap → implementação dial bootstrap → mDNS opt-in + gate estendido + docs/`AGENTS.md`.

### Task 1 — Contrato de descoberta WAN + CLI/bootstrap (doc)

1. Criar `docs/rede-descoberta-wan.md`: modos (`lan`, `peer`, `bootstrap`, `mdns`), formato de lista/arquivo, segurança (bootstrap ≠ identidade), marcadores `DISC_*`, limites e futuro relay/DHT (só desenho).
2. Fixar flags: `--bootstrap`, `--bootstrap-file`, precedência vs `--peer` (documentar: `--peer` explícito vence ou são mutuamente complementares — **uma** regra).
3. Ponte em `docs/rede-ia-livre-v1.md` e `docs/desenho-protocolo-rede-ia-livre.md`.
4. Esboço de extensão do gate em comentário no plano da Task 3 / seção «Verificação» da doc.
5. ADR 0004: addendum curto ou nota na doc se bootstrap for extensão do dial multiendereço — sem redecidir stack.

Critério parcial: contrato legível + flags fixadas; **sem** código obrigatório nesta task (só doc/spec alinhada).

### Task 2 — Implementação bootstrap em `node/`

1. Parser `--bootstrap` (lista `host:port`) e `--bootstrap-file`.
2. Loop de dial aos endpoints até sucesso ou esgotamento; emitir `IA_LIVRE_DISC_MODE=bootstrap` e `IA_LIVRE_DISC_OK` ao iniciar sessão autenticada (alinhado ao contrato Task 1).
3. Integrar com `dial_peer` / sessão existente — **reutilizar** IDENT/MSG/PING v1.
4. Preservar HELLO UDP e `--peer`; smoke manual: A sobe, B só com bootstrap.
5. `cargo build -p ia-livre-node` sucede.

Critério parcial: B alcança A via bootstrap no loopback; marcadores v1 (`PEER_OK`, etc.) no fluxo.

### Task 3 — Gate estendido + mDNS opt-in + fechamento

1. Estender `scripts/verify-node.sh`: fase bootstrap (B sem `--peer`) + regressão `--peer` (mesmo script ou flag `VERIFY_NODE_LEGACY_PEER=1`).
2. mDNS: flag `--disc-mdns` (nome fixado na Task 1) com crate leve; se não couber no tempo, registrar skip `VERIFY_NODE_MDNS_SKIP` e manter só bootstrap no gate — **honestidade**.
3. Atualizar `AGENTS.md` (Como rodar / Como verificar); README (`readme-por-fatia`).
4. `make verify-node` verde; não marcar etapa `feita` aqui.

Critério parcial: gate cobre bootstrap + checks v1; doc e AGENTS sincronizados.

### Defaults canônicos (orientação)

| Item | Valor |
|------|-------|
| TCP A / B | `7400` / `7401` |
| UDP | `7410` |
| Bootstrap gate | `127.0.0.1:7400` |
| Arquivo exemplo | `build/node-bootstrap.txt` (gitignored via `build/`) |
| Timeout gate | 45s (`VERIFY_NODE_TIMEOUT`) |
| Prova MSG | `ola-rede-ia-livre` (inalterada) |
| Serviço mDNS | `_ia-livre._tcp.local` (se implementado) |

### Notas de implementação (orientação)

- Preferir módulo `node/src/discovery.rs` (bootstrap + mDNS) se `main.rs` crescer.
- Bootstrap: tratar `localhost` e `127.0.0.1` explicitamente no gate.
- Não duplicar sessão TCP se `--peer` e bootstrap apontam ao mesmo host — política documentada na Task 1.
- Gate: logs em tempfile; cleanup com `trap` (padrão E23).

## Arquivos prováveis

- `node/src/main.rs`, `node/src/discovery.rs` (novo, provável)
- `node/Cargo.toml` — dep mDNS opcional (feature flag preferível)
- `docs/rede-descoberta-wan.md` (novo)
- `docs/rede-ia-livre-v1.md`, `docs/desenho-protocolo-rede-ia-livre.md`
- `docs/adr/0004-stack-protocolo-rede-ia-livre.md` — addendum opcional
- `scripts/verify-node.sh`, `Makefile` (se necessário)
- `AGENTS.md`
- `specs/rede-descoberta-wan/tasks.md`

Não editar como entrega desta etapa: `kernel/`, `runtime/`, `agent/`, harness, `ROADMAP.md` status (agente principal).

## Dependências

- Etapas 23 feita (v1 + gate).
- Host: Rust estável; loopback.
- Sem QEMU, GGUF, cmake/libclang para o nó.
- Coordenação: respeitar lease em `memory-bank/AGENT_CLAIM.md`.

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
cargo build -p ia-livre-node

# Smoke bootstrap (após Task 2)
# Terminal A: cargo run -p ia-livre-node -- --tcp-port 7400 --node-id alice
# Terminal B: cargo run -p ia-livre-node -- --tcp-port 7401 --node-id bob \
#   --bootstrap 127.0.0.1:7400

make verify-node
test -f docs/rede-descoberta-wan.md
grep -q 'IA_LIVRE_DISC_' node/src/main.rs node/src/discovery.rs 2>/dev/null || \
  grep -q 'DISC_' docs/rede-descoberta-wan.md
! grep -qi 'libp2p' node/Cargo.toml
```

Gate da etapa = checklist da spec + `make verify-node` com cenário bootstrap. Gates kernel/runtime/agent/harness **inalterados** como critério desta etapa.