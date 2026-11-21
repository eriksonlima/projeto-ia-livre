# Tasks — Autonomia mínima no caminho nativo (ou bridge SO↔host)

Uma task = uma fatia. Ordem = implementação.

- [x] Task 1 — Contrato + decisão B: `docs/autonomia-bridge-nativo.md` (e ADR curto se couber); fixar marcadores `IA_LIVRE_BRIDGE_*`, fontes `blockio` vs `metal_block`, rejeição de A/shell/fraude host-as-native; pontes ADR 0001/0005 e docs de autonomia/runtime; nome do gate/`make` target.
- [x] Task 2 — Bridge host mínima: script/consumidor que obtém evidência nativa (log serial ou subprocesso documentado do repo), valida marcadores da fonte, emite `BRIDGE_OK` (+ `BRIDGE_MODE` / `BRIDGE_NATIVE_SRC`); allowlist intacta; sem shell irrestrito; one-shot `agent/` só se necessário ao critério.
- [x] Task 3 — Gate + AGENTS: `scripts/verify-…` + `Makefile`; prova B no host de referência; `verify-agent` permanece independente do SO; README avaliado (`readme-por-fatia`); registrar desfecho no roadmap/Memory Bank (agente principal).
