# Plan — Descoberta WAN (NAT/DHT/relay)

## Abordagem

Três fatias verticais até o Pronto quando da Etapa 67. Base: `node/` E39/E50 (bootstrap + mDNS). Ambiente: **host Linux** `std`. **Preferir A** (relay TCP mínimo + gate dois nós). **B** (ADR + skip) só se A for inviável com motivo medido. DHT = stub/adiado se A fechar. **Não** puxar libp2p. **Não** tocar kernel/runtime/agent/harness/TCP guest.

Ordem: contrato + decisão A/B → implementação relay (ou ADR B) → gate + AGENTS.

### Task 1 — Contrato WAN/relay + decisão A/B

1. Atualizar `docs/rede-descoberta-wan.md`: modo `relay` (ou bloqueio); flags candidatas; precedência dial (`--peer` > bootstrap > **relay** > mdns); limites loopback ≠ internet pública; DHT adiado/stub.
2. Fixar modelo do relay mínimo (recomendado): processo R com `--relay-listen` + clientes com `--relay host:port` que introduzem/encaminham até peer alvo — **uma** regra escrita.
3. Fixar marcadores: A → `IA_LIVRE_DISC_MODE=relay` + `IA_LIVRE_DISC_OK` (+ opcional `IA_LIVRE_RELAY_OK`); B → `IA_LIVRE_DISC_RELAY_SKIP=…` / `DISC_WAN_BLOCK=…`.
4. Fixar nome do gate: estágio em `verify-node` **ou** `make verify-node-relay`.
5. Se já houver evidência de inviabilidade de A na Task 1: abrir ADR `0025` e seguir caminho B nas tasks seguintes (sem código teatral).
6. Ponte curta em `rede-ia-livre-v1.md` / addendum ADR 0004 se A for extensão natural.

Critério parcial: contrato legível; decisão A ou B registrada; **sem** exigir código de produto além de docs (salvo esboço de flag).

### Task 2 — Relay em `node/` (A) ou ADR+marcadores (B)

**Caminho A:**

1. CLI `--relay` / `--relay-listen` (nomes da Task 1) em `main.rs` + módulo `relay.rs` ou extensão de `discovery.rs`.
2. Dial/forward via R até sessão IDENT; emitir `DISC_MODE=relay` + `DISC_OK`.
3. Falha/timeout: log honesto; não quebrar peer/bootstrap/mdns.
4. Smoke: três processos no loopback (R, A, B).
5. **Sem** libp2p; preferir só TCP/`tokio`.

**Caminho B:**

1. ADR `0025` (relay/WAN mínimo inviável nesta fatia; motivo; reabertura).
2. Runner/estágio que emite skip/bloqueio; **proibido** `DISC_OK`/`RELAY_OK` fingidos.
3. Sem stub teatral de relay.

Critério parcial: A = B alcança A via relay no loopback; B = ADR + marcador honesto.

### Task 3 — Gate + AGENTS + fechamento

1. Estágio relay (A: três processos / dois nós via R; exige marcadores) **ou** skip (B: imprime skip, exit 0).
2. Regressão `make verify-node` (peer + bootstrap + mDNS skip default) verde; ADR 0001.
3. `AGENTS.md` (Como rodar / Como verificar); README (`readme-por-fatia`).
4. Anti-fraude documentada no script (A: exige caminho relay; B: falha se `RELAY_OK` sem implementação).
5. Não marcar etapa `feita` aqui.

Critério parcial: gate documentado; regressão intacta; docs/AGENTS sincronizados.

### Defaults canônicos (orientação)

| Item | Valor |
|------|-------|
| Preferência | A — relay TCP mínimo |
| Fallback | B — ADR `0025` + skip |
| DHT | Stub/adiado se A fecha Pronto quando |
| Flag cliente | `--relay host:port` (Task 1 confirma) |
| Flag servidor | `--relay-listen` (Task 1 confirma) |
| Portas smoke | R `7399`, A `7400`, B `7401` (ajustar se colidir) |
| Marcadores A | `DISC_MODE=relay`, `DISC_OK` |
| Marcadores B | `DISC_RELAY_SKIP=…` |
| Gate | estágio / `verify-node-relay` (Task 1) |
| Timeout | reutilizar `VERIFY_NODE_TIMEOUT` ou `VERIFY_NODE_RELAY_TIMEOUT` |
| libp2p | **proibido** sem ADR nova |

### Notas de implementação (orientação A)

- Relay ≠ identidade: IDENT continua após o caminho.
- Não dialar se `peer_ok` já true.
- Precedência: se `--peer` presente, relay **não** diala (como bootstrap/mdns).
- Cleanup no gate: matar R/A/B em trap.
- Documentar honestamente: prova = atravessar intermediário no loopback, **não** NAT real na internet.

## Arquivos prováveis

- `docs/rede-descoberta-wan.md`
- `docs/rede-ia-livre-v1.md`
- `docs/adr/0004-stack-protocolo-rede-ia-livre.md` (addendum opcional)
- `docs/adr/0025-….md` (só caminho B)
- `node/src/main.rs`, `node/src/discovery.rs`, `node/src/relay.rs` (novo, provável A)
- `node/Cargo.toml` — **sem** libp2p
- `scripts/verify-node.sh` e/ou `scripts/verify-node-relay.sh`
- `Makefile` — target se gate separado
- `AGENTS.md`
- `README.md` (avaliar)
- `docs/glossario.md` — se `DISC_MODE=relay` / skip precisar entrada
- `specs/descoberta-wan-dht-relay/tasks.md`

Não editar como entrega: `kernel/`, `runtime/`, `agent/`, harness, TCP guest, status `feita` no `ROADMAP.md` (agente principal).

## Dependências

- E39 + E50 feitas (`node/` + `verify-node`)
- Host: Rust estável; loopback TCP
- Sem QEMU, GGUF, cmake para o nó
- Lease: `memory-bank/AGENT_CLAIM.md`

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
cargo build -p ia-livre-node

# Smoke A (após Task 2) — três processos; ver docs/rede-descoberta-wan.md

make verify-node
# + estágio relay (A) ou skip documentado (B)
# make verify-node-relay   # se target separado na Task 1

! grep -qi 'libp2p' node/Cargo.toml
grep -qE 'relay|RELAY|DISC_WAN' docs/rede-descoberta-wan.md
```

Gate da etapa = checklist da spec + regressão `verify-node` + evidência A (relay) **ou** B (ADR+skip). Gates kernel/runtime/agent/harness **inalterados**.
