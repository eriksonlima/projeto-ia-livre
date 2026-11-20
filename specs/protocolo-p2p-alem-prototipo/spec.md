# Spec — Protocolo P2P além do protótipo (stack / identidade)

## Resultado visível

Existe uma **escolha documentada** (ADR + doc de desenho) da **stack candidata** da Rede IA Livre além do protótipo HELLO/MSG/ACK:

1. **Transporte** de sessão e de descoberta local.
2. **Identidade** criptográfica do nó (substitui `node_id` livre como âncora de confiança).
3. **Descoberta** além do HELLO UDP periódico + dial `--peer`.
4. **Fronteira do próximo protótipo** (o que entra na próxima implementação vs o que fica fora).

A etapa é **só documental**. Não há implementação completa do protocolo novo em `node/`, nem marketplace, nem integração com runtime/kernel.

## Contexto fixo (não reinventar)

- Protótipo atual (Etapa 6): [`docs/rede-ia-livre-prototipo.md`](../../docs/rede-ia-livre-prototipo.md) — TCP linhas UTF-8 (`MSG`/`ACK`) + UDP `HELLO <node_id> <tcp_port>`; crate `node/` (`ia-livre-node`); gate `make verify-node`.
- ADR 0001: P2P **independente** do SO; participar da Rede **não exige** o IA Livre — [`docs/adr/0001-separacao-camadas-e-p2p.md`](../../docs/adr/0001-separacao-camadas-e-p2p.md).
- Decisão aberta em [`docs/architecture.md`](../../docs/architecture.md): «Stack concreta do protocolo P2P (bibliotecas, transporte, identidade)».
- Fora do protótipo atual (explícito): DHT, crypto de identidade, NAT traversal, marketplace, libp2p, integração runtime/kernel.
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`; se não precisar, registrar.

## Decisão de desenho (única — obrigatória)

| Peça | Escolha nesta etapa |
|------|---------------------|
| Forma | **Desenho** (ADR + doc) — **não** implementação completa do protocolo novo |
| Stack candidata | Protocolo **Rede IA Livre v1** (próprio, versionado) sobre **TCP + UDP**, com identidade **ed25519** — **sem** adotar libp2p no próximo protótipo |
| Transporte | **TCP** = sessão (framing por linha UTF-8 versionado); **UDP** = descoberta local (HELLO assinado). QUIC = evolução candidata **documentada**, fora do próximo protótipo |
| Identidade | Par de chaves **ed25519**; `PeerId` = fingerprint da chave pública; `HELLO` e handshake de sessão autenticam o peer; `node_id` string vira **apelido** opcional (não âncora de confiança) |
| Descoberta além de HELLO | (1) HELLO UDP **assinado** + versão de protocolo; (2) dial multiendereço explícito (`--peer` / lista de peers conhecidos); (3) **mDNS / DHT / relay / NAT traversal completo** = fronteira futura, só nomeados no doc |
| Mensagens além de MSG/ACK | Framing **v1** com tipos mínimos: `HELLO` (UDP), `IDENT` (handshake TCP), `MSG`/`ACK` (compatível com prova atual), `PING`/`PONG` (liveness) — detalhar no doc |
| Bibliotecas | Preferir crates **auditáveis e leves** no próximo protótipo (ex.: `ed25519-dalek` ou equivalente); **não** puxar stack libp2p completa nesta fronteira |
| ADR | **Nova** (ex.: `docs/adr/0004-stack-protocolo-rede-ia-livre.md`) — status **aceita** no nível *desenho candidato*; implementação = etapa/backlog futuro |
| Doc de desenho | `docs/desenho-protocolo-rede-ia-livre.md` (ou nome equivalente fixado na Task 2) |

### Rejeitado (explícito)

- Implementar o protocolo v1 completo em `node/` nesta etapa (salvo ponte documental).
- Marketplace, leilão de recursos, economia de tokens.
- Integração do nó com runtime de inferência ou kernel UEFI.
- Adotar **libp2p** (ou Iroh / equivalente monolítico) como dependência do **próximo** protótipo — avaliar no ADR e **adiar** com motivo (controle do framing, superfície, independência do manifesto).
- NAT traversal completo (STUN/TURN/hole-punching/relay) como critério desta etapa ou do próximo protótipo.
- DHT / Kademlia como requisito do próximo protótipo.
- Várias stacks concorrentes sem escolher uma — a etapa **fixa uma** candidata.
- Declarar a Rede “pronta para produção” ou o protótipo atual obsoleto sem fronteira clara.

### Esboço do contrato (a detalhar no doc de desenho)

```
Nó A                                              Nó B
────                                              ────
UDP: HELLO v1 + PeerId + tcp_port + sig  →   valida sig / PeerId
TCP dial ────────────────────────────────→   aceita
TCP: IDENT (PeerId, pubkey, nonce, sig)  ↔   IDENT resposta
TCP: MSG / ACK (prova existente)         ↔   (compat gate atual)
TCP: PING / PONG (opcional)              ↔   liveness
```

Compatibilidade: o gate atual (`IA_LIVRE_PEER_OK` / `IA_LIVRE_MSG_OK`) permanece válido até uma etapa de implementação substituí-lo; o desenho v1 **não** quebra o contrato documentado do protótipo sem etapa dedicada.

Não-objetivos do v1 (desenho): ABI estável multi-linguagem, DHT, relay, marketplace, sync de conhecimento, tarefas distribuídas de inferência — listar no doc como **futuro**.

## Conteúdo obrigatório

### 1. ADR

- Contexto: lacuna «stack concreta» em `architecture.md` + limites do protótipo HELLO/MSG/ACK.
- Decisão: stack candidata acima (TCP+UDP, ed25519/PeerId, descoberta HELLO assinado + dial, framing v1; libp2p adiado).
- Consequências positivas/negativas; o que **não** fica decidido (implementação, NAT, DHT, QUIC obrigatório).
- Relação com ADR 0001 (independência do SO) e com o protótipo Etapa 6 (evolução, não descarte silencioso).

### 2. Doc de desenho

- Motivação: por que ir além de `node_id` livre e HELLO sem autenticação.
- Modelo de identidade (geração de chave, PeerId, apelido).
- Transporte e framing v1 (tabela de mensagens; compat MSG/ACK).
- Descoberta: o que entra no próximo protótipo vs mDNS/DHT/NAT/relay.
- Fronteira do **próximo protótipo** (checklist: o que implementar depois; o que continua fora).
- Alternativas consideradas (libp2p, QUIC-first, identidade só por certificado X.509) e por que não agora.
- Não-objetivos e backlog de implementação futura (sem promover etapa sozinho).
- Honestidade: o `node/` atual **não** implementa v1.

### 3. Pontes

- `docs/architecture.md`: mover/riscar «Stack concreta do protocolo P2P…» para **decidida no nível desenho** (apontar ADR + doc); implementação continua aberta.
- Ponte em `docs/rede-ia-livre-prototipo.md`: protótipo atual = Etapa 6; desenho v1 = Etapa 14 (não implementado).
- `AGENTS.md`: menção curta na estrutura/docs (ponte), sem inventar gate de código novo.
- README: avaliar (`readme-por-fatia`).

## Fora de escopo

- Código de produto em `node/`, `kernel/`, `runtime/`, `agent/` (exceto se ponte documental citar paths existentes)
- Implementação de ed25519, IDENT, DHT, NAT, mDNS, QUIC no crate
- Marketplace / economia / leilão de recursos
- Integração nó ↔ runtime / kernel
- Mudança de manifesto ou de ADR 0001
- Nova etapa de implementação sem promoção via backlog / pedido explícito
- Gate `make verify-node` novo ou alterado nesta etapa

## Critérios de aceite

- [ ] ADR nova registra **uma** stack candidata (transporte + identidade + descoberta além de HELLO/MSG/ACK) com fronteiras e consequências
- [ ] Doc de desenho detalha framing v1, identidade ed25519/PeerId, fronteira do próximo protótipo e não-objetivos (NAT completo, DHT, marketplace, libp2p no próximo protótipo, integração runtime/kernel)
- [ ] `architecture.md` deixa de listar a stack P2P como “aberta sem proposta”; aponta ADR/doc; implementação permanece aberta
- [ ] Ponte honesta no doc do protótipo: Etapa 6 ≠ desenho v1 ≠ implementação
- [ ] README avaliado (`readme-por-fatia`)
- [ ] Sem código de produto novo no `node/` (nem outros crates de produto) nesta etapa
- [ ] Etapa 14 não é marcada `feita` nesta spec (só após revisão pelo agente principal)

## Riscos e rollback

- **Risco:** leitor achar que `node/` já fala v1 → avisos explícitos «desenho ≠ implementação».
- **Risco:** escopo inchado (implementar crypto/NAT agora) → Pronto quando = só doc/ADR + fronteira.
- **Risco:** ADR contradizer 0001 (amarrar P2P ao SO) → rejeitar; rede continua independente.
- **Risco:** adotar libp2p “por padrão” sem justificar → a decisão desta spec **adia** libp2p no próximo protótipo; se evidência futura mudar, nova ADR.
- **Rollback:** reverter ADR/doc/pontes; etapa continua `em_andamento`.

## Etapa do roadmap

- Etapa 14 — Protocolo P2P além do protótipo (stack / identidade) (`em_andamento`, Issue [#14](https://github.com/eriksonlima/projeto-ia-livre/issues/14))
- Spec: `specs/protocolo-p2p-alem-prototipo/`
- Pronto quando (roadmap): escolha documentada (ADR/doc) da stack candidata (transporte, identidade, descoberta além de HELLO/MSG/ACK) e fronteira do próximo protótipo — sem marketplace nem integração runtime/kernel.
