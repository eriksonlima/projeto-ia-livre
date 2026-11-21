# Progress

## O que funciona

- Etapas 1–34
- E33: attn+FFN layer0; `no_gguf_full_prefill`
- E34: `A_otimizada` script + gate

## Bloqueios

- Sem TOKENS_PER_S em B (22L/KV)
- E35 bare-metal exige hardware real (pode `BAREMETAL_SKIP` honesto)

## Por etapa

- 1–34: feitas
- 35: em_andamento (#34) — B28 promovido
