# Active context

## Foco atual

- Etapa 43 **feita** (subset Prefill 2L×2 + KV; `no_gguf_prefill_22l`)
- Próximo: promover **B38** (Decode + sampling + `TOKENS_PER_S` em B) → Etapa 44

## Mudanças recentes

- ADR 0014: critério 22L vs subset; QEMU debug 2L×16 timeout 600s → guest 2×2
- `runtime-native`: attn/FFN `blk.N`, KvCache GQA, RoPE, prefill multi
- Gates: `PREFILL_PARTIAL_OK` / `KV_CACHE_OK` / `B_BLOCK=no_gguf_prefill_22l`
- Comparable reason `E43_no_gguf_prefill_22l_subset_kv_ok`

## Próximo passo

- Sync + claim; promover B38 → roadmap; especificar/fatiar Decode

## Notas

- Lease: liberar após push da fatia E43
- README capa: sem mudança (AGENTS/docs cobrem)
