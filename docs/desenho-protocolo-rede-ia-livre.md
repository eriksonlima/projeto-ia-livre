# Desenho — Protocolo Rede IA Livre v1

Stack candidata além do protótipo HELLO/MSG/ACK.  
**Nível:** desenho (Etapa 14). **Não** implementação. O crate `node/` atual **não** fala v1.

ADR: [`docs/adr/0004-stack-protocolo-rede-ia-livre.md`](adr/0004-stack-protocolo-rede-ia-livre.md).  
Protótipo Etapa 6: [`docs/rede-ia-livre-prototipo.md`](rede-ia-livre-prototipo.md).  
ADR 0001: P2P independente do SO.

## Motivação

| Limite do protótipo (E6) | Resposta v1 (desenho) |
|--------------------------|------------------------|
| `node_id` livre (spoof trivial) | `PeerId` = fingerprint ed25519 |
| HELLO sem autenticação | HELLO assinado + versão |
| Só MSG/ACK | + `IDENT`, `PING`/`PONG` |
| Sem noção de versão de protocolo | Framing **v1** explícito |

## Identidade

1. Gerar par ed25519 no primeiro start (persistir chave fora do git).
2. `PeerId` = representação estável da chave pública (ex. hex/multihash — fixar na implementação).
3. Apelido (`node_id`) opcional para UX — **não** âncora de confiança.
4. Sessão TCP: troca `IDENT` (PeerId, pubkey, nonce, assinatura) antes de MSG de aplicação.

## Transporte e mensagens v1

| Tipo | Transporte | Papel |
|------|------------|--------|
| `HELLO` | UDP | Descoberta local; inclui versão, PeerId, tcp_port, assinatura |
| `IDENT` | TCP | Handshake de identidade / anti-replay (nonce) |
| `MSG` / `ACK` | TCP | Aplicação; compatível com a prova atual do gate |
| `PING` / `PONG` | TCP | Liveness |

Framing: linhas UTF-8 `\n` (igual ao protótipo), com campos versionados documentados na implementação.

### Fluxo canônico

```
UDP HELLO (assinado)  →  valida PeerId/sig
TCP dial              →  IDENT ↔ IDENT
MSG / ACK             →  prova de aplicação
PING / PONG           →  opcional
```

## Descoberta — fronteira do próximo protótipo

**Entra no próximo protótipo (implementação futura):**

- [ ] Chaves ed25519 + PeerId
- [ ] HELLO UDP assinado + versão de protocolo
- [ ] IDENT no TCP
- [ ] MSG/ACK compatível (gate atual ou evolução documentada)
- [ ] PING/PONG
- [ ] Dial `--peer` / lista de peers conhecidos

**Continua fora (só nomeado):**

- mDNS, DHT/Kademlia, relay, STUN/TURN/hole-punching
- marketplace / economia
- integração com runtime ou kernel
- libp2p / Iroh como dependência do próximo protótipo
- QUIC obrigatório

## Alternativas consideradas

| Alternativa | Por que não agora |
|-------------|-------------------|
| libp2p first | Superfície grande; framing menos controlável; reavaliar se NAT/DHT virarem críticos |
| QUIC-first | Bom caminho futuro; próximo protótipo aproveita TCP/UDP já gateados |
| Identidade só X.509 | Mais pesado para nó comunitário mínimo; ed25519 basta no v1 |

## Não-objetivos

- Rede “pronta para produção”
- Obsolecer o protótipo E6 sem etapa de implementação
- Amarrar participação ao SO IA Livre

## Implementação futura

1. Etapa/backlog: implementar v1 em `node/` + gate
2. Depois: descoberta WAN (NAT/DHT) se a comunidade exigir
3. Reavaliar libp2p só com ADR nova
