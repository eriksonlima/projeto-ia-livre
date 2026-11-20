# Tasks — Ambiente de autonomia (camada 3)

Uma task = uma fatia.

- [x] Task 1 — Scaffold do crate `agent/` (Rust host no workspace, CLI mínima `ia-livre-agent`), documento do protótipo em `docs/ambiente-autonomia-prototipo.md` (loop, memória, ferramenta, consumo do runtime, independência do SO/QEMU), e **Como rodar** parcial em `AGENTS.md`; sem regressão estrutural do workspace/kernel
  - **Pronto quando:** `cargo build -p ia-livre-agent` sucede; doc descreve o contrato mínimo da camada 3 e que o protótipo não exige o IA Livre; AGENTS lista o layout `agent/` e pré-requisitos (Rust host + runtime/modelo).

- [ ] Task 2 — Loop mínimo do cenário de prova consumindo `ia-livre-runtime` + pelo menos uma ferramenta com efeito observável e marcador `IA_LIVRE_TOOL_OK`
  - **Pronto quando:** comando documentado em **Como rodar** invoca o runtime existente, executa a ferramenta de prova de forma determinística (não só via parsing frágil do SLM) e imprime `IA_LIVRE_TOOL_OK`.

- [ ] Task 3 — Memória persistente verificável (`IA_LIVRE_MEMORY_OK`), fechamento do loop (`IA_LIVRE_AGENT_OK`), script/alvo `verify-agent`, e gate adicional completo em `AGENTS.md` → **Como verificar**
  - **Pronto quando:** `make verify-agent` (ou script equivalente) confirma os três marcadores e exit 0; doc do protótipo e AGENTS fecham o fluxo; gates do kernel/runtime/nó não são removidos; documentado que não exige UEFI/QEMU.
