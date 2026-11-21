# Progress

## O que funciona

- Etapas 1–23 feitas
- E21: `CONTRACT_READY` + `B_BLOCK=no_gguf_path`
- E22: `make verify-harness-comparable` → `VERDICT=INCONCLUSIVO`
- E23: Rede v1 em `node/` — `make verify-node` → PEER/MSG/IDENT/PING

## Bloqueios

- GGUF real em B ausente → prova A vs B permanece inconclusiva até loader nativo

## Por etapa

- 1–23: feitas
- 24–25: pendente (branches `etapa-b18` / `b19`)
