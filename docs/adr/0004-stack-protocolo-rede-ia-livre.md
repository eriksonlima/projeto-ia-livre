# ADR 0004 — Stack candidata do protocolo Rede IA Livre (v1)

- Status: aceita (nível **desenho**; implementação mínima = Etapa 23 em `node/` — [`docs/rede-ia-livre-v1.md`](../rede-ia-livre-v1.md))
- Data: 2026-11-20

## Contexto

A Rede IA Livre tem protótipo mínimo (Etapa 6): TCP com `MSG`/`ACK` em linhas UTF-8 e UDP `HELLO <node_id> <tcp_port>`, sem identidade criptográfica — ver [`docs/rede-ia-livre-prototipo.md`](../rede-ia-livre-prototipo.md). Em [`docs/architecture.md`](../architecture.md) restava aberta a «stack concreta do protocolo P2P (bibliotecas, transporte, identidade)».

Sem escolha documentada, o próximo código em `node/` arrisca ou inflar a superfície (ex.: puxar libp2p cedo) ou continuar com `node_id` livre como âncora de confiança. ADR 0001 permanece: P2P **independente** do SO; participar **não exige** o IA Livre.

Esta ADR fixou a stack no nível desenho (Etapa 14). A implementação mínima do v1 no host está na **Etapa 23** (`node/` + gate). Detalhe operacional do desenho: [`desenho-protocolo-rede-ia-livre.md`](../desenho-protocolo-rede-ia-livre.md).

## Decisão

1. **Protocolo próprio versionado:** **Rede IA Livre v1** — framing e mensagens do projeto, não um monólito de terceiros no próximo protótipo.
2. **Transporte:**
   - **TCP** — sessão (framing por linha UTF-8 versionado).
   - **UDP** — descoberta local (HELLO assinado).
   - **QUIC** — evolução candidata **documentada**; **fora** do próximo protótipo (não obrigatório agora).
3. **Identidade:** par de chaves **ed25519**; `PeerId` = fingerprint da chave pública; HELLO e handshake de sessão autenticam o peer. O `node_id` string do protótipo vira **apelido** opcional — **não** âncora de confiança.
4. **Descoberta (próximo protótipo):** (a) HELLO UDP **assinado** + versão de protocolo; (b) dial multiendereço explícito (`--peer` / lista). **mDNS / DHT / relay / NAT traversal completo** ficam nomeados como futuro — **não** critérios do próximo protótipo.
5. **Framing v1 (tipos mínimos):** `HELLO` (UDP), `IDENT` (handshake TCP), `MSG`/`ACK` (compatíveis com a prova atual), `PING`/`PONG` (liveness).
6. **Bibliotecas no próximo protótipo:** preferir crates auditáveis e leves (ex.: `ed25519-dalek` ou equivalente). **Não** adotar **libp2p** (nem Iroh / equivalente monolítico) como dependência do próximo protótipo — motivo: controle do framing, superfície menor, evolução alinhada ao manifesto sem amarrar o protocolo a um stack externo cedo.
7. **Fronteira ADR 0001:** o desenho v1 aplica-se a nós em SO convencional e (futuro) nós nativos; o SO não é pedágio de entrada.

### O que esta ADR **não** decide

- Implementação no crate `node/` (código, gate novo, breaking do protótipo).
- NAT traversal, DHT/Kademlia, relay, marketplace, integração runtime/kernel.
- QUIC como transporte obrigatório.
- ABI multi-linguagem estável ou “Rede pronta para produção”.

## Consequências

### Positivas

- Fecha a lacuna de architecture no nível **desenho** com **uma** stack candidata
- Identidade criptográfica no caminho crítico sem exigir libp2p
- Mantém o protótipo Etapa 6 como base evolutiva (MSG/ACK preserváveis até etapa de implementação)
- Alinha P2P ao ADR 0001 (independência do SO)

### Negativas

- Protocolo próprio exige manutenção e especificação explícita (sem herdar ecossistema libp2p de graça)
- Sem NAT/DHT no próximo protótipo, a malha continua LAN/`--peer`-centrada
- Risco de reinventar peças se o escopo de descoberta crescer cedo demais — por isso DHT/NAT ficam **fora** desta decisão

## Relação com etapas e ADRs

| Peça | Papel |
|------|--------|
| ADR 0001 | Independência SO × P2P — intacta |
| Etapa 6 | Protótipo HELLO/MSG/ACK — continua válido até etapa de implementação do v1 |
| Etapa 14 | Esta ADR + doc de desenho |
| Etapa 23 | Implementação v1 mínima em `node/` (IDENT + HELLO assinado + PeerId + PING/PONG) |
| Futuro | NAT/DHT/relay; reavaliar libp2p só com ADR nova |

Doc de desenho (Task 2): [`docs/desenho-protocolo-rede-ia-livre.md`](../desenho-protocolo-rede-ia-livre.md) (a criar).
