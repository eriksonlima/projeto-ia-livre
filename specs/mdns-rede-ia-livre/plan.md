# Plan — mDNS real na Rede IA Livre (além do skip)

## Abordagem

Três fatias **verticais** até o Pronto quando da Etapa 50. Base: `node/` E39 (bootstrap + flag `--disc-mdns` placeholder). Ambiente: **host Linux** `std`. **Não** puxar libp2p/DHT. **Não** tocar kernel/runtime/agent/harness.

Ordem: contrato mDNS (doc + regras) → implementação anúncio/resolução → gate opt-in + AGENTS.

### Task 1 — Contrato mDNS real (atualizar docs E39)

1. Atualizar `docs/rede-descoberta-wan.md`: remover “implementação adiada”; descrever anúncio/resolução `_ia-livre._tcp`, marcadores, precedência dial, skip/force do gate.
2. Fixar **uma** regra de precedência: `--peer` > bootstrap > mdns > LAN; se `--disc-mdns` coexiste com bootstrap, bootstrap diala e mdns **ainda anuncia** (recomendado) — gravar na doc.
3. Ponte em `docs/rede-ia-livre-v1.md` (E50 em vez de “skip E39”).
4. Esboçar variáveis: `VERIFY_NODE_MDNS_SKIP` (default 1), `VERIFY_NODE_MDNS_FORCE` (opt-in falha se multicast down).
5. Escolher crate candidata (`mdns-sd` ou equivalente leve) e anotar na doc/plan — confirmação final na Task 2 se build falhar.

Critério parcial: contrato legível; **sem** código obrigatório (só docs/ponte).

### Task 2 — Anúncio + resolução mDNS em `node/`

1. Dep Rust leve em `node/Cargo.toml` (sem libp2p).
2. Com `--disc-mdns`: registrar serviço `_ia-livre._tcp` → TCP local; browse/resolve peers; dial até sessão (reutilizar `run_session` / IDENT).
3. Emitir `IA_LIVRE_DISC_MODE=mdns` + `IA_LIVRE_DISC_OK` no sucesso; remover/`não` emitir placeholder `IA_LIVRE_DISC_MDNS=skip` no path feliz.
4. Timeout/falha multicast: log honesto; não quebrar accept/`--peer`/bootstrap.
5. Smoke manual: dois processos `--disc-mdns` na mesma máquina (sem `--peer`).

Critério parcial: B descobre A via mDNS no loopback/LAN e completa v1; `cargo build -p ia-livre-node` ok.

### Task 3 — Gate opt-in + AGENTS + fechamento

1. Estender `scripts/verify-node.sh`: estágio `mdns` quando `VERIFY_NODE_MDNS_SKIP≠1`; A e B com `--disc-mdns`; B sem peer/bootstrap; portas distintas (ex. TCP 7403/7404 ou reutilizar B2 com cuidado de cleanup).
2. Skip default: imprimir `IA_LIVRE_DISC_MDNS_SKIP=…` exit 0 no estágio; com skip=0 exigir `DISC_MODE=mdns` + `DISC_OK`; FORCE documentado.
3. Atualizar `AGENTS.md` (Como rodar / Como verificar); README (`readme-por-fatia`).
4. `make verify-node` verde com skip default (peer+bootstrap intactos).
5. Não marcar etapa `feita` aqui.

Critério parcial: gate documentado; prova forçável; docs/AGENTS sincronizados.

### Defaults canônicos (orientação)

| Item | Valor |
|------|-------|
| Serviço | `_ia-livre._tcp` |
| Flag | `--disc-mdns` |
| TCP smoke A/B | `7400` / `7401` (ou portas dedicadas no gate mdns para não colidir com estágios) |
| Timeout gate / estágio | `VERIFY_NODE_TIMEOUT` (45s) — mdns pode precisar sleep extra pós-anúncio |
| Skip default | `VERIFY_NODE_MDNS_SKIP=1` |
| Forçar prova | `VERIFY_NODE_MDNS_SKIP=0` |
| Forçar falha se down | `VERIFY_NODE_MDNS_FORCE=1` |
| Marcadores | `IA_LIVRE_DISC_MODE=mdns`, `IA_LIVRE_DISC_OK` |

### Notas de implementação (orientação)

- Preferir `node/src/mdns.rs` ou funções em `discovery.rs`.
- Filtrar anúncios do próprio nó (mesmo PeerId / mesma porta).
- Não dialar se `peer_ok` já true.
- Preferir API que conviva com tokio (spawn_blocking se crate sync).
- Manter `! grep -qi libp2p node/Cargo.toml` no gate AGENTS.

## Arquivos prováveis

- `node/src/main.rs`, `node/src/discovery.rs`, `node/src/mdns.rs` (novo, provável)
- `node/Cargo.toml` — dep mDNS
- `docs/rede-descoberta-wan.md`
- `docs/rede-ia-livre-v1.md`
- `scripts/verify-node.sh`
- `AGENTS.md`
- `README.md` (avaliar)
- `specs/mdns-rede-ia-livre/tasks.md`

Não editar como entrega desta etapa: `kernel/`, `runtime/`, `agent/`, harness, status `feita` no `ROADMAP.md` (agente principal).

## Dependências

- Etapa 39 feita (bootstrap + flag reservada).
- Host: Rust estável; multicast LAN/loopback desejável para prova.
- Sem QEMU, GGUF, cmake/libclang para o nó.
- Lease: `memory-bank/AGENT_CLAIM.md`.

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
cargo build -p ia-livre-node

# Smoke mDNS (após Task 2) — dois terminais:
# A: cargo run -p ia-livre-node -- --tcp-port 7400 --node-id alice --disc-mdns
# B: cargo run -p ia-livre-node -- --tcp-port 7401 --node-id bob --disc-mdns

make verify-node
# Prova opt-in (quando multicast ok):
# VERIFY_NODE_MDNS_SKIP=0 make verify-node

grep -q 'IA_LIVRE_DISC_MODE=mdns' docs/rede-descoberta-wan.md
grep -q '_ia-livre._tcp' docs/rede-descoberta-wan.md
! grep -qi 'libp2p' node/Cargo.toml
```

Gate da etapa = checklist da spec + `make verify-node` (skip default verde) + evidência de estágio mdns **ou** skip honesto documentado. Gates kernel/runtime/agent/harness **inalterados**.
