# Tasks — Re-corrida harness A vs B com geração real em B (Etapa 33)

Uma task = uma fatia.

- [x] Task 1 — RMSNorm + atenção completa 1 camada (`attn_q/k/v/output` Q4_K, GQA, produto Q·K^T/√d + softmax mínimo + ·V + residual) em `runtime-native/`; `ATTN_LAYER_OK` (serial ou unit test host); sem `TOKENS_PER_S`
- [x] Task 2 — FFN SwiGLU 1 camada completa (`ffn_gate/up/down` Q4_K, SiLU, residual) + loop Prefill multi-camada (N_LAYER iterações sobre token de entrada + KV cache mínimo documentado) → `FFN_LAYER_OK` + `PREFILL_OK` **ou** `B_BLOCK` novo (≠ `no_gguf_decode`, ex. `no_gguf_kv_cache` / `no_gguf_full_prefill`) após (1) verificado
- [x] Task 3 — Loop Decode autoregressivo N=32 + sampling argmax (output_norm + output.weight + argmax) + `rdtsc` para métricas → `RUNTIME_NATIVE_OK` + `LOAD_KIND=gguf` + `LOAD_S`/`TOKENS_PER_S` medidos **ou** `B_BLOCK` novo (≠ `no_gguf_decode`, ex. `no_gguf_sampling` / `no_gguf_decode_loop`) após (1)+(2) verificados; harness B + comparable atualizados (reason ≠ `E32_no_gguf_decode`)
- [x] Task 4 — Re-corrida quieta (`harness-corrida-quieta.md`): `make verify-harness-comparable` exit 0 com `VERDICT_REASON` ≠ ausência de tokens B; docs finais (`runtime-nativo-linha-b.md` seção E33, `harness-a-b-comparavel.md`, `harness-corrida-quieta.md` evidência, `AGENTS.md`); README avaliado
