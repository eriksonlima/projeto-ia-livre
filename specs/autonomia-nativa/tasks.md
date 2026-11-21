# Tasks — Autonomia consumindo runtime/evidência nativa

Etapa 70 · Spec: `specs/autonomia-nativa/`  
Desfecho: **A** (consumo host da evidência bridge). Pivot **B** só se A colapsar na Task 1.

Uma task = uma fatia. Ordem = implementação.

- [x] Task 1 — Contrato «consumir ≠ validar»: doc (`docs/autonomia-nativa.md` ou seção em `autonomia-bridge-nativo.md`); fixar marcadores `IA_LIVRE_NATIVE_CONSUME_*`, mecanismo mínimo de injeção (memória/`--prompt`/tool), fontes `blockio`/`metal_block`, nome do runner/gate; pontes ADR 0001/0018; critérios de pivot B («bridge = máximo até X»).
  - **Pronto quando:** contrato versionado no repo descreve E70 vs E49, marcadores, proibições (guest/shell/`TOKENS`/`METAL_OK`/`COMPROVA`/fraude host-as-native) e confirma A (ou registra pivot B com critérios de reabertura); sem gate novo obrigatório ainda.
  - **Arquivos previstos:** `docs/autonomia-nativa.md` (ou extensão bridge) + pontes curtas; opcional esqueleto de ADR se B.

- [x] Task 2 — Consumidor host: `scripts/run-autonomia-nativa.sh` (e extensão mínima de `agent/` se necessário) obtém `BRIDGE_OK`, injeta evidência nativa no caminho de autonomia, emite `NATIVE_CONSUME_*` com prova de uso; allowlist intacta; sem shell irrestrito; sem agente no kernel.
  - **Pronto quando:** one-shot/script no host de referência consome fonte bridge (fixture/log ok) e imprime `NATIVE_CONSUME_OK` + `SRC=`; falha se só ecoar bridge; **não** inventa `TOKENS_PER_S`/`METAL_OK`.
  - **Arquivos previstos:** `scripts/run-autonomia-nativa.sh`; opcional `agent/src/main.rs` (+ fixtures se couber).

- [x] Task 3 — Gate aditivo + AGENTS: `scripts/verify-autonomia-nativa.sh` + `make verify-autonomia-nativa`; prova A; `verify-agent` permanece independente do SO; `verify-autonomia-bridge` intacto; README avaliado (`readme-por-fatia`); desfecho no roadmap/Memory Bank (agente principal).
  - **Pronto quando:** gate verde com `NATIVE_CONSUME_OK`; regressão `verify-agent` sem QEMU; `AGENTS.md` documenta Como rodar/verificar; README considerado; critério Pronto quando da Etapa 70 cumprido (ou B documentado se pivot).
  - **Arquivos previstos:** `scripts/verify-autonomia-nativa.sh`, `Makefile`, `AGENTS.md`; opcional `README.md`.
