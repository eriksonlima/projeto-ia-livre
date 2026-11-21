# Progress

## O que funciona

- Etapas 1–26 feitas
- E26: `GGUF_NATIVE_LOADER=esp_header`, `GGUF_STATUS=header_ok`, `B_BLOCK=no_gguf_infer`
- Gates: `verify` + `verify-harness` + `verify-harness-comparable` (INCONCLUSIVO)
- Baseline CPU serial: mediana ~13,4 tok/s (`docs/runtime-inferencia-cpu-metricas.md`)

## Bloqueios

- Sem geração/`TOKENS_PER_S` em B → hipótese INCONCLUSIVO (B21)
- Backlog: B21, B22

## Por etapa

- 1–26: feitas
- Próxima candidata: B21 (#27)
