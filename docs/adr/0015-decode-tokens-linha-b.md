# ADR 0015 — Decode + sampling + TOKENS_PER_S na Linha B

- Status: aceita
- Data: 2026-11-21

## Contexto

Etapa 43 entregou Prefill subset (`2L×2` pos) + KV com `B_BLOCK=no_gguf_prefill_22l`. A hipótese A vs B permanece **INCONCLUSIVO** sem `TOKENS_PER_S` medidos em B. Prefill 22L pleno e 2L×16 no QEMU **debug** foram inviáveis (ADR 0014). Esta etapa (44 / B38) cobre Decode + sampling + métricas — **sem** inventar taxa.

## Decisão

1. **Preferência (A):** Decode autoregressivo (`n-predict=32` preferido) + sampling greedy (argmax) no `runtime-native`, com as **N layers** do Prefill/KV guest; `LOAD_KIND=gguf` + `LOAD_S` / `TOKENS_PER_S` **só** com loop real; `RUNTIME_NATIVE_OK` / `DECODE_OK` / `SAMPLING_OK`.
2. **Otimização prévia (Task 2):** build UEFI **release** opt-in (`IA_LIVRE_KERNEL_PROFILE=release` / Makefile) — medir Prefill E43 antes/depois; sem métricas de geração nesta task.
3. **Fallback (B):** se Decode inviável após release + tentativa: Decode mínimo (N&lt;32 e/ou subset layers) **com** métricas reais **ou** `B_BLOCK=no_gguf_decode_perf` (**≠** reutilizar `no_gguf_prefill_22l` se o bloqueio passou a ser Decode/perf).
4. Motor em `runtime-native/`; kernel glue/serial + TSC para wall-clock.
5. **Proibido:** `TOKENS_PER_S` / `LOAD_KIND=gguf` sem ≥1 token gerado no guest; host-as-B.

### Marcadores

| Sucesso | Fallback |
|---------|----------|
| `DECODE_OK`, `SAMPLING_OK`, `N_PREDICT=`, `RUNTIME_NATIVE_OK` | `DECODE_ATTEMPT=1`, `DECODE_FAIL=<reason>` |
| harness: `LOAD_KIND=gguf`, `LOAD_S=`, `TOKENS_PER_S=` | `B_BLOCK=no_gguf_decode_perf` (ou `no_gguf_decode`) |
| `B_BLOCK` omitido | **proibido** `TOKENS_PER_S` |

### Baseline (E43 → E44 Task 1)

| Item | Valor |
|------|--------|
| Prefill guest debug | 2L×2; `make verify` ~210 s (incl. GGUF load) |
| Host release 2L×16 | ~7 s |
| Estimativa logits `output.weight` | ~1–2× custo FFN/token (vocab 32k) |
| Decode 32 tok × 2L (host, ordem de grandeza) | dezenas de segundos — QEMU debug provavelmente inviável; **release** é o primeiro alívio |

## Relação

| ADR | Papel |
|-----|--------|
| 0013 | Fatia até geração |
| 0014 | Prefill/KV subset |
| **0015** | Decode/sampling/métricas; fronteira honestidade |

## Rejeitado

- Inventar `TOKENS_PER_S`; microbench-as-tokens; pular otimização sem registro.

## Consequências

- Gates E44: ou métricas GGUF reais em B, ou `B_BLOCK` novo + comparable reason atualizado.
- Comparable pode permanecer `INCONCLUSIVO` se espécie ≠ A plena — sem forçar `COMPROVA`.
