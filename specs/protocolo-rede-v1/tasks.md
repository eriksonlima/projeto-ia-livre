# Tasks — Protocolo Rede IA Livre v1 (impl. em node/)

Uma task = uma fatia.

- [x] Task 1 — Identidade ed25519 + PeerId + HELLO UDP assinado (v1)
  - **Pronto quando:** `node/` gera/carrega chave ed25519 (path fora do git), deriva `PeerId` estável (forma documentada), anuncia `HELLO` UDP v1 **assinado** com versão de protocolo e valida assinatura/PeerId na recepção; `--node-id` é só apelido; `--peer` ainda diala; `cargo build -p ia-livre-node` sucede; doc parcial do framing HELLO/identidade atualizada; sem libp2p/NAT/DHT; README avaliado (`readme-por-fatia`).

- [x] Task 2 — IDENT no TCP + sessão MSG/ACK (compat gate)
  - **Pronto quando:** após connect/accept, handshake `IDENT` mútuo (pubkey, PeerId, nonce, sig) precede MSG; dois processos com `--peer` completam IDENT + `MSG`/`ACK` da prova (`ola-rede-ia-livre`) e emitem `IA_LIVRE_PEER_OK` + `IA_LIVRE_MSG_OK`; IDENT inválido não autentica a sessão; framing documentado; sem marketplace/integração runtime-kernel; README reavaliado.

- [x] Task 3 — PING/PONG + documentação final + `make verify-node`
  - **Pronto quando:** `PING`/`PONG` na sessão autenticada (marcador opcional `IA_LIVRE_PING_OK` se adotado); `make verify-node` / `scripts/verify-node.sh` verdes (preservados ou extensão documentada); `AGENTS.md` (Como rodar / Como verificar) e doc do protocolo cobrem v1 + independência do SO; ponte no desenho/ADR 0004 (checklist mínimo implementado); README reavaliado; etapa pronta para revisão (não marcar `feita` aqui).
