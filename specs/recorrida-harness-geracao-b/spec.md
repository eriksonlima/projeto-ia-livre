# Spec — Re-corrida harness A vs B com geração real em B (Etapa 33)

## Resultado visível

**Caminho preferido (tokens reais):** Prefill completo + loop Decode N=32 + sampling mínimo (argmax)
em `runtime-native/` no guest QEMU → `RUNTIME_NATIVE_OK` + `LOAD_KIND=gguf` + `LOAD_S` / `TOKENS_PER_S`
**medidos** + re-corrida harness comparable quieta com `COMPROVA`, `REFUTA` **ou** `INCONCLUSIVO`
baseado em métricas honestas (checklist A/B comparável satisfeito).

**Caminho de fallback (bloqueio novo honesto):** Avanço real além de `no_gguf_decode` — atenção
completa 1 camada + FFN verificáveis — com `B_BLOCK` **novo e mais preciso** (ex. `no_gguf_full_attn`,
`no_gguf_ffn`, `no_gguf_sampling`) ≠ `no_gguf_decode`; re-corrida com `INCONCLUSIVO` cujo
`VERDICT_REASON` **não** é "ausência de tokens em B" (ex.: `KV_cache_RAM_insuficiente`,
`decode_loop_timeout`, `softmax_sem_float`).

> **Pronto quando do ROADMAP:** `verify-harness-comparable` quieto com `COMPROVA`/`REFUTA`
> **ou** `INCONCLUSIVO` só com motivo ≠ ausência de tokens B.
> Pure `B_BLOCK=no_gguf_decode` **não** fecha a etapa — é o estado de entrada.

## Contexto fixo (não reinventar)

- **E32 desfecho:** `B_BLOCK=no_gguf_decode`; `TOKENIZE_OK` + `EMBED_OK` + `LAYER_PARTIAL_OK`
  (`blk.0.attn_output.weight` matvec parcial, 8 saídas); **sem** Prefill/Decode/sampling → **sem**
  `TOKENS_PER_S`.
- **`runtime-native/src/lib.rs` atual:**
  - `CANONICAL_PROMPT_TOKEN_IDS` (ids fixos BOS+prompt, capturados via llama.cpp)
  - `TOKEN_EMBD_NAME` / `ATTN_OUT_NAME` (blk.0.attn_output.weight)
  - `ForwardError::NoDecode` (bloqueio E32)
  - Embedding lookup e matvec parcial `attn_output` operacional
- **Harness comparável atual:**
  - `VERDICT=INCONCLUSIVO`; `VERDICT_REASON=B_proxy_sem_TOKENS_PER_S_E32_no_gguf_decode`
- **ADR 0013:** geração canônica fatiada; relação 0001/0010/0012; critério inviável após
  tokenize+embed+camada parcial.
- **Infra QEMU:** `-m 1536M`; disco raw `build/gguf-canon.gguf`; ADR 0001 (motor fora do kernel).
- **Referência Linha A:** `runtime/` + llama-cpp-2; prompt canônico; `n-predict=32`; CPU.
- **Nomenclatura:** Projeto IA Livre / IA Livre / Rede IA Livre.
- **Rule `readme-por-fatia`:** cada fatia avalia `README.md`.

## Avaliação de alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A — porta completa de uma vez** | Todas as 22 camadas + KV + sampling num único PR | **Rejeitada como escopo único** — alto risco de zero avanço verificável; E32 já provou inviabilidade |
| **B — fatiamento vertical de ops** | Atenção completa 1 camada (QKV+softmax+o_proj) → FFN SwiGLU 1 camada → Prefill N camadas + loop Decode + argmax | **Escolhida** |
| **C — fraude / atalho** | Inventar `TOKENS_PER_S`; host-as-B; microbench-as-tokens; reutilizar `no_gguf_decode` sem avanço | **Rejeitada** — fraude de espécie/ambiente |

## Decisão de desenho — Opção B

### Arquitetura TinyLlama 1.1B (referência — não mudar)

| Parâmetro | Valor |
|-----------|-------|
| Dimensão de embedding (`n_embd`) | 2048 |
| Dimensão intermediária FFN (`n_ff`) | 5632 |
| Cabeças de atenção (`n_heads`) | 32 |
| Cabeças KV (`n_kv_heads`) | 4 — GQA (Grouped Query Attention) |
| Número de camadas | 22 |
| Vocab | ~32 000 |
| Quantização dos pesos | Q4_K_M |

