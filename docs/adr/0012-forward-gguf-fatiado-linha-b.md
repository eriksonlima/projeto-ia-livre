# ADR 0012 — Forward GGUF fatiado na Linha B

- Status: aceita
- Data: 2026-11-21

## Contexto

Etapa 29 deixou `prepare()` + `B_BLOCK=no_gguf_forward`. Porta completa TinyLlama Q4_K_M (attention+FFN+sampling) no guest é multi-etapa. Inventar `TOKENS_PER_S` é fraude.

## Decisão

1. **Fatia B:** mapa de tensores nomeados → dequant Q4_K (≥1 bloco) → ≥1 op honesta (ex. dot/checksum sobre pesos dequantizados).
2. **Preferência:** estender até Prefill+Decode+sampling canônicos quando viável.
3. **Fallback desta etapa:** se geração completa inviável — `B_BLOCK=no_gguf_generate` (mapa+dequant+op ok; sem tokens). **≠** `no_gguf_forward` (lacuna mudou).
4. Motor permanece em `runtime-native/` (ADR 0001/0010).

## Rejeitado

- Microbench/proxy como tokens; host-as-B; `LOAD_KIND=gguf` sem geração medida.

## Consequências

- Marcadores: `TENSOR_MAP_OK`, `Q4K_DEQUANT_OK`, `FORWARD_OP_OK`; sucesso pleno = `RUNTIME_NATIVE_OK` + métricas.
- Gates exigem intermediários + `no_gguf_generate` até existir geração.
