# Tasks — Decode + sampling + TOKENS_PER_S canônico na Linha B

Uma task = uma fatia.

- [x] Task 1 — ADR 0015 + marcadores + critério A/B + baseline
- [x] Task 2 — Otimização guest release UEFI (`IA_LIVRE_KERNEL_PROFILE=release`); medição; sem inventar tokens
- [x] Task 3 — Decode+sampling greedy em `runtime-native` (2L × n_predict=1) → métricas guest reais
- [x] Task 4 — Harness B `LOAD_KIND=gguf` + comparable INCONCLUSIVO (subset ≠ espécie A); docs; README avaliado (sem mudança capa)

## Desfecho

- `DECODE_OK` / `SAMPLING_OK` / `RUNTIME_NATIVE_OK` / `TOKENS_PER_S` medidos
- `B_BLOCK` omitido no sucesso
- Comparable: `INCONCLUSIVO` / `E44_subset_generate_not_canonical_species_layers=2_npredict=1`
- Gates: `make verify`, `verify-harness`, `verify-harness-comparable`, `verify-docs-consistency`
