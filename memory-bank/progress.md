# Progress

## O que funciona

- Etapas 1–27
- E26/E27: path GGUF em B (`esp_header` → `blockio_full` + stub)
- Gates verify / verify-harness / comparable (INCONCLUSIVO)
- Baseline CPU serial ~13,4 tok/s

## Bloqueios

- Sem motor de geração em B → `no_gguf_infer_engine` → hipótese INCONCLUSIVO
- Backlog: B22 (protocolo de corrida quieta)

## Por etapa

- 1–27: feitas
