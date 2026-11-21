# Plan — Re-corrida harness A vs B com geração real em B (Etapa 33)

## Abordagem

Fatia vertical em `runtime-native/` seguindo ADR 0010/0012/0013:

1. **Task 1 — Atenção completa 1 camada + RMSNorm**
   - Adicionar `forward_attn_layer`: RMSNorm (pesos F32) + dequant Q4_K de `attn_q/k/v/output` +
     matvec QKV + GQA (repetir K/V para os grupos de Q) + produto Q·K^T / √d_k + softmax mínimo
     (argmax-safe) + produto ·V + o_proj + residual.
   - `F32` nativo para operações de ativação (Rust `f32` compila em `no_std` sem `libm` para operações
     básicas; `exp` precisa de aproximação ou `compiler-builtins` — avaliar e documentar).
   - Marcador serial: `IA_LIVRE_RUNTIME_NATIVE_ATTN_LAYER_OK`.

2. **Task 2 — FFN SwiGLU 1 camada + loop Prefill multi-camada**
   - Adicionar `forward_ffn_layer`: RMSNorm FFN + dequant Q4_K de `ffn_gate/up/down` + matvec
     gate_proj + SiLU (aproximação `x * sigmoid(x)`) + up_proj × gate + down_proj + residual.
   - Marcador serial: `IA_LIVRE_RUNTIME_NATIVE_FFN_LAYER_OK`.
   - Loop Prefill: iterar `0..N_LAYER` chamando `forward_attn_layer` + `forward_ffn_layer` com
     token de entrada; KV cache plano (1 buffer por layer com capacidade `MAX_SEQ_LEN` fixo e
     documentado — ajustar se RAM insuficiente).
   - Marcador serial: `IA_LIVRE_RUNTIME_NATIVE_PREFILL_OK` **ou** `B_BLOCK` novo se inviável.

3. **Task 3 — Loop Decode + sampling argmax + métricas**
   - Autoregressive decode: para `i in 0..N_PREDICT`, re-rodar Prefill do token previsto +
     projeção `output_norm` + `output.weight` → logits → argmax → token próximo.
   - `rdtsc` para medir `LOAD_S` (Prefill) e `TOKENS_PER_S` (tokens/s decode).
   - Marcadores: `DECODE_OK`, `RUNTIME_NATIVE_OK`, `TOKENS_OK=N`.
   - Harness B: se geração ok → `LOAD_KIND=gguf`; se bloqueio → `B_BLOCK=<novo>`.
   - Atualizar `run-harness-line-b.sh` + `run-harness-a-b-comparable.sh`.

4. **Task 4 — Re-corrida quieta + docs finais**
   - Protocolo `harness-corrida-quieta.md` (host quieto, sem QEMU concorrente).
   - `make verify-harness-comparable` → `VERDICT` ≠ reason `E32_no_gguf_decode`.
   - Atualizar `docs/runtime-nativo-linha-b.md` (seção E33), `docs/harness-a-b-comparavel.md`,
     `docs/harness-corrida-quieta.md` (registro de evidência), `AGENTS.md`.
   - `README.md`: avaliar; atualizar se superfície pública mudou.

## Arquivos prováveis

### Código de produto
- `runtime-native/src/lib.rs` — principal: adicionar RMSNorm, forward_attn_layer, forward_ffn_layer, loop Prefill/Decode, sampling argmax
- `runtime-native/src/main.rs` (se existir) — entrypoint UEFI; glue serial; marcadores novos
- `kernel/src/main.rs` — apenas marcadores de reemissão se necessário (glue fino)

### Scripts do harness
- `scripts/run-harness-line-b.sh` — atualizar para emitir `LOAD_KIND=gguf` + métricas se geração ok, ou `B_BLOCK` novo
- `scripts/run-harness-a-b-comparable.sh` — atualizar `VERDICT_REASON` baseline (≠ `E32_no_gguf_decode`)
- `scripts/verify-harness.sh` — atualizar gate B: exigir novos marcadores (`ATTN_LAYER_OK`, `FFN_LAYER_OK`) além dos existentes
- `scripts/verify-harness-comparable.sh` — atualizar aceitar `COMPROVA`/`REFUTA` com métricas reais; manter `INCONCLUSIVO` honesto

