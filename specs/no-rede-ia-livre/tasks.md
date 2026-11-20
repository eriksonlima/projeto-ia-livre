# Tasks — Protótipo do nó Rede IA Livre

Uma task = uma fatia.

- [x] Task 1 — Scaffold do crate `node/` (Rust host no workspace, CLI mínima `ia-livre-node`), documento do protocolo mínimo em `docs/rede-ia-livre-prototipo.md`, e **Como rodar** parcial em `AGENTS.md` (independência do SO explícita); sem regressão estrutural do workspace/kernel
  - **Pronto quando:** `cargo build -p ia-livre-node` sucede; doc descreve framing/descoberta/mensagem e que participar não exige o IA Livre; AGENTS lista o layout `node/` e pré-requisitos só de Rust host.

- [x] Task 2 — Descoberta mínima (UDP `HELLO` e/ou `--peer`) + sessão TCP entre dois processos no mesmo host, com marcador `IA_LIVRE_PEER_OK`
  - **Pronto quando:** dois processos documentados em **Como rodar** conectam-se; `IA_LIVRE_PEER_OK` aparece na stdout; fallback `--peer` existe se UDP falhar no ambiente.

- [x] Task 3 — Troca da mensagem de prova documentada (`IA_LIVRE_MSG_OK`), script/alvo `verify-node`, e gate adicional completo em `AGENTS.md` → **Como verificar**
  - **Pronto quando:** `make verify-node` (ou script equivalente) sobe dois nós, confirma `IA_LIVRE_PEER_OK` + `IA_LIVRE_MSG_OK` e exit 0; doc do protocolo e AGENTS fecham o fluxo; gates do kernel/runtime não são removidos.
