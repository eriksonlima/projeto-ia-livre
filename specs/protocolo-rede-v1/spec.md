# Spec — Protocolo Rede IA Livre v1 (impl. em node/)

## Resultado visível

O crate `node/` (`ia-livre-node`) implementa o **protocolo Rede IA Livre v1** conforme ADR 0004 / desenho Etapa 14:

1. Identidade **ed25519** com `PeerId` = fingerprint estável da chave pública.
2. `HELLO` UDP **assinado** + versão de protocolo.
3. Handshake TCP `IDENT` (PeerId, pubkey, nonce, assinatura) antes de MSG de aplicação.
4. `MSG`/`ACK` compatíveis com a prova atual do gate (`ola-rede-ia-livre`).
5. `PING`/`PONG` (liveness) na sessão TCP.
6. Dial explícito `--peer` preservado (preferido no gate).

`make verify-node` (ou extensão documentada) fica **verde**. Participar da Rede **não exige** o SO IA Livre (ADR 0001). Sem libp2p, NAT, DHT, marketplace ou QUIC obrigatório.

## Contexto fixo (não reinventar)

- ADR 0004 (aceita, desenho): [`docs/adr/0004-stack-protocolo-rede-ia-livre.md`](../../docs/adr/0004-stack-protocolo-rede-ia-livre.md) — TCP+UDP, ed25519/PeerId, framing v1, sem libp2p no próximo protótipo.
- Desenho operacional: [`docs/desenho-protocolo-rede-ia-livre.md`](../../docs/desenho-protocolo-rede-ia-livre.md) — checklist do que entra nesta implementação.
- Protótipo Etapa 6 (base a evoluir): [`docs/rede-ia-livre-prototipo.md`](../../docs/rede-ia-livre-prototipo.md) + `node/src/main.rs` — TCP linhas UTF-8, UDP `HELLO <node_id> <tcp_port>`, `MSG`/`ACK`, `--peer`, marcadores `IA_LIVRE_PEER_OK` / `IA_LIVRE_MSG_OK`, gate `scripts/verify-node.sh`.
- ADR 0001: P2P **independente** do SO; participar **não exige** o IA Livre.
- Spec de desenho (Etapa 14, feita): `specs/protocolo-p2p-alem-prototipo/` — esta etapa **implementa** o que aquela só desenhou.
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`; se não precisar, registrar.

## Decisão de implementação (obrigatória)

| Peça | Escolha |
|------|---------|
| Forma | **Implementação** no crate `node/` (host Linux `std`) — evolui o protótipo E6, não reescreve do zero |
| Protocolo | **Rede IA Livre v1** — framing por linha UTF-8 `\n`, campos versionados |
| Identidade | Par **ed25519** (crate leve, ex. `ed25519-dalek`); chave persistida fora do git (path documentado sob `build/` ou `~/.config` / flag CLI); `PeerId` = hex lowercase da chave pública (32 bytes → 64 chars) **ou** fingerprint SHA-256 truncado documentado — **uma** forma fixada na Task 1 e na doc |
| Apelido | `--node-id` permanece **apelido opcional** (UX); **não** âncora de confiança |
| HELLO UDP | `HELLO v1 <peer_id> <tcp_port> <pubkey_hex> <sig_hex>` (campos exatos na doc); assinatura cobre os campos canônicos; rejeitar HELLO sem sig válida / PeerId ≠ fingerprint(pubkey) |
| IDENT TCP | Antes de MSG: troca mútua `IDENT v1 <peer_id> <pubkey_hex> <nonce_hex> <sig_hex>`; anti-replay via nonce; falha → não emitir `PEER_OK` de sessão autenticada |
| MSG/ACK | Manter `MSG <texto>` / `ACK <texto>` da prova (`ola-rede-ia-livre`); gate atual continua válido; opcional prefixar versão só se documentado e o gate for estendido |
| PING/PONG | `PING <nonce>` / `PONG <nonce>` na sessão TCP após IDENT; pelo menos um ciclo verificável (marcador opcional ou cobertura no gate estendido) |
| Dial | `--peer host:port` obrigatório como fallback; gate preferencialmente usa `--peer` (como hoje) |
| Libs | `ed25519-dalek` (ou equivalente auditável); **proibido** libp2p / Iroh / monolito equivalente nesta etapa |
| Ambiente | Só host; sem QEMU/GGUF/runtime/kernel como dependência do nó |

### Fluxo canônico (pós-implementação)

```
UDP HELLO v1 (assinado)  →  valida PeerId/sig
TCP dial (--peer ou após HELLO)  →
IDENT ↔ IDENT (nonce)    →  sessão autenticada
MSG / ACK (prova)        →  IA_LIVRE_PEER_OK + IA_LIVRE_MSG_OK
PING / PONG              →  liveness
```

### Marcadores

- Preservar: `IA_LIVRE_PEER_OK`, `IA_LIVRE_MSG_OK` (e opcionais `PEER_ADDR` / `NODE_ID`).
- Novos recomendados (documentar se adotados): `IA_LIVRE_PEER_ID=…`, `IA_LIVRE_PROTO=v1`, `IA_LIVRE_IDENT_OK`, `IA_LIVRE_PING_OK`.
- Gate mínimo: continua exigindo `PEER_OK` + `MSG_OK`; extensão documentada pode exigir `IDENT_OK` e/ou `PING_OK`.

### Compatibilidade com o gate E6

- `make verify-node` **não** pode regressar: dois processos, `--peer` no segundo, `PEER_OK` + `MSG_OK`, timeout `VERIFY_NODE_TIMEOUT` (default 45s) — ou extensão **documentada** em `AGENTS.md` / doc do protocolo.
- Breaking silencioso do framing E6 sem atualizar doc + script = rejeitado.

## Conteúdo obrigatório

### 1. Código em `node/`

- Geração/carga de chave ed25519; derivação de `PeerId`.
- HELLO UDP v1 assinado + validação na recepção; dial após HELLO válido (além de `--peer`).
- Sessão TCP: IDENT mútuo → MSG/ACK prova → PING/PONG.
- Sem dependência de `kernel/` ou `runtime/`.

### 2. Documentação

- Atualizar [`docs/rede-ia-livre-prototipo.md`](../../docs/rede-ia-livre-prototipo.md) **ou** criar `docs/rede-ia-livre-v1.md` (ponte clara) com framing v1, tabela de mensagens, identidade, defaults, marcadores, gate.
- Atualizar ponte no desenho ADR 0004 / `desenho-protocolo-rede-ia-livre.md`: checklist de implementação **cumprido** (honestidade: desenho ≠ código → agora código cobre o checklist mínimo).
- `AGENTS.md`: **Como rodar** / **Como verificar** do nó refletem v1 (flags novas se houver; independência do SO intacta).
- README: avaliar (`readme-por-fatia`).

### 3. Gate

- `scripts/verify-node.sh` + `make verify-node` verdes com o binário v1.
- Se o gate ganhar checks extras (`IDENT_OK` / `PING_OK`), documentar variáveis/timeout e manter o caminho `--peer` como canônico do script.

## Fora de escopo

- libp2p, Iroh, QUIC obrigatório
- mDNS, DHT/Kademlia, relay, STUN/TURN/hole-punching / NAT traversal
- Marketplace, economia, leilão de recursos
- Integração nó ↔ runtime / kernel / agente
- ABI multi-linguagem estável; “Rede pronta para produção”
- Alterar kernel, runtime, agent, harness além de pontes documentais
- Mudar ADR 0001 ou manifesto
- Marcar Etapa 23 `feita` nesta spec (só após gate + revisor pelo agente principal)
- Tocar Etapa 19 / lease de outro agente; não editar `AGENT_CLAIM.md` / promover backlog

## Critérios de aceite

- [ ] `node/` usa ed25519 + `PeerId` estável; apelido `--node-id` não é âncora de confiança
- [ ] HELLO UDP v1 assinado + versão; HELLO inválido não dispara dial confiável
- [ ] IDENT no TCP com nonce antes de MSG de aplicação
- [ ] MSG/ACK da prova preservados; `IA_LIVRE_PEER_OK` + `IA_LIVRE_MSG_OK` no fluxo `--peer`
- [ ] PING/PONG implementados e documentados (cobertos pelo gate ou marcador verificável)
- [ ] `make verify-node` verde (preservado ou extensão documentada)
- [ ] Doc + `AGENTS.md` descrevem v1 e independência do SO; README avaliado
- [ ] Sem libp2p/NAT/DHT/marketplace/QUIC obrigatório na entrega
- [ ] Etapa 23 não marcada `feita` nesta spec

## Riscos e rollback

- **Risco:** quebrar gate E6 ao mudar framing → evoluir com compat MSG/ACK; atualizar script e doc na mesma fatia do breaking.
- **Risco:** persistência de chave no git → path sob `build/` / home, gitignored; sem segredos no commit.
- **Risco:** escopo NAT/DHT “já que estamos no P2P” → rejeitar; Pronto quando = checklist ADR 0004 mínimo.
- **Risco:** colisão com agente da Etapa 19 → esta etapa só toca `node/` + docs P2P + scripts do nó; branch `etapa-b17-rede-v1`.
- **Rollback:** reverter commits do `node/`/docs/scripts do v1; protótipo E6 e gate antigo permanecem recuperáveis.

## Etapa do roadmap

- Etapa 23 — Protocolo Rede IA Livre v1 (impl. em node/) (`pendente` no ROADMAP canônico enquanto Etapa 19 está `em_andamento`; Issue [#23](https://github.com/eriksonlima/projeto-ia-livre/issues/23))
- Spec: `specs/protocolo-rede-v1/`
- Pronto quando (roadmap): contratos do desenho ADR 0004 cobertos em `node/` — ed25519/PeerId, HELLO UDP assinado, IDENT no TCP, MSG/ACK, PING/PONG, dial `--peer`; `make verify-node` (ou extensão documentada) verde; participação **sem** exigir o SO IA Livre; sem libp2p/NAT/DHT/marketplace.
