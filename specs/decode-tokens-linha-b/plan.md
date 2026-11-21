# Plan — Decode + sampling + TOKENS_PER_S canônico na Linha B

## Abordagem

1. **Contrato primeiro (Task 1):** ADR **0015** fixa preferência Decode canônico N=32 + sampling + `LOAD_KIND=gguf` + `TOKENS_PER_S` medidos; caminho realista com Prefill subset 2L (otimizar → Decode mínimo → ou `B_BLOCK` novo); marcadores (`DECODE_OK`, `SAMPLING_OK`, `N_PREDICT`, `RUNTIME_NATIVE_OK`); critério inviável; relação ADR 0013/0014. Atualizar `runtime-nativo-linha-b.md`, pontes harness/comparável, `AGENTS.md`. Baseline: tempo Prefill E43 + estimativa 1 token Decode no host.

2. **Otimização guest (Task 2):** tornar Decode tentável no QEMU — candidatos: build **release** UEFI (opt-in/`Makefile` documentado), reduzir custo matvec/dequant, alinhar `PREFILL_LAYERS`/`KV_N_POS` ao mínimo necessário para Decode. Medir antes/depois (host e/ou QEMU). **Sem** emitir `TOKENS_PER_S` ainda; **sem** fingir geração.

3. **Decode + sampling (Task 3):** em `runtime-native/`: logits (`output.weight` / caminho mínimo), sampling (greedy/argmax), loop Decode autoregressivo atualizando KV; preferência N=32 com layers disponíveis; unit tests host; glue serial no kernel. Sucesso → métricas guest. Inviável → Decode 1–N documentado **ou** `B_BLOCK` novo + `DECODE_FAIL` — **nunca** inventar taxa.

4. **Gates e docs (Task 4):** `verify-boot` / `verify-harness` / `run-harness-line-b` / comparable: se tokens → exigir `LOAD_KIND=gguf` + `TOKENS_PER_S` + marcadores Decode/sampling, omitir `B_BLOCK` antigo; se fallback → novo `B_BLOCK` + reason E44, rejeitar métricas inventadas. Docs + `ROADMAP` desfecho. README avaliar (`readme-por-fatia`).

Ordem: 1 → 2 → 3 → 4. Uma fatia por vez. Motor na crate; kernel só serial.

## Arquivos prováveis

- `docs/adr/0015-decode-tokens-linha-b.md` (novo; nome final na Task 1)
- `docs/runtime-nativo-linha-b.md`, `docs/desenho-motor-inferencia-linha-b.md`
- `docs/harness-linha-a-b.md`, `docs/harness-a-b-comparavel.md`
- `docs/glossario.md` (`B_BLOCK` / `TOKENS_PER_S` B se mudar)
- `AGENTS.md`, `README.md` (avaliar)
- `runtime-native/src/` (`lib.rs`, attn/ffn/kv, novo `decode`/`sample`/`logits` conforme necessário)
- `kernel/src/main.rs` (reemissão marcadores — glue fino)
- `scripts/verify-boot.sh`, `scripts/verify-harness.sh`, `scripts/run-harness-line-b.sh`, `scripts/run-harness-a-b-comparable.sh`
- `Makefile` (release UEFI / timeouts)
- `specs/decode-tokens-linha-b/tasks.md`

## Dependências

- Etapa 43 (Prefill subset + KV) — **feita**
- Etapas 26/27/29/31–33 (loader, layout, forward parcial, attn/FFN) — **feitas**
- ADR 0013 / 0014 — fronteira Decode = esta etapa
- GGUF local + QEMU/OVMF
- **Não** depende de bare-metal, GPU guest, node, agent

## Verificação

Gate base em `AGENTS.md` + checks desta feature:

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

# Após Task 1
test -f docs/adr/0015-decode-tokens-linha-b.md   # ou nome escolhido na fatia

# Após Task 2
make build   # e/ou build release documentado
# evidência de medição registrada em docs/ADR

# Após Tasks 3–4 — sucesso com tokens (preferido)
./scripts/fetch-model.sh
make verify
make verify-harness            # LOAD_KIND=gguf + TOKENS_PER_S + DECODE/SAMPLING
make verify-harness-comparable # veredito honesto com métricas B

# Fallback sem tokens:
# gates exigem B_BLOCK novo + tentativa Decode; SEM TOKENS_PER_S / SEM LOAD_KIND=gguf
```

Proibido em qualquer caminho: inventar `TOKENS_PER_S` sem loop Decode real no guest.
