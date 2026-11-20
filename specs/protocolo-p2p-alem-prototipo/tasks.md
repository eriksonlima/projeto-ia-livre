# Tasks — Protocolo P2P além do protótipo (stack / identidade)

Uma task = uma fatia.

- [ ] Task 1 — ADR da stack candidata (transporte, identidade, descoberta)
  - **Pronto quando:** existe ADR nova (ex.: `docs/adr/0004-stack-protocolo-rede-ia-livre.md`) com status aceita *no nível desenho*: decide protocolo Rede IA Livre **v1** próprio sobre **TCP + UDP**, identidade **ed25519** / `PeerId`, descoberta com HELLO assinado + dial multiendereço, e framing além de MSG/ACK (`IDENT`, `PING`/`PONG`); afirma fronteira ADR 0001 (P2P independente do SO); **adia** libp2p e NAT/DHT completos no próximo protótipo com motivo; lista consequências e o que **não** fica decidido (implementação, QUIC obrigatório, marketplace). Sem código de produto. README avaliado (`readme-por-fatia`).

- [ ] Task 2 — Doc de desenho do protocolo v1 e fronteira do próximo protótipo
  - **Pronto quando:** `docs/desenho-protocolo-rede-ia-livre.md` (ou nome alinhado à ADR) descreve motivação vs protótipo Etapa 6, modelo de identidade (chave / PeerId / apelido), tabela de mensagens v1, fluxo HELLO→IDENT→MSG/ACK, o que entra no **próximo protótipo** vs o que fica fora (mDNS, DHT, NAT/relay, marketplace, integração runtime/kernel, libp2p); alternativas consideradas; deixa explícito que `node/` atual **não** implementa v1. Sem código de produto. README reavaliado.

- [ ] Task 3 — Pontes em architecture / protótipo do nó e fechamento documental
  - **Pronto quando:** `docs/architecture.md` marca a stack concreta do P2P como **decidida no nível desenho** (link ADR + doc), mantendo implementação **aberta**; ponte mínima em `docs/rede-ia-livre-prototipo.md` (Etapa 6 = protótipo; Etapa 14 = desenho ≠ código); `AGENTS.md` aponta os docs se a estrutura pública precisar; README reavaliado; etapa pronta para revisão (não marcar `feita` aqui). Sem código de produto.
