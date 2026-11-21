# Progress

## O que funciona

- Etapas 1–33
- E33: attn+FFN layer0 + prefill parcial; `B_BLOCK=no_gguf_full_prefill`; comparable INCONCLUSIVO com reason estrutural

## Bloqueios

- Sem Prefill 22L / Decode / `TOKENS_PER_S` em B
- Topo backlog após E34: B28 bare-metal…

## Por etapa

- 1–33: feitas
- 34: em_andamento (#33) — B27 promovido; spec a definir