Tensores por bloco (nome GGUF canônico):

| Tensor | Tipo | Shape |
|--------|------|-------|
| `blk.N.attn_norm.weight` | F32 | [2048] |
| `blk.N.attn_q.weight` | Q4_K | [2048, 2048] |
| `blk.N.attn_k.weight` | Q4_K | [256, 2048] — GQA |
| `blk.N.attn_v.weight` | Q4_K | [256, 2048] — GQA |
| `blk.N.attn_output.weight` | Q4_K | [2048, 2048] ← já parcial |
| `blk.N.ffn_norm.weight` | F32 | [2048] |
| `blk.N.ffn_gate.weight` | Q4_K | [5632, 2048] — SwiGLU gate |
| `blk.N.ffn_up.weight` | Q4_K | [5632, 2048] — SwiGLU up |
| `blk.N.ffn_down.weight` | Q4_K | [2048, 5632] — proj de volta |
| `output_norm.weight` | F32 | [2048] |
| `output.weight` | Q4_K ou F16 | [32000, 2048] — cabeça LM |

### Peças a implementar (em `runtime-native/`)

| Peça | Escopo na etapa |
|------|----------------|
| **RMSNorm** | Normalização em F32 (pesos F32 já no GGUF) |
| **QKV projection** | Dequant Q4_K + matvec; GQA (repetir KV para heads de Q) |
| **Softmax mínimo** | Escalar (sem float nativo no guest → aproximação honesta: f32 fixo ou fallback simples; documentar) |
| **Multi-head attention** | Q·K^T / √d_k + softmax + ·V + o_proj |
| **Residual** | Soma vetorial elementar |
| **FFN SwiGLU** | gate_proj×SiLU×up_proj + down_proj; dequant Q4_K |
| **Loop Prefill** | Iterar sobre N_LAYER camadas com token corrente |
| **Loop Decode** | Autoregressive N=32 tokens; KV cache mínimo (1 head × 1 layer com RAM disponível, ou KV fixo documentado) |
| **Sampling** | Argmax sobre logits da cabeça LM (output.weight × hidden + output_norm) |
| **Métricas** | TSC-based (`rdtsc`) para `LOAD_S` / `TOKENS_PER_S`; já usado no proxy E12 |

### Critério de fallback honesto (quando fallback é permitido)

Só após evidência **verificável** de:
1. RMSNorm + atenção completa 1 camada (QKV+softmax+o_proj+residual) — `ATTN_LAYER_OK`
2. FFN SwiGLU 1 camada completa — `FFN_LAYER_OK`

Exemplos de bloqueio novo **honesto** (≠ `no_gguf_decode`):

- `no_gguf_kv_cache` — sem RAM suficiente para KV cache 22 camadas × 32 heads × 2048 (> 1,5 GB QEMU)
- `no_gguf_softmax` — sem `f32::exp` / `libm` em `no_std` e aproximação insegura para argmax
- `no_gguf_full_prefill` — Prefill loop inviável no tempo/QEMU após attn+FFN 1 camada verificados
- `no_gguf_sampling` — argmax necessário mas output.weight inacessível (tipo ou offset inválido)

**Não** é bloqueio honesto: fechar sem (1)+(2) verificados, ou renomear `no_gguf_decode` sem avanço.

### Marcadores novos (kernel/serial + harness)

| Marcador | Quando |
|----------|--------|
| `IA_LIVRE_RUNTIME_NATIVE_ATTN_LAYER_OK` | Atenção completa ≥1 camada verificada |
| `IA_LIVRE_RUNTIME_NATIVE_FFN_LAYER_OK` | FFN SwiGLU ≥1 camada verificada |
| `IA_LIVRE_RUNTIME_NATIVE_PREFILL_OK` | Prefill N_PROMPT tokens completo (N camadas) |
| `IA_LIVRE_RUNTIME_NATIVE_DECODE_OK` | ≥1 token decodificado (loop autoregressivo) |
| `IA_LIVRE_RUNTIME_NATIVE_OK` | Geração mínima completa (`n-predict=32` ou N documentado) |
| `IA_LIVRE_RUNTIME_NATIVE_TOKENS_OK=N` | N tokens gerados (medidos) |
| `IA_LIVRE_RUNTIME_NATIVE_FORWARD_FAIL=<motivo>` | Motivo residual se bloqueio novo |

