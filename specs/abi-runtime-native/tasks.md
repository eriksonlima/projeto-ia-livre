# Tasks — ABI mínima estável kernel↔runtime-native

Etapa 71 · Spec: `specs/abi-runtime-native/`  
Desfecho: **A** (ABI mínima freestanding versionada + consumidor nativo). Pivot **B** só se A colapsar na Task 1.

Uma task = uma fatia. Ordem = implementação.

- [x] Task 1 — Contrato ABI v1: `docs/abi-runtime-native.md` (natureza freestanding ≠ syscall; `ABI_VERSION`; superfície mínima MemClass/Phase/layout/`prepare`/marcadores; fora de escopo da ABI; pontes E19/E20/ADR 0003/0010; nome do consumidor e do gate; critérios de pivot B «glue ≠ ABI estável»). ADR 0025 só se necessário.
  - **Pronto quando:** contrato versionado no repo descreve a superfície mínima, version id, fronteira ADR 0001 (motor fora do kernel) e confirma A (ou registra pivot B com critérios de estabilização); sem gate novo obrigatório ainda.
  - **Arquivos previstos:** `docs/abi-runtime-native.md` + pontes curtas; opcional `docs/adr/0025-….md`.

- [x] Task 2 — Version id + consumidor nativo: constante(s) em `runtime-native` (+ glue mínimo no kernel se o consumidor for o guest); emitir `ABI_VERSION` + `ABI_OK` (nomes da Task 1) exercitando MemClass/Phase/layout handshake; **sem** mover Prefill/Decode/dequant/sampling para `kernel/src`; **sem** inventar `TOKENS_PER_S`/`COMPROVA`/`METAL_OK`.
  - **Pronto quando:** consumidor nativo no host de referência (freestanding e/ou serial guest documentado) prova o contrato com version id + sucesso; fronteira ADR 0001 preservada na revisão do diff.
  - **Arquivos previstos:** `runtime-native/src/lib.rs` (e/ou `abi.rs`); opcional `kernel/src/main.rs` (glue só); opcional teste freestanding.

- [x] Task 3 — Gate aditivo + AGENTS: `scripts/verify-abi-runtime-native.sh` + `make verify-abi-runtime-native`; prova A; regressão `make verify` + `make verify-runtime-contract`; README avaliado (`readme-por-fatia`); desfecho no roadmap/Memory Bank (agente principal).
  - **Pronto quando:** gate verde com version id + `ABI_OK` (ou teto B documentado); regressões verdes; `AGENTS.md` documenta Como rodar/verificar; README considerado; critério Pronto quando da Etapa 71 cumprido.
  - **Arquivos previstos:** `scripts/verify-abi-runtime-native.sh`, `Makefile`, `AGENTS.md`; opcional `README.md`.
