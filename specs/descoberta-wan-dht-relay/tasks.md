# Tasks — Descoberta WAN (NAT/DHT/relay)

Etapa 67 · Spec: `specs/descoberta-wan-dht-relay/`

Uma task = uma fatia.

- [x] Task 1 — Contrato WAN/relay em `rede-descoberta-wan` + decisão A (relay TCP mínimo) vs B (ADR `0025` + skip): flags, precedência, marcadores, nome do gate; DHT stub/adiado; ponte v1/ADR 0004; pré-anunciar em `AGENTS.md`
- [x] Task 2 — Caminho A: dial/forward via relay em `node/` (`DISC_MODE=relay` + `DISC_OK`, sem libp2p) **ou** caminho B: ADR inviabilidade + marcadores de skip/bloqueio (sem fingir WAN)
- [x] Task 3 — Gate (estágio/`verify-node-relay`) + anti-fraude; regressão `make verify-node` (ADR 0001); `AGENTS.md` + README (`readme-por-fatia`)
