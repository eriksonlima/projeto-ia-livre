# ADR 0013 — Geração canônica fatiada na Linha B

- Status: aceita
- Data: 2026-11-21

## Contexto

Etapa 31 deixou mapa de tensores + dequant Q4_K + op parcial com `B_BLOCK=no_gguf_generate`. A hipótese A vs B continua **INCONCLUSIVO** sem tokens medidos em B. Porta completa do transformer TinyLlama (todas as camadas + KV + sampling) num único PR é inviável como escopo único; inventar `TOKENS_PER_S` é fraude.

## Decisão

1. **Fatia vertical em `runtime-native/`** (ADR 0001 / 0010 / 0012):
   1. Tokenização mínima do prompt canônico → ids fixos (ou tokenizer mínimo) + marcador `TOKENIZE_OK`.
   2. Embedding lookup no tensor `token_embd` (Q4_K) + `EMBED_OK`.
   3. ≥1 camada transformer **parcial** honesta (attn **ou** FFN com dequant/matmul reais) + `LAYER_PARTIAL_OK`.
   4. Preferência: Prefill + Decode + sampling → `RUNTIME_NATIVE_OK` + `LOAD_S` / `TOKENS_PER_S` medidos (`n-predict=32`, CPU).
2. **Fallback desta etapa:** se (4) inviável **após** (1)–(3) verificáveis — `B_BLOCK` **novo** (`no_gguf_decode` / `no_gguf_transformer` / `no_gguf_sampling`) — **≠** `no_gguf_generate`.
3. Motor permanece fora do kernel (glue/serial só).

### Marcadores intermediários (fixados)

| Marcador (kernel / harness) | Significado |
|-----------------------------|-------------|
| `IA_LIVRE_RUNTIME_NATIVE_TOKENIZE_OK` | Prompt canônico → ids |
| `IA_LIVRE_RUNTIME_NATIVE_EMBED_OK` | Lookup `token_embd` Q4_K |
| `IA_LIVRE_RUNTIME_NATIVE_LAYER_PARTIAL_OK` | ≥1 attn **ou** FFN parcial real |
| `IA_LIVRE_RUNTIME_NATIVE_OK` | Geração mínima ok (caminho sucesso) |
| `IA_LIVRE_RUNTIME_NATIVE_FORWARD_FAIL=` | Motivo residual se sem geração plena |

Harness reemite sob `IA_LIVRE_HARNESS_RUNTIME_NATIVE_*` quando aplicável.

### Critério de “inviável” (fallback permitido)

Só após tokenize + embed + camada parcial evidenciados. Exemplos honestos:

- Attention/KV/FFN **completos** + loop decode N=32 inviáveis sem fraude no prazo/RAM QEMU.
- Sampling mínimo sem logits de saída seguros.

**Não** é inviável: fechar a etapa sem (1)–(3), ou só renomear `no_gguf_generate`.

## Rejeitado

- Opção A: porta-tudo-de-uma-vez como escopo único da etapa.
- Opção C: inventar métricas; host-as-B; microbench/tipado/op-parcial-as-tokens; reutilizar `no_gguf_generate` após avanço real.
- Engessar llama.cpp / motor produto em `kernel/src/main.rs`.

## Consequências

- Gates E32 exigem intermediários; com geração: `LOAD_KIND=gguf` + métricas; sem: `B_BLOCK` novo + `INCONCLUSIVO`.
- Relação: 0012 cobre mapa/dequant/op; 0013 cobre o caminho até tokens ou bloqueio pós-embedding/camada.