Preservados de E32: `TOKENIZE_OK`, `EMBED_OK`, `LAYER_PARTIAL_OK`, `TENSOR_MAP_OK`,
`Q4K_DEQUANT_OK`, `FORWARD_OP_OK` (loader E26/E27 + mapa E29 + intermediários E32).

## Fora de escopo

- GPU nativa no guest (CUDA/Vulkan/ROCm)
- Bare-metal/USB (Etapa 30)
- KV cache multi-sequência ou multi-tenant
- Todas as 22 camadas em modo otimizado (loop simples de 22 é ok; SIMD/AVX não exigido)
- Alterar Linha A, carga canônica A, llama-cpp-2 no host
- `node/` / `agent/` / protocolo P2P
- Inventar `TOKENS_PER_S` sem geração medida no guest
- Forçar `COMPROVA`/`REFUTA` sem checklist comparável satisfeito
- Port de llama.cpp completo em `kernel/src/main.rs`

## Critérios de aceite

- [ ] **Atenção completa ≥1 camada** verificável em `runtime-native/`: RMSNorm + QKV (Q4_K) + softmax + o_proj + residual → `ATTN_LAYER_OK` (serial ou unit test host)
- [ ] **FFN SwiGLU ≥1 camada** verificável: gate_proj + SiLU + up_proj + down_proj (dequant Q4_K) → `FFN_LAYER_OK`
- [ ] **Ou** (preferência): Prefill N camadas + loop Decode N=32 + argmax → `RUNTIME_NATIVE_OK` + `LOAD_KIND=gguf` + `LOAD_S`/`TOKENS_PER_S` medidos + `N_PREDICT=32`; **ou** `B_BLOCK` novo (≠ `no_gguf_decode`) com motivo técnico concreto ≠ "ausência de tokens"
- [ ] Harness B + comparable atualizados: `VERDICT_REASON` ≠ `E32_no_gguf_decode`; sem tokens inventados
- [ ] Re-corrida quieta (`harness-corrida-quieta.md`): `VERDICT` ∈ {COMPROVA, REFUTA, INCONCLUSIVO}; se INCONCLUSIVO → motivo ≠ ausência de tokens B
- [ ] ADR 0001/0010/0012/0013 respeitados (motor em `runtime-native/`; glue/serial no kernel; fatia vertical)
- [ ] Hipótese só sai de INCONCLUSIVO com métricas reais de espécie (nunca proxy convertido)
- [ ] `AGENTS.md` cobre o estado novo; `docs/runtime-nativo-linha-b.md` / `docs/harness-a-b-comparavel.md` atualizados; README avaliado

## Riscos e rollback

- **Risco alto:** KV cache completo (22 camadas × 32 heads × seq_len × 256 B) > 1 GB → excede `-m 1536M`.
  Mitigação: KV cache de 1 camada ou N fixo documentado; se inviável → `B_BLOCK=no_gguf_kv_cache`.
- **Risco:** softmax em `no_std` sem `libm` → usar approximação honesta (`f32` fixo compilado) **ou**
  argmax direto sobre logits não normalizados (documentar limitação); se instável → `B_BLOCK=no_gguf_softmax`.
- **Risco:** Prefill 22 camadas + 32 tokens decode > timeout 300s em QEMU emulado sem SIMD.
  Mitigação: aumentar `VERIFY_HARNESS_TIMEOUT` + documentar; ou N_LAYER_PARTIAL com medição parcial real
  se loop completo inviável.
- **Risco:** pressão por COMPROVA → regra dura; attn+FFN parciais não substituem tokens reais.
- **Rollback:** se decode loop falhar após attn+FFN verificados → restaurar `B_BLOCK` mais específico;
  intermediários `ATTN_LAYER_OK` / `FFN_LAYER_OK` permanecem no gate.

## Etapa do roadmap

- Etapa **33** — Re-corrida harness A vs B com geração real em B (`em_andamento`)
- Issue: [#32](https://github.com/eriksonlima/projeto-ia-livre/issues/32)
- Spec: `specs/recorrida-harness-geracao-b/`
- Pronto quando: `verify-harness-comparable` quieto com `COMPROVA`/`REFUTA` **ou** `INCONCLUSIVO`
  só com motivo ≠ ausência de tokens B; depende de geração real em B (além de `no_gguf_decode`)
  **ou** bloqueio honesto documentado se tokens ainda inviáveis sem fraude.
