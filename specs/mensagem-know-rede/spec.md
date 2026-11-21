# Spec — Mensagem KNOW na Rede

Etapa 68 · Issue [#68](https://github.com/eriksonlima/projeto-ia-livre/issues/68)  
Depende: Etapa 51 (`TASK`/`TASK_ACK` no `node/`).  
Origem backlog: **B63**.

---

## Resultado visível

O crate `node/` (`ia-livre-node`) troca, após o ciclo TASK, um ciclo **KNOW → KNOW_ACK** no framing TCP v1, **sem** marketplace, **sem** persistência de conhecimento e **sem** exigir o SO IA Livre (ADR 0001):

1. **Tipo novo** — mensagem `KNOW` com id + payload de texto curto (prova canônica documentada).
2. **ACK correspondente** — `KNOW_ACK` ecoando o mesmo `know_id` (espelha `TASK`/`TASK_ACK`; **não** reutiliza `ACK` de MSG nem `TASK_ACK`).
3. **Prova em dois nós** — sessão TCP (dial `--peer` ou equivalente) completa IDENT → MSG → PING → TASK → **KNOW/KNOW_ACK**.
4. **Marcador** — `IA_LIVRE_KNOW_OK` quando o ciclo KNOW/KNOW_ACK valida.
5. **Gate** — `make verify-node` (estágio peer ou estágio dedicado) exige `IA_LIVRE_KNOW_OK` com marcadores honestos; regressão MSG/PING/TASK/bootstrap/mDNS/relay **não** quebra.

Participar da Rede **continua sem** kernel UEFI, QEMU, GGUF nem runtime.

---

## Contexto fixo (não reinventar)

- Contrato v1: [`docs/rede-ia-livre-v1.md`](../../docs/rede-ia-livre-v1.md) — hoje IDENT/MSG/ACK/PING/PONG/TASK/TASK_ACK; KNOW ainda fora.
- Framing: `node/src/proto.rs`; sessão: `node/src/session.rs` (padrão TASK já implementado).
- Espelho explícito de TASK: `KNOW <know_id> <texto>` / `KNOW_ACK <know_id>` → `IA_LIVRE_KNOW_OK`.
- Descoberta: bootstrap E39 + mDNS E50 + relay E67 — **fora** desta etapa salvo regressão.
- Sem libp2p (`! grep -qi libp2p node/Cargo.toml`).
- ADR 0001 / 0004 — host `std`; stack leve; marketplace/DHT fora.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A** | `KNOW` + `KNOW_ACK` espelhando TASK | **Escolhida** — prova pedido/ACK de conhecimento mínimo; escopo do Pronto quando |
| **B** | Reutilizar `MSG`/`ACK` com prefixo no texto | **Rejeitada** — não cria tipo de framing; prova frágil |
| **C** | Reutilizar `TASK` com namespace no `task_id` | **Rejeitada** — confunde semântica tarefa vs conhecimento |
| **D** | Gossip / sync / store de conhecimento | **Rejeitada** — persistência e rede de saber além do mínimo |
| **E** | Marketplace / ranking de saberes | **Rejeitada** — fora do Pronto quando |
| **F** | libp2p / DHT / pubsub | **Rejeitada** — AGENTS + ADR 0004; DHT adiado na E67 |
| **G** | Exigir SO / bridge nativa | **Rejeitada** — ADR 0001 |

### Escolha: **A — KNOW + KNOW_ACK**

| Peça | Escolha nesta etapa |
|------|---------------------|
| Tipos | `KNOW` (anúncio/pedido de conhecimento) e `KNOW_ACK` (confirmação do `know_id`) |
| Formato TCP | `KNOW <know_id> <texto>\n` / `KNOW_ACK <know_id>\n` |
| `know_id` | Token sem espaços (prova fixa `k1`); UTF-8; documentar restrição |
| Payload | Texto curto sem `\n`; prova canônica `prova-know-v1` |
| Ordem na sessão | Após `TASK_OK` (não substitui MSG/PING/TASK) |
| ACK de MSG / TASK_ACK | Permanecem distintos — **não** misturar com KNOW |
| Marcador sucesso | `IA_LIVRE_KNOW_OK` (uma vez por sessão de prova) |
| Transporte | TCP pós-IDENT (mesmo path de MSG/PING/TASK) |
| Independência SO | Host Linux `std` apenas |
| Marketplace / store | Nenhum ranking, preço, matching, fila ou persistência |

### Fluxo canônico (prova — dois nós)

```
UDP HELLO (opcional) / dial --peer
IDENT ↔ IDENT          → IA_LIVRE_IDENT_OK + IA_LIVRE_PEER_OK
MSG / ACK (prova)      → IA_LIVRE_MSG_OK
PING / PONG            → IA_LIVRE_PING_OK
TASK / TASK_ACK        → IA_LIVRE_TASK_OK
KNOW / KNOW_ACK        → IA_LIVRE_KNOW_OK
```

Exemplo de linhas:

```
KNOW k1 prova-know-v1
KNOW_ACK k1
```

---

## Conteúdo obrigatório

### 1. Documentação

- Atualizar [`docs/rede-ia-livre-v1.md`](../../docs/rede-ia-livre-v1.md): tabela de mensagens, fluxo, marcador `KNOW_OK`, prova canônica; remover “KNOW fora” do núcleo v1 (marketplace/persistência/DHT continuam fora).
- `AGENTS.md`: Como rodar / Como verificar do nó — exigir `IA_LIVRE_KNOW_OK` no gate do nó.
- README: avaliar (`readme-por-fatia`); só atualizar se a capa ficar enganosa.
- ADR nova: **não** exigida (extensão do framing v1 já ADR 0004); só se a fronteira arquitetural mudar.

### 2. Código em `node/`

- `proto.rs`: format/parse de `KNOW` e `KNOW_ACK` (constantes de prova `k1` / `prova-know-v1`).
- `session.rs`: após ciclo TASK, enviar/receber KNOW/KNOW_ACK e emitir `IA_LIVRE_KNOW_OK`.
- Rejeitar/ignorar linhas malformadas de forma honesta (sem travar peer/bootstrap/mDNS/relay).
- **Não** quebrar MSG/ACK, PING/PONG nem TASK/TASK_ACK.

### 3. Gate

- Estender `scripts/verify-node.sh` (preferido, estágio peer) **ou** estágio/alvo dedicado chamado por `make verify-node`.
- Estágio peer (dois nós) deve exigir `IA_LIVRE_KNOW_OK` além de `PEER_OK` / `MSG_OK` / `IDENT_OK` / `PING_OK` / `TASK_OK`.
- Bootstrap + mDNS + relay: regressão intacta; mDNS/relay continuam opt-in/skip default.
- Sem QEMU/GGUF.

---

## Fora de escopo

- Marketplace, leilão, matching, ranking de saberes
- Persistência / store / sync / gossip de conhecimento
- libp2p, Iroh, QUIC obrigatório, DHT, NAT (além da regressão E67)
- Exigir SO IA Livre / QEMU / GGUF / runtime / agent
- Alterar descoberta E39/E50/E67 (exceto não regressar)
- Substituir ou remover MSG/PING/TASK
- Marcar Etapa 68 `feita` nesta spec (agente principal após gate + revisor)

---

## Critérios de aceite

- [ ] Framing v1 documenta `KNOW` + `KNOW_ACK` em `rede-ia-livre-v1.md`
- [ ] Sessão de dois nós completa KNOW → KNOW_ACK e emite `IA_LIVRE_KNOW_OK`
- [ ] MSG/PING/TASK continuam verdes na mesma sessão
- [ ] Gate do nó exige `IA_LIVRE_KNOW_OK` (marcadores honestos; sem fingir)
- [ ] Sem marketplace; sem persistência; sem exigir SO; `! grep -qi libp2p node/Cargo.toml`
- [ ] `AGENTS.md` atualizado; README avaliado
- [ ] Regressão `make verify-node` (peer + bootstrap; mDNS skip default) verde

---

## Riscos e rollback

- **Risco:** colisão lexical `ACK` vs `KNOW_ACK` / `TASK_ACK` → parsers por prefixo estrito (`KNOW_ACK` / `TASK_ACK` antes de `ACK`).
- **Risco:** ordem de emissão (KNOW antes de TASK) → fixar ordem na doc e no `session.rs` (após `TASK_OK`).
- **Risco:** payload com espaços → `know_id` sem espaços; resto da linha = texto.
- **Rollback:** remover tipos KNOW/KNOW_ACK e exigência `KNOW_OK` do gate; v1 volta a TASK como último tipo de aplicação.

---

## Etapa do roadmap

- Etapa 68 — Mensagem KNOW na Rede (`em_andamento`; Issue [#68](https://github.com/eriksonlima/projeto-ia-livre/issues/68))
- Spec: `specs/mensagem-know-rede/`
- Pronto quando (roadmap): `KNOW`(+ACK) + gate dois nós; sem marketplace; sem exigir SO.
