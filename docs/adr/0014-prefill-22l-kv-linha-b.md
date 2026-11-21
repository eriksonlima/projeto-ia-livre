# ADR 0014 — Prefill 22L + KV cache na Linha B

- Status: aceita
- Data: 2026-11-21

## Contexto

Etapa 33 entregou attn+FFN+prefill **layer0** (1 token) com `B_BLOCK=no_gguf_full_prefill`. A hipótese A vs B permanece **INCONCLUSIVO** sem Decode/`TOKENS_PER_S` (backlog B38). Prefill completo TinyLlama exige **22 camadas** × prompt multi-token + **KV GQA** — escopo desta etapa (43 / B37). Inventar métricas de geração ou fingir `PREFILL_LAYERS=22` é fraude.

## Decisão

1. **Preferência (caminho A):** Prefill multi-token sobre `CANONICAL_PROMPT_TOKEN_IDS` com loop `blk.0`…`blk.21` (22L), KV cache GQA por camada (`n_kv_head × head_dim × n_pos`), marcadores:
   - `IA_LIVRE_RUNTIME_NATIVE_PREFILL_LAYERS=22`
   - `IA_LIVRE_RUNTIME_NATIVE_KV_BYTES=` / `KV_N_POS=` / `KV_CACHE_OK`
   - `IA_LIVRE_RUNTIME_NATIVE_PREFILL_22L_OK`
   - `FORWARD_FAIL=no_decode` (ou omitir `no_full_prefill`)
   - `B_BLOCK=no_gguf_decode` (Decode/sampling = B38)
2. **Fallback (caminho B — subset):** só se inviável **após** generalizar attn/FFN ≥2 layers + KV multi-pos ≥2 + medição QEMU/host. Emitir:
   - `PREFILL_LAYERS=N` com **N&lt;22** documentado
   - `PREFILL_PARTIAL_OK` + `KV_*`
   - `B_BLOCK=no_gguf_prefill_22l` (**≠** reutilizar `no_gguf_full_prefill` sem avanço)
3. Motor em `runtime-native/`; kernel só glue/serial (ADR 0001 / 0010 / 0013).
4. **Proibido:** `TOKENS_PER_S`, `LOAD_KIND=gguf`, Decode autoregressivo, `PREFILL_LAYERS=22` mentiroso.

### Critério de “inviável” (subset permitido)

Só depois de: (1) attn/FFN `blk.N` ≥2 layers verificável; (2) KV ≥2 posições verificável; (3) medição.

Exemplos honestos:

- Estimativa host release **≥ ~180 s** só no forward 22L×16 tokens **e** QEMU/timeout de gate inviável mesmo com **uma** extensão documentada de `VERIFY_TIMEOUT`.
- OOM / fragmentação no guest com KV+pesos.
- Timeout verify após extensão única registrada neste ADR / `runtime-nativo-linha-b.md`.

**Não** é inviável: demorado mas passa o gate; fechar sem generalizar layer; manter `no_gguf_full_prefill` sem novos marcadores.

### Baseline QEMU (E33 → E43 Task 1)

| Item | Valor |
|------|--------|
| Estado | E33: layer0 + `no_gguf_full_prefill` |
| RAM QEMU | `-m 1536M` (inalterado; KV subset ≪ 1 MiB) |
| KV estimado 22L×16 pos | ≈ 22 × 16 × 256 × 4 × 2 ≈ **704 KiB** |
| Baseline `make verify` E33 | **~93 s** (medido Task 1) |
| Forward 1L×1 tok (host release) | ~0,7 s |
| Prefill 2L×16 (host release) | **~6,8 s** (medido) |
| Extrapolação 22L×16 | ~ **250 s** host — QEMU debug mais lento → inviável no timeout |

**Decisão Task 1+3:** subset guest **`PREFILL_LAYERS_GUEST=2` × `PREFILL_POS_GUEST=2`** (mesmas ops attn/FFN/KV; ≥2 layers × ≥2 pos). Prompt completo × 2L verificado em **host** (`cargo test`). QEMU debug: 2L×16 estourou 600 s após `PREFILL_OK` layer0. `B_BLOCK=no_gguf_prefill_22l` + `VERIFY_TIMEOUT` default **600 s** (uma extensão).

### Relação com ADR 0013 / B38

| ADR / item | Papel |
|------------|--------|
| 0013 | Fatia até geração; intermediários tokenize/embed/layer |
| **0014** | Prefill multi-layer + KV; fronteira **antes** de Decode |
| B38 | Decode + sampling + `TOKENS_PER_S` honestos |

## Rejeitado

- Emitir `TOKENS_PER_S` / `LOAD_KIND=gguf` nesta etapa.
- Prefill “22L” sem KV multi-token.
- Host-as-B; microbench como prefill GGUF.
- Engessar llama.cpp no kernel.

## Consequências

- Gates E43 exigem `PREFILL_22L_OK`+`KV_CACHE_OK` **ou** `PREFILL_PARTIAL_OK`+`PREFILL_LAYERS=N`+`no_gguf_prefill_22l`.
- Comparable permanece **INCONCLUSIVO** (sem tokens); `VERDICT_REASON` atualiza se sair de `E33_no_gguf_full_prefill_*`.
- Proxy Linha B (`LOAD_KIND=proxy`) preservado até B38.
