# Progress

## O que funciona

- Etapas 1–38
- E38: `GPU_MGR=native` + afinidade/placement no `make verify`
- E37: GOP + `OBS_OK`

## Bloqueios

- Sem TOKENS_PER_S em B (22L/KV)
- Sem log metal real (SKIP)
- Multi-GPU shard ainda só documentado

## Por etapa

- 1–38: feitas
- 39: em_andamento (#38) — descoberta WAN mínima