### Documentação
- `docs/runtime-nativo-linha-b.md` — seção "Estado atual (após Etapa 33)"
- `docs/harness-a-b-comparavel.md` — seção "Estado atual" e tabela de veredito
- `docs/harness-corrida-quieta.md` — seção "Evidência — re-corrida quieta (Etapa 33)"
- `AGENTS.md` — atualizar marcadores E33, `B_BLOCK` corrente, gates harness
- `README.md` — avaliar; atualizar se entrypoint/gate visível mudou

## Dependências

- **E32 verificada:** `TOKENIZE_OK` + `EMBED_OK` + `LAYER_PARTIAL_OK` + `B_BLOCK=no_gguf_decode`
- **ADR 0001:** motor em `runtime-native/`; kernel só glue/serial
- **ADR 0010/0012/0013:** layout GGUF + fatia vertical + critério inviável após intermediários
- **Infra QEMU:** `-m 1536M`, disco raw `build/gguf-canon.gguf`; BlockIO funcional (E26/E27)
- **Rust `no_std` + `f32`:** operações básicas disponíveis; `exp`/`ln` via `compiler-builtins` ou
  aproximação; documentar se precisar de crate adicional (`libm` feature)

## Notas técnicas de implementação

### RMSNorm
```
rms_norm(x, w) = x / sqrt(mean(x²) + ε) × w
```
Sem `sqrt` nativo em `no_std` → usar `f32::sqrt()` (disponível via `core::f32` intrínseco).

### GQA (Grouped Query Attention)
TinyLlama: `n_heads=32`, `n_kv_heads=4` → `n_groups=8`. Para cada group de 8 heads de Q,
compartilhar 1 head de K e 1 head de V. Dimensão por head: `n_embd / n_heads = 64`.

### KV cache
Capacidade mínima viável: `seq_len × n_kv_heads × head_dim` por camada.
Para 32 tokens + 22 layers + 4 KV heads + head_dim=64: `32 × 4 × 64 × 2 × 22 × 4 bytes ≈ 7 MB` —
viável em 1536M. Se buffer estático não couber → documentar e usar `B_BLOCK=no_gguf_kv_cache`.

### Softmax
`f32::exp` não está em `core` mas em `std`/`libm`. Alternativas honestas:
- Feature `libm` do Cargo para `compiler-builtins-fallback`
- Implementação manual via série de Taylor (documentar erro máximo)
- Argmax direto sobre logits sem softmax para sampling (válido para greedy/argmax)
- **Preferência:** argmax sobre Q·K^T sem softmax normalizado para greedy decode (documenta desvio)

### Timeout QEMU
Prefill 22 camadas × (matvec 2048×2048 + 2×5632×2048) em QEMU emulado ≈ lento sem SIMD.
Estimar antes de confirmar `n-predict=32`; se > 300s → aumentar `VERIFY_HARNESS_TIMEOUT` e
documentar; ou aceitar N_TOKENS < 32 se medido e documentado (≠ inventar taxa).

## Verificação

Comandos do gate em `AGENTS.md` + checks específicos desta feature:

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

# 1. Build runtime-native (host compile-check; no_std)
cargo build -p ia-livre-runtime-native 2>&1 | grep -v warning

# 2. Gate harness principal (A + B)
./scripts/fetch-model.sh
make verify-harness

# 3. Re-corrida quieta (gate E33)
make verify-harness-comparable

# Verificações adicionais pós-task
grep -q 'IA_LIVRE_RUNTIME_NATIVE_ATTN_LAYER_OK' runtime-native/src/lib.rs
grep -q 'IA_LIVRE_RUNTIME_NATIVE_FFN_LAYER_OK' runtime-native/src/lib.rs
grep -q 'VERDICT_REASON' scripts/run-harness-a-b-comparable.sh
# Deve NÃO conter E32_no_gguf_decode como reason final:
! grep -q 'E32_no_gguf_decode' <(make verify-harness-comparable 2>&1) || true
```

Gate final: `make verify-harness-comparable` exit 0 com `VERDICT` ∈ {COMPROVA, REFUTA, INCONCLUSIVO}
e `VERDICT_REASON` ≠ motivo de ausência de tokens (ex. ≠ `E32_no_gguf_decode`, ≠ `sem_TOKENS_PER_S`).
