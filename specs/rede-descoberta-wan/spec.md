# Spec — Rede IA Livre além de v1 (descoberta WAN mínima)

Etapa 39 · Issue [#38](https://github.com/eriksonlima/projeto-ia-livre/issues/38) (ex-B32)  
Depende: Etapa 6 (protótipo `node/`), Etapa 14 (ADR 0004 / desenho), Etapa 23 (protocolo v1 + gate `make verify-node`).

---

## Resultado visível

O crate `node/` (`ia-livre-node`) ganha **descoberta além de HELLO UDP em LAN e dial único `--peer`**, sem exigir o SO IA Livre (ADR 0001):

1. **Lista de bootstrap** (caminho principal, verificável no loopback): dial multiendereço a partir de `--bootstrap` (repetível) e/ou arquivo de configuração documentado.
2. **mDNS opcional** (opt-in por flag): anúncio/resolução `_ia-livre._tcp` na LAN quando a feature estiver ativa — **não** obrigatório no gate se o ambiente não tiver multicast.
3. **Relay/DHT:** apenas **desenho mínimo documentado** (formato de hint, limites, evolução futura) — **sem** implementação Kademlia/libp2p/NAT traversal nesta etapa.

O gate `make verify-node` é **estendido** com um cenário em que o nó B alcança o nó A via **bootstrap** (sem `--peer`), mantendo o cenário v1 `--peer` como regressão documentada ou segundo estágio no mesmo script.

Marcadores novos (mínimo): `IA_LIVRE_DISC_MODE=…`, `IA_LIVRE_DISC_OK` (ou equivalente fixado na Task 1) quando a descoberta não-LAN/bootstrap completar o caminho até `IDENT`/`PEER_OK`.

Participar da Rede **continua sem** kernel UEFI, QEMU, GGUF nem runtime.

---

## Contexto fixo (não reinventar)

- Protocolo v1: [`docs/rede-ia-livre-v1.md`](../../docs/rede-ia-livre-v1.md) — HELLO UDP assinado, IDENT, MSG/ACK, PING/PONG, `--peer`.
- ADR 0004: [`docs/adr/0004-stack-protocolo-rede-ia-livre.md`](../../docs/adr/0004-stack-protocolo-rede-ia-livre.md) — já previa dial multiendereço; mDNS/DHT/relay adiados ao v1.
- Desenho: [`docs/desenho-protocolo-rede-ia-livre.md`](../../docs/desenho-protocolo-rede-ia-livre.md) — próximo passo após E23 = descoberta WAN.
- Gate atual: `scripts/verify-node.sh` — dois processos, B com `--peer 127.0.0.1:7400`.
- Spec E23: `specs/protocolo-rede-v1/` — **não** reabrir framing v1 salvo extensão de descoberta.
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A** | `--bootstrap host:port[,…]` + arquivo opcional; TCP dial após resolução; simula WAN com endpoints estáticos | **Escolhida (núcleo + gate)** |
| **B** | mDNS (`_ia-livre._tcp`) opt-in | **Escolhida (opcional)** — feature flag; skip honesto no CI |
| **C** | Relay UDP mínimo in-process (dois hops no loopback) | **Rejeitada** — complexidade NAT; documentar só como futuro |
| **D** | DHT/Kademlia ou libp2p | **Rejeitada** — fora do Pronto quando e do ADR 0004 |
| **E** | STUN/TURN/hole-punching | **Rejeitada** — fora de escopo |
| **F** | Só documentar sem código | **Rejeitada** — roadmap exige gate |

### Escolha: **A (+ B opcional) — bootstrap verificável + mDNS opt-in**

| Peça | Escolha nesta etapa |
|------|---------------------|
| Modos de descoberta | `lan` (HELLO UDP existente), `peer` (`--peer`), `bootstrap` (`--bootstrap` / arquivo), `mdns` (opt-in) |
| Bootstrap | Lista ordenada de `host:port` TCP; tentativa sequencial ou paralela mínima documentada; falha honesta se vazia/inválida |
| Arquivo | Ex.: `build/node-bootstrap.txt` ou `--bootstrap-file`; uma linha = um endpoint; comentários `#` opcionais documentados |
| Segurança | Bootstrap só fornece **endereço**; autenticação permanece **IDENT** ed25519 (não confiar em bootstrap como identidade) |
| HELLO LAN | **Preservado**; não remover anúncio UDP |
| mDNS | Crate leve (ex. `mdns-sd` ou equivalente auditável); `--mdns` ou `--disc-mdns`; **não** exigir no gate default |
| Relay/DHT | Seção em doc nova com formato de hint futuro (`RELAY_HINT v1 …`) — **sem** código de malha |
| Marcadores | `IA_LIVRE_DISC_MODE=bootstrap\|peer\|lan\|mdns`; `IA_LIVRE_DISC_OK` ao concluir dial por bootstrap/mdns até sessão; preservar todos os marcadores v1 |
| Independência SO | Host Linux `std` apenas |

### Fluxo canônico (bootstrap — gate)

```
A: listen tcp:7400 + UDP HELLO (inalterado)
B: --bootstrap 127.0.0.1:7400  (sem --peer)
  → DISC_MODE=bootstrap
  → TCP dial 127.0.0.1:7400
  → IDENT ↔ IDENT → PEER_OK / MSG_OK / PING_OK (v1)
  → DISC_OK
```

---

## Conteúdo obrigatório

### 1. Documentação

- Novo contrato: `docs/rede-descoberta-wan.md` (ou seção equivalente claramente linkada a partir de `rede-ia-livre-v1.md`) — modos, flags, arquivo bootstrap, mDNS opt-in, limites WAN reais vs simulação loopback, relay/DHT futuro.
- Atualizar ponte em `desenho-protocolo-rede-ia-livre.md` (item «descoberta WAN»).
- `AGENTS.md`: **Como rodar** / **Como verificar** do nó com bootstrap + extensão do gate.
- ADR: **addendum** em 0004 ou ADR curta nova **só** se a decisão alterar fronteira do v1 — preferir addendum/doc se bootstrap for extensão natural do item 4 do ADR.

### 2. Código em `node/`

- Parser CLI `--bootstrap` / `--bootstrap-file` (e flag mDNS se Task 3).
- Caminho de dial bootstrap integrado ao fluxo de sessão existente (`session.rs` / `main.rs`).
- Sem dependência de kernel/runtime/agent.

### 3. Gate

- `scripts/verify-node.sh`: estágio A = regressão v1 `--peer` **ou** estágio único que exige **ambos** (preferência: **ambos** no mesmo script, ordem documentada).
- Estágio bootstrap: B **sem** `--peer`, com bootstrap apontando para A; exige `IA_LIVRE_DISC_OK` + marcadores v1 existentes.
- Variáveis: ex. `VERIFY_NODE_BOOTSTRAP=1` (default on), timeout preservado `VERIFY_NODE_TIMEOUT`.
- `make verify-node` permanece o alvo.

---

## Fora de escopo

- libp2p, Iroh, QUIC obrigatório, DHT/Kademlia implementado
- NAT traversal, STUN/TURN, hole-punching, relay executável multi-hop
- Marketplace, integração runtime/kernel/agent
- Protocolo v2 / breaking do framing IDENT/MSG
- Exigir internet pública ou dois hosts físicos no gate
- Exigir SO IA Livre
- Marcar Etapa 39 `feita` nesta spec (agente principal após gate + revisor)

---

## Critérios de aceite

- [ ] Doc `rede-descoberta-wan` descreve bootstrap, mDNS opt-in e futuro relay/DHT
- [ ] `node/` diala via `--bootstrap` sem `--peer` no cenário loopback
- [ ] Autenticação continua IDENT ed25519; bootstrap não substitui PeerId
- [ ] HELLO LAN + `--peer` preservados (sem regressão documentada)
- [ ] mDNS opt-in implementado **ou** skip honesto documentado se adiado à Task 3 com motivo na spec/tasks
- [ ] `make verify-node` estendido cobre bootstrap + preserva checks v1
- [ ] `AGENTS.md` atualizado; README avaliado (`readme-por-fatia`)
- [ ] Sem libp2p/DHT/NAT/marketplace na entrega

---

## Riscos e rollback

- **Risco:** gate flaky por corrida bootstrap vs HELLO → ordem determinística no script; sleeps mínimos documentados.
- **Risco:** mDNS indisponível em CI → opt-in + skip `VERIFY_NODE_MDNS_SKIP=1`.
- **Risco:** escopo DHT «só mais um pouco» → relay/DHT ficam só em doc.
- **Risco:** colisão multi-agente → só `node/` + docs P2P + `verify-node.sh`; respeitar `AGENT_CLAIM.md`.
- **Rollback:** reverter `node/` + script; gate v1 `--peer`-only recuperável.

---

## Etapa do roadmap

- Etapa 39 — Rede IA Livre além de v1 (descoberta WAN mínima) (`em_andamento`; Issue [#38](https://github.com/eriksonlima/projeto-ia-livre/issues/38))
- Spec: `specs/rede-descoberta-wan/`
- Pronto quando (roadmap): descoberta além de `--peer`/HELLO LAN + gate; sem exigir SO.