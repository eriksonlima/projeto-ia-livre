# Progress

## O que funciona

- Etapas 1–31
- E31: tensor map + Q4_K dequant + op parcial em `runtime-native`

## Bloqueios

- `B_BLOCK=no_gguf_generate` — sem Prefill/Decode/sampling
- Topo backlog: **B36** geração canônica

## Por etapa

- 1–31: feitas
