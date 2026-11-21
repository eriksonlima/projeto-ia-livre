# Spec — Descoberta WAN (NAT/DHT/relay)

Etapa 67 · Issue [#67](https://github.com/eriksonlima/projeto-ia-livre/issues/67) (ex-B62)  
Depende: E39 (bootstrap) · E50 (mDNS) · ADR [`0004`](../../docs/adr/0004-stack-protocolo-rede-ia-livre.md) · [`docs/rede-descoberta-wan.md`](../../docs/rede-descoberta-wan.md).  
ADR 0001: participar da Rede **não exige** o SO IA Livre.

---

## Resultado visível

Existe um desfecho **verificável** de descoberta além de bootstrap/mDNS para o cenário WAN/NAT (hoje só loopback/LAN):

| Caminho | Condição | Esperado |
|---------|----------|----------|
| **A — Relay TCP simples** | Processo/modo relay documentado; dois nós dialam **via relay** (loopback simula NAT) até sessão autenticável | Marcadores `DISC_MODE=relay` (ou equiv.) + `DISC_OK` / `RELAY_OK` + gate dois nós; regressão `verify-node` intacta |
| **B — Inviabilidade honesta** | A inviável na fatia com motivo medido | ADR nova (ex. `0025`) + skip/bloqueio documentado (`DISC_RELAY_SKIP` / `DISC_WAN_BLOCK=…`); **sem** fingir WAN; gate exit 0 no estágio com skip |

O Pronto quando do roadmap fecha com **DHT ou relay** verificável + gate/skip. Nesta etapa: **preferir A (relay)**; DHT fica **stub/adiado** se A fechar o critério. **Proibido** libp2p monólito sem ADR nova. **Proibido** fingir internet pública / hole-punch.

---

## Contexto fixo (não reinventar)

- E39/E50: `lan` / `peer` / `bootstrap` / `mdns`; precedência `--peer` > bootstrap > mdns; `make verify-node` (peer + bootstrap + mDNS skip default).
- ADR 0004: DHT/relay/NAT **nomeados como futuro**; **não** adotar libp2p no mínimo.
- Doc: [`rede-descoberta-wan.md`](../../docs/rede-descoberta-wan.md) — seção Futuro: `RELAY_HINT v1 <host:port>`; DHT fora; loopback **não** prova internet pública.
- Nó: `node/` (`discovery.rs`, `mdns.rs`, `session.rs`); `! grep -qi libp2p node/Cargo.toml`.
- E66 / ADR 0024: TCP **guest** inviável — **fora**; esta etapa é **host** `std` apenas.
- KNOW (B63), marketplace, TCP guest: **fora**.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A — Relay TCP simples + gate dois nós** | Flag/`--relay` ou nó dedicado; B alcança A via R no loopback; IDENT ed25519 intacto | **Preferida** — fecha Pronto quando com mínimo honesto; sem libp2p |
| **B — ADR inviabilidade + skip/bloqueio** | Medir por que relay mínimo não cabe; ADR `0025`; gate skip honesto | **Fallback** se A inviável na fatia |
| **C — DHT/Kademlia real** | Tabela distribuída | **Adiada** — opcional só se sobrar após A; stub/doc basta se A fecha Pronto quando |
| **D — libp2p / Iroh monólito** | Stack externa completa | **Rejeitada** sem ADR nova dedicada |
| **E — STUN/TURN/hole-punch completo** | NAT traversal real | **Fora** desta etapa |
| **F — Fingir WAN** (`DISC_OK` sem caminho relay) | Marcador cosmético | **Rejeitada** — fraude |
| **G — Acoplar `verify-node` ao SO/QEMU** | Rede host exige guest | **Rejeitada** — ADR 0001 |

### Escolha: **A preferida; B se inviável**

| Peça | Nesta etapa |
|------|-------------|
| Núcleo | Relay TCP **mínimo** documentado (introdução de endereço **ou** forward de sessão entre dois dials) — Task 1 fixa o modelo exato |
| Flags | Ex.: `--relay <host:port>` no cliente e/ou modo `--relay-listen` no processo R; nomes exactos na Task 1 |
| Precedência dial | `--peer` > bootstrap > **relay** > mdns > LAN — **ou** regra única equivalente fixada na Task 1 (uma só) |
| Segurança | Relay só fornece **caminho/endereço**; autenticação continua **IDENT** / PeerId |
| DHT | Stub/doc ou “adiado” explícito se A fecha Pronto quando; **não** exigir Kademlia |
| Marcadores A | `IA_LIVRE_DISC_MODE=relay` + `IA_LIVRE_DISC_OK` (+ v1); opcional `IA_LIVRE_RELAY_OK` |
| Marcadores B | `IA_LIVRE_DISC_RELAY_SKIP=…` e/ou `IA_LIVRE_DISC_WAN_BLOCK=…` (nome na Task 1); **sem** `DISC_OK` fingido |
| Gate | Estágio aditivo em `verify-node` **ou** `make verify-node-relay` — Task 1 decide; regressão peer/bootstrap/mDNS **permanece** |
| Skip CI | Default skip do estágio relay **só** no caminho B; no caminho A o gate deve provar dois nós via relay no loopback |
| Independência SO | Host Linux `std` apenas |

### Fluxo canônico (A — prova)

```
R: --relay-listen --tcp-port 7399   (ou processo/modo fixado na Task 1)
A: --tcp-port 7400 --node-id alice  (aceita; pode registrar no relay)
B: --tcp-port 7401 --node-id bob --relay 127.0.0.1:7399
  → IA_LIVRE_DISC_MODE=relay
  → caminho via R até A
  → IDENT ↔ IDENT → PEER_OK / MSG_OK / PING_OK (v1)
  → IA_LIVRE_DISC_OK (+ RELAY_OK se adotado)
```

### Fluxo canônico (B — skip/bloqueio)

```
ADR 0025: relay/WAN mínimo inviável nesta fatia (motivo medido)
gate estágio relay:
  → IA_LIVRE_DISC_RELAY_SKIP=<motivo>  (ou DISC_WAN_BLOCK=…)
  → exit 0 no estágio; sem DISC_OK / RELAY_OK fingidos
verify-node (peer+bootstrap+mdns) permanece verde
```

---

## Conteúdo obrigatório

### 1. Documentação

- Atualizar [`docs/rede-descoberta-wan.md`](../../docs/rede-descoberta-wan.md): modo `relay` (A) **ou** bloqueio/skip (B); precedência; limites (loopback ≠ internet pública); DHT adiado/stub.
- Ponte em [`docs/rede-ia-livre-v1.md`](../../docs/rede-ia-livre-v1.md) e/ou desenho ADR 0004 (addendum curto se A for extensão natural).
- Se B: ADR nova **`0025`** (título sugerido: relay/WAN mínimo inviável / adiado com motivo) — critérios de reabertura.
- `AGENTS.md`: Como rodar / Como verificar o estágio relay (ou skip).

### 2. Código em `node/` (caminho A)

- CLI + caminho de dial/forward via relay integrado à sessão existente.
- Sem libp2p; deps leves se necessário (só TCP/`tokio` preferível).
- Falha honesta se relay indisponível (sem `DISC_OK` falso).

### 3. Gate

- Estágio dois nós via relay (A) **ou** skip/bloqueio documentado (B).
- Regressão: `make verify-node` (peer + bootstrap + mDNS skip default) **verde** sem QEMU/SO.
- Anti-fraude: falha se `DISC_OK`/`RELAY_OK` sem evidência de caminho relay (A) ou se skip omitido no caminho B.

---

## Fora de escopo

- KNOW (B63); marketplace; integração runtime/kernel/agent
- TCP Rede no guest (E66/0024)
- libp2p / Iroh monólito sem ADR nova
- STUN/TURN/hole-punch completo; exigir internet pública ou dois hosts físicos
- Fingir WAN / `DISC_OK` cosmético
- DHT Kademlia completo (adiável se A fecha Pronto quando)
- Quebrar framing v1; exigir SO IA Livre
- Marcar Etapa 67 `feita` nesta spec (agente principal após gate + revisor)

---

## Critérios de aceite

- [ ] Decisão A vs B registrada; desfecho fecha Pronto quando (relay **ou** DHT verificável **ou** ADR+skip honesto)
- [ ] Se A: dois nós via relay no gate/loopback + `DISC_MODE=relay` + `DISC_OK` (+ v1); IDENT = âncora
- [ ] Se B: ADR `0025` (ou número livre) + skip/bloqueio sem fingir; reabertura documentada
- [ ] DHT: implementado mínimo **ou** stub/adiado explícito (ok se A fechou)
- [ ] `! grep -qi libp2p node/Cargo.toml` (salvo ADR nova explícita — fora do default)
- [ ] `make verify-node` regressão intacta (ADR 0001); sem QEMU/SO
- [ ] `docs/rede-descoberta-wan.md` + `AGENTS.md` atualizados; README avaliado (`readme-por-fatia`)

---

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| Escopo virar NAT completo / libp2p | Preferir A mínimo; D rejeitada; B se A estourar |
| Gate flaky (3 processos) | Portas fixas; sleeps documentados; cleanup no script |
| Confundir bootstrap com relay | Modo/marcador distintos; doc de precedência |
| Fingir WAN pública | Doc: loopback simula; não emitir prova de internet |
| Colisão multi-agente | Só `node/` + docs Rede + scripts gate; respeitar `AGENT_CLAIM.md` |

Rollback: reverter CLI/relay + estágio gate; bootstrap/mDNS/`verify-node` recuperáveis.

---

## Etapa do roadmap

Etapa 67 — Descoberta WAN (NAT/DHT/relay)  
Issue: [#67](https://github.com/eriksonlima/projeto-ia-livre/issues/67) (ex-B62)  
Status roadmap: _(promover / `em_andamento` — agente principal)_  
Pronto quando: DHT **ou** relay verificável + gate/skip; sem libp2p monólito sem ADR.  
Spec: `specs/descoberta-wan-dht-relay/`
