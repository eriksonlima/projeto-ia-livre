# Tasks — Geração canônica Prefill+Decode+sampling na Linha B

Uma task = uma fatia.

- [x] Task 1 — ADR 0013 + marcadores intermediários (tokenize/embed/camada) + critério inviável; pontes docs/`AGENTS.md`
- [x] Task 2 — Tokenização mínima + embedding lookup (`token_embd` Q4_K) com evidência (unit test e/ou serial); sem `TOKENS_PER_S`
- [x] Task 3 — Camada transformer parcial (attn ou FFN) + tentativa Prefill/Decode/sampling → `RUNTIME_NATIVE_OK` + métricas **ou** `B_BLOCK` novo (≠ `no_gguf_generate`) com embedding+camada evidenciados
- [x] Task 4 — Harness B + comparable + docs alinhados ao desfecho (geração **ou** bloqueio novo); README avaliado
