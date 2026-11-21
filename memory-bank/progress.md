# Progress

## Funciona

- Etapas 1–43 feitas (E43: Prefill multi/KV subset na Linha B)
- `make verify` + `verify-harness` + `verify-harness-comparable` + `verify-docs-consistency`
- Hipótese A vs B: ainda **INCONCLUSIVO** (sem `TOKENS_PER_S` em B)

## Bloqueios / residual

- Prefill 22L pleno e Decode/sampling: backlog **B38** (`no_gguf_prefill_22l`)
- Boot metal real: B40 (E35 skip neste host)

## Roadmap

- Ver `ROADMAP.md` — E43 desfecho; próxima promoção B38
