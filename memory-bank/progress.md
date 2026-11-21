# Progress

## O que funciona

- Etapas 1–32
- E32: tokenize + embed + camada parcial; `B_BLOCK=no_gguf_decode`; harness/comparable `INCONCLUSIVO`

## Bloqueios

- Sem Prefill/Decode/sampling / `TOKENS_PER_S` em B (`no_gguf_decode`)
- E33 = re-corrida quieta exigindo tokens reais em B (ou motivo ≠ ausência)

## Por etapa

- 1–32: feitas
- 33: em_andamento (#32) — B26 promovido; spec a definir
