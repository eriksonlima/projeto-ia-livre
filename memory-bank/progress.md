# Progress

## O que funciona

- Etapas 1–31
- E31: tensor map + Q4_K dequant + op parcial em `runtime-native`
- E32 Task 1: ADR 0013 + marcadores TOKENIZE/EMBED/LAYER_PARTIAL

## Bloqueios

- Ainda sem Prefill/Decode/sampling / `TOKENS_PER_S` em B
- E32 Tasks 2–4 abertas

## Por etapa

- 1–31: feitas
- 32: em_andamento (#42) — Task 1 feita; 2–4 pendentes
