# Progress

## O que funciona

- Etapas 1–37
- E37: GOP fill+bitmap + `OBS_OK` no `make verify`; fallback input documentado
- E36: FULL_GGUF opt-in + BAREMETAL_GGUF_OK

## Bloqueios

- Sem TOKENS_PER_S em B (22L/KV)
- Sem log metal real (SKIP)
- GPU manager nativo ainda stub host (E25); E38 em andamento

## Por etapa

- 1–37: feitas
- 38: em_andamento (#37) — GPU manager nativo
