# Tasks — Nó Rede no SO nativo (pós-ExitBoot ou bridge)

Uma task = uma fatia. Ordem = implementação.

- [x] Task 1 — Contrato + decisão B: `docs/rede-bridge-nativo.md` (e ADR curto se couber); fixar marcadores `IA_LIVRE_NET_BRIDGE_*`, fonte nativa mínima do caminho B, âncora Rede host (preferir `TASK_OK`), rejeição de A/TCP teatral e de fraude host-as-native; pontes ADR 0001 / E49 / v1; nome do gate/`make` target.
- [x] Task 2 — Bridge host mínima: script/consumidor que obtém evidência nativa (log serial ou subprocesso documentado), valida marcadores do caminho B, ancora `ia-livre-node` (prova mínima), emite `NET_BRIDGE_OK` (+ `MODE` / `NATIVE_SRC`); sem portar nó ao kernel; sem alterar `verify-node` para exigir QEMU.
- [x] Task 3 — Gate + AGENTS: `scripts/verify-…` + `Makefile`; prova B no host de referência; `verify-node` permanece independente do SO; README avaliado (`readme-por-fatia`); registrar desfecho no roadmap/Memory Bank (agente principal).
