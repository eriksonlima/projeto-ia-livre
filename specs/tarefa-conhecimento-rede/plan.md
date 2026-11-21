# Plan — Tarefa/conhecimento mínimo na Rede (além de PING)

## Abordagem

Três fatias **verticais** até o Pronto quando da Etapa 51. Base: protocolo v1 E23 + sessão MSG/PING em `node/`. Ambiente: **host Linux** `std`. **Não** puxar libp2p/marketplace/KNOW. **Não** tocar kernel/runtime/agent/harness/descoberta além de regressão.

Ordem: contrato no doc v1 → framing + sessão → gate + AGENTS.

### Task 1 — Contrato TASK/TASK_ACK em `rede-ia-livre-v1`

1. Atualizar `docs/rede-ia-livre-v1.md`: tabela de mensagens, fluxo canônico, prova (`task_id` + texto), marcador `IA_LIVRE_TASK_OK`.
2. Deixar explícito: `TASK_ACK` ≠ `ACK` de MSG; KNOW/marketplace fora.
3. Esboçar ordem pós-IDENT: MSG → PING → TASK.
4. Ponte curta em `AGENTS.md` só se necessário na Task 3 (esta fatia = doc contrato).

Critério parcial: contrato legível; **sem** código obrigatório.

### Task 2 — Framing + sessão TASK/TASK_ACK em `node/`

1. `proto.rs`: `format_task` / `parse_task` / `format_task_ack` / `parse_task_ack`.
2. `session.rs`: após MSG_OK + PING_OK, dialer envia `TASK`; peer responde `TASK_ACK`; ambos validam `task_id`.
3. Emitir `IA_LIVRE_TASK_OK` uma vez; não quebrar MSG/PING.
4. Smoke: dois processos `--peer` na mesma máquina.

Critério parcial: `cargo build -p ia-livre-node` + smoke com `IA_LIVRE_TASK_OK`.

### Task 3 — Gate verify-node + AGENTS + fechamento

1. Estender `scripts/verify-node.sh` (estágio peer) para exigir `IA_LIVRE_TASK_OK`.
2. Atualizar `AGENTS.md` (Como rodar / Como verificar); README (`readme-por-fatia`).
3. Confirmar regressão bootstrap + mDNS skip default.
4. Não marcar etapa `feita` aqui.

Critério parcial: `make verify-node` verde com `TASK_OK`; docs/AGENTS sincronizados.

### Defaults canônicos (orientação)

| Item | Valor |
|------|-------|
| Tipos | `TASK` / `TASK_ACK` |
| Prova `task_id` | `t1` (ou hex curto documentado) |
| Prova texto | `prova-task-v1` |
| Marcador | `IA_LIVRE_TASK_OK` |
| Ordem | após `PING_OK` |
| TCP smoke A/B | `7400` / `7401` |
| Timeout | `VERIFY_NODE_TIMEOUT` (45s) |
| KNOW | fora |

### Notas de implementação (orientação)

- Parse: strip_prefix `"TASK_ACK "` antes de qualquer lógica `ACK`; `"TASK "` com split em `task_id` + resto.
- Reutilizar `emit_once` como MSG/PING.
- Preferir dialer inicia TASK (simétrico ao PING).
- Manter `! grep -qi libp2p node/Cargo.toml`.

## Arquivos prováveis

- `docs/rede-ia-livre-v1.md`
- `node/src/proto.rs`, `node/src/session.rs` (e `main.rs` só se comentário/help)
- `scripts/verify-node.sh`
- `AGENTS.md`
- `README.md` (avaliar)
- `Makefile` (só se alvo dedicado for necessário)
- `specs/tarefa-conhecimento-rede/tasks.md`

Não editar como entrega desta etapa: `kernel/`, `runtime/`, `agent/`, harness, `mdns.rs` (salvo regressão acidental), status `feita` no `ROADMAP.md` (agente principal).

## Dependências

- Etapa 23 feita (framing v1).
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

grep -q 'IA_LIVRE_TASK_OK' docs/rede-ia-livre-v1.md
grep -q 'TASK_ACK' docs/rede-ia-livre-v1.md
grep -q 'IA_LIVRE_TASK_OK' scripts/verify-node.sh
! grep -qi 'libp2p' node/Cargo.toml
```

Gate da etapa = checklist da spec + `make verify-node` exigindo `TASK_OK`. Gates kernel/runtime/agent/harness **inalterados**.
