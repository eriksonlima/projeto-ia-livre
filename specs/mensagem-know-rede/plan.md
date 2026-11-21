# Plan — Mensagem KNOW na Rede

## Abordagem

Três fatias **verticais** até o Pronto quando da Etapa 68. Base: protocolo v1 E23 + TASK E51 em `node/`. Ambiente: **host Linux** `std`. **Não** puxar marketplace, persistência, DHT nem libp2p. **Não** tocar kernel/runtime/agent/harness/descoberta além de regressão.

Ordem: contrato no doc v1 → framing + sessão → gate + AGENTS.

### Task 1 — Contrato KNOW/KNOW_ACK em `rede-ia-livre-v1`

1. Atualizar `docs/rede-ia-livre-v1.md`: tabela de mensagens, fluxo canônico (após TASK), prova (`know_id=k1` + `prova-know-v1`), marcador `IA_LIVRE_KNOW_OK`.
2. Deixar explícito: `KNOW_ACK` ≠ `ACK` de MSG ≠ `TASK_ACK`; marketplace/persistência/DHT fora.
3. Remover “tipo KNOW fora” do núcleo framing; manter marketplace/store fora.
4. Ponte curta em `AGENTS.md` só se necessário na Task 3 (esta fatia = doc contrato).

Critério parcial: contrato legível; **sem** código obrigatório.

### Task 2 — Framing + sessão KNOW/KNOW_ACK em `node/`

1. `proto.rs`: constantes `PROOF_KNOW_ID` / `PROOF_KNOW_TEXT`; `format_know` / `parse_know` / `format_know_ack` / `parse_know_ack` (espelho de TASK).
2. `session.rs`: após `TASK_OK`, dialer envia `KNOW`; peer responde `KNOW_ACK`; ambos validam `know_id`.
3. Emitir `IA_LIVRE_KNOW_OK` uma vez; não quebrar MSG/PING/TASK.
4. Smoke: dois processos `--peer` na mesma máquina.

Critério parcial: `cargo build -p ia-livre-node` + smoke com `IA_LIVRE_KNOW_OK`.

### Task 3 — Gate verify-node + AGENTS + fechamento

1. Estender `scripts/verify-node.sh` (estágio peer) para exigir `IA_LIVRE_KNOW_OK` (além de `TASK_OK`).
2. Atualizar `AGENTS.md` (Como rodar / Como verificar); README (`readme-por-fatia`).
3. Confirmar regressão bootstrap + mDNS skip default (+ relay opt-in intacto).
4. Não marcar etapa `feita` aqui.

Critério parcial: `make verify-node` verde com `KNOW_OK`; docs/AGENTS sincronizados.

### Defaults canônicos (orientação)

| Item | Valor |
|------|-------|
| Tipos | `KNOW` / `KNOW_ACK` |
| Prova `know_id` | `k1` |
| Prova texto | `prova-know-v1` |
| Marcador | `IA_LIVRE_KNOW_OK` |
| Ordem | após `TASK_OK` |
| TCP smoke A/B | `7400` / `7401` |
| Timeout | `VERIFY_NODE_TIMEOUT` (45s) |
| Marketplace / store | fora |

### Notas de implementação (orientação)

- Parse: strip_prefix `"KNOW_ACK "` antes de qualquer lógica genérica `ACK`; `"KNOW "` com split em `know_id` + resto (mesmo padrão de `TASK`).
- Reutilizar `emit_once` como MSG/PING/TASK.
- Preferir dialer inicia KNOW após `task_ok` (simétrico ao TASK pós-`ping_ok`).
- Critério de saída da sessão: incluir `know_ok` junto com msg/ping/task.
- Manter `! grep -qi libp2p node/Cargo.toml`.

## Arquivos prováveis

- `docs/rede-ia-livre-v1.md`
- `node/src/proto.rs`, `node/src/session.rs` (e `main.rs` só se comentário/help)
- `scripts/verify-node.sh`
- `AGENTS.md`
- `README.md` (avaliar)
- `Makefile` (só se alvo dedicado for necessário)
- `specs/mensagem-know-rede/tasks.md`

Não editar como entrega desta etapa: `kernel/`, `runtime/`, `agent/`, harness, `mdns.rs` / relay (salvo regressão), status `feita` no `ROADMAP.md` (agente principal).

## Dependências

- Etapa 51 feita (`TASK`/`TASK_ACK` + `IA_LIVRE_TASK_OK`).
- Host: Rust estável; loopback TCP.
- Sem QEMU, GGUF, cmake/libclang para o nó.
- Lease: `memory-bank/AGENT_CLAIM.md`.

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
cargo build -p ia-livre-node

# Smoke (após Task 2) — dois terminais:
# A: cargo run -p ia-livre-node -- --tcp-port 7400 --node-id alice
# B: cargo run -p ia-livre-node -- --tcp-port 7401 --node-id bob --peer 127.0.0.1:7400

make verify-node

grep -q 'IA_LIVRE_KNOW_OK' docs/rede-ia-livre-v1.md
grep -q 'KNOW_ACK' docs/rede-ia-livre-v1.md
grep -q 'IA_LIVRE_KNOW_OK' scripts/verify-node.sh
! grep -qi 'libp2p' node/Cargo.toml
```

Gate da etapa = checklist da spec + `make verify-node` exigindo `KNOW_OK`. Gates kernel/runtime/agent/harness/relay **inalterados**.
