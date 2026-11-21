# Spec — Tarefa/conhecimento mínimo na Rede (além de PING)

Etapa 51 · Issue [#51](https://github.com/eriksonlima/projeto-ia-livre/issues/51)  
Depende: Etapa 23 (protocolo v1: IDENT / MSG / ACK / PING / PONG).  
Origem backlog: **B45**.

---

## Resultado visível

O crate `node/` (`ia-livre-node`) troca, após IDENT, um ciclo **TASK → TASK_ACK** no framing TCP v1, além de MSG/PING existentes, **sem** marketplace e **sem** exigir o SO IA Livre (ADR 0001):

1. **Tipo novo** — mensagem `TASK` com id + payload de texto curto (prova canônica documentada).
2. **ACK correspondente** — `TASK_ACK` ecoando o mesmo `task_id` (espelha o padrão PING/PONG; **não** reutiliza o `ACK` de MSG).
3. **Prova em dois nós** — sessão TCP (dial `--peer` ou equivalente já suportado) completa IDENT → MSG/ACK → PING/PONG → **TASK/TASK_ACK**.
4. **Marcador** — `IA_LIVRE_TASK_OK` quando o ciclo TASK/TASK_ACK valida.
5. **Gate** — `make verify-node` (estágio peer ou estágio dedicado) exige `IA_LIVRE_TASK_OK` com marcadores honestos; regressão MSG/PING/bootstrap/mDNS **não** quebra.

Participar da Rede **continua sem** kernel UEFI, QEMU, GGUF nem runtime.

---

## Contexto fixo (não reinventar)

- Contrato v1: [`docs/rede-ia-livre-v1.md`](../../docs/rede-ia-livre-v1.md) — hoje IDENT/MSG/ACK/PING/PONG.
- Framing: `node/src/proto.rs`; sessão: `node/src/session.rs`.
- Descoberta: bootstrap E39 + mDNS E50 (`DISC_*`) — **fora** desta etapa salvo regressão.
- Sem libp2p (`! grep -qi libp2p node/Cargo.toml`).
- ADR 0001 / 0004 — host `std`; stack leve; marketplace/DHT fora.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A** | Só `TASK` + `TASK_ACK` no v1 | **Escolhida** — prova pedido/resposta além de PING; escopo mínimo do Pronto quando |
| **B** | Só `KNOW` + ACK | **Adiada** — conhecimento broadcast tende a escopo de “conteúdo/rede de saber”; fica para etapa futura |
| **C** | `TASK` **e** `KNOW` na mesma etapa | **Rejeitada** — duas superfícies; fatia > mínima |
| **D** | Reutilizar `MSG`/`ACK` com prefixo no texto | **Rejeitada** — não cria tipo de framing; prova frágil; conflita com `ola-rede-ia-livre` |
| **E** | Marketplace / leilão / matching de tarefas | **Rejeitada** — fora do Pronto quando |
| **F** | libp2p / Iroh pubsub | **Rejeitada** — AGENTS + ADR 0004 |
| **G** | Exigir SO / bridge nativa | **Rejeitada** — ADR 0001; B46 é outra demanda |

### Escolha: **A — TASK + TASK_ACK**

| Peça | Escolha nesta etapa |
|------|---------------------|
| Tipos | `TASK` (pedido) e `TASK_ACK` (confirmação do `task_id`) |
| Formato TCP | `TASK <task_id> <texto>\n` / `TASK_ACK <task_id>\n` |
| `task_id` | Token sem espaços (ex. hex curto ou string fixa da prova); UTF-8; documentar restrição |
| Payload | Texto curto sem `\n`; prova canônica (ex. `prova-task-v1`) |
| Ordem na sessão | Após MSG_OK e PING_OK (ou imediatamente após PING); **não** substitui MSG/PING |
| ACK de MSG | `ACK <texto>` **permanece** só para MSG — **não** misturar com TASK |
| KNOW | **Fora** desta etapa (não emitir tipo KNOW) |
| Marcador sucesso | `IA_LIVRE_TASK_OK` (uma vez por sessão de prova) |
| Transporte | TCP pós-IDENT (mesmo path de MSG/PING) |
| Independência SO | Host Linux `std` apenas |
| Marketplace | Nenhum ranking, preço, matching multi-peer ou fila persistente |

### Fluxo canônico (prova — dois nós)

```
UDP HELLO (opcional) / dial --peer
IDENT ↔ IDENT          → IA_LIVRE_IDENT_OK + IA_LIVRE_PEER_OK
MSG / ACK (prova)      → IA_LIVRE_MSG_OK
PING / PONG            → IA_LIVRE_PING_OK
TASK / TASK_ACK        → IA_LIVRE_TASK_OK
```

Exemplo de linhas:

```
TASK t1 prova-task-v1
TASK_ACK t1
```

---

## Conteúdo obrigatório

### 1. Documentação

- Atualizar [`docs/rede-ia-livre-v1.md`](../../docs/rede-ia-livre-v1.md): tabela de mensagens, fluxo, marcador `TASK_OK`, prova canônica, fora de escopo (KNOW/marketplace).
- `AGENTS.md`: Como rodar / Como verificar do nó — exigir `IA_LIVRE_TASK_OK` no gate do nó.
- README: avaliar (`readme-por-fatia`); só atualizar se a capa ficar enganosa.
- ADR nova: **não** exigida (extensão do framing v1 já ADR 0004); só se a fronteira arquitetural mudar.

### 2. Código em `node/`

- `proto.rs`: format/parse de `TASK` e `TASK_ACK`.
- `session.rs`: após ciclo MSG/PING, enviar/receber TASK/TASK_ACK e emitir `IA_LIVRE_TASK_OK`.
- Rejeitar/ignorar linhas malformadas de forma honesta (sem travar peer/bootstrap/mDNS).
- **Não** quebrar MSG/ACK/`ola-rede-ia-livre` nem PING/PONG.

### 3. Gate

- Estender `scripts/verify-node.sh` (preferido) **ou** alvo dedicado `verify-node-task` chamado por `make verify-node`.
- Estágio peer (dois nós) deve exigir `IA_LIVRE_TASK_OK` além de `PEER_OK` / `MSG_OK` / `IDENT_OK` / `PING_OK`.
- Bootstrap + mDNS: regressão intacta; estágio mDNS continua skip default.
- Sem QEMU/GGUF.

---

## Fora de escopo

- Tipo `KNOW` / gossip / sync de conhecimento
- Marketplace, leilão, matching, fila persistente, multi-hop de tarefas
- libp2p, Iroh, QUIC obrigatório, DHT, NAT, relay
- Exigir SO IA Livre / QEMU / GGUF / runtime / agent
- Alterar descoberta E39/E50 (exceto não regressar)
- Substituir ou remover MSG/PING
- Marcar Etapa 51 `feita` nesta spec (agente principal após gate + revisor)

---

## Critérios de aceite

- [ ] Framing v1 documenta `TASK` + `TASK_ACK` em `rede-ia-livre-v1.md`
- [ ] Sessão de dois nós completa TASK → TASK_ACK e emite `IA_LIVRE_TASK_OK`
- [ ] `ACK` de MSG e `PING`/`PONG` continuam verdes na mesma sessão
- [ ] Gate do nó exige `IA_LIVRE_TASK_OK` (marcadores honestos; sem fingir)
- [ ] Sem marketplace; sem exigir SO; `! grep -qi libp2p node/Cargo.toml`
- [ ] `AGENTS.md` atualizado; README avaliado
- [ ] Regressão `make verify-node` (peer + bootstrap; mDNS skip default) verde

---

## Riscos e rollback

- **Risco:** colisão lexical `ACK` vs `TASK_ACK` no parser → parsers por prefixo estrito (`TASK_ACK` antes de `ACK` se compartilhado; preferir match dedicado).
- **Risco:** ordem de emissão no gate (TASK antes de PING) → fixar ordem na doc e no `session.rs`.
- **Risco:** payload com espaços → `task_id` sem espaços; resto da linha = texto.
- **Rollback:** remover tipos TASK/TASK_ACK e exigência `TASK_OK` do gate; v1 volta a MSG/PING only.

---

## Etapa do roadmap

- Etapa 51 — Tarefa/conhecimento mínimo na Rede (além de PING) (`em_andamento`; Issue [#51](https://github.com/eriksonlima/projeto-ia-livre/issues/51))
- Spec: `specs/tarefa-conhecimento-rede/`
- Pronto quando (roadmap): tipo de mensagem v1 (`TASK` + `TASK_ACK`) + ACK correspondente + gate de dois nós; sem marketplace; sem exigir SO.
