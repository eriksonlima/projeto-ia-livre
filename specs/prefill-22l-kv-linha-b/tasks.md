# Tasks — Prefill completo 22L + KV cache viável na Linha B

Uma task = uma fatia.

- [x] Task 1 — ADR 0014 + marcadores (`PREFILL_22L_OK`, `KV_*`, `PREFILL_LAYERS`) + critério 22L vs subset; medição baseline QEMU; pontes docs/`AGENTS.md`; decisão `B_BLOCK` pós-sucesso (`no_gguf_decode` / subset `no_gguf_prefill_22l`)
- [x] Task 2 — Generalizar attn/FFN (`blk.N`) + `KvCache` GQA multi-pos (≥2 tokens × ≥2 layers em test host); sem loop 22; sem `TOKENS_PER_S`
- [x] Task 3 — Prefill multi-token: subset guest 2L×2 pos (`PREFILL_PARTIAL_OK` + `KV_CACHE_OK`) após inviabilidade 22L/16pos QEMU; host prova 2L×16; `ForwardError::NoDecode`
- [x] Task 4 — `verify-boot` / `verify-harness` / comparable reason + docs/`runtime-nativo-linha-b.md` alinhados; proxy preservado; README avaliado (sem mudança de capa — AGENTS/docs cobrem); **sem** `TOKENS_PER_S`

## Desfecho

- Subset ADR 0014: `PREFILL_LAYERS=2`, `KV_N_POS=2`, `PREFILL_PARTIAL_OK`, `KV_CACHE_OK`, `B_BLOCK=no_gguf_prefill_22l`
- Comparable: `INCONCLUSIVO` / `E43_no_gguf_prefill_22l_subset_kv_ok`
- Gate: `make verify` (~210s), `verify-harness`, `verify-harness-comparable`, `verify-docs-consistency`
