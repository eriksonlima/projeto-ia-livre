# Plan — Prefill completo 22L + KV cache viável na Linha B

## Abordagem

1. **Contrato primeiro (Task 1):** ADR 0014 fixa preferência **22L + KV multi-token**, critério de inviabilidade para subset, marcadores (`PREFILL_22L_OK`, `KV_CACHE_OK`, `PREFILL_LAYERS=`, `KV_BYTES`, `KV_N_POS`), evolução de `B_BLOCK` (`no_gguf_full_prefill` → `no_gguf_decode` no sucesso forte). Atualizar `runtime-nativo-linha-b.md`, ponte harness/comparável, `AGENTS.md`. Medir RAM/tempo baseline QEMU com estado E33.

2. **Generalização por camada (Task 2):** refatorar `attn`/`ffn` para `layer_idx` (nomes `blk.N.*`); unit tests host com GGUF canônico (≥ layers 0 e 1). Introduzir estrutura `KvCache` em `runtime-native` (layout GQA, alloc bump/vec fixo `no_std`); API `kv_write_pos` / leitura na attn; marcador serial opcional `KV_LAYER0_OK` após 2 posições × 1 layer. **Sem** loop 22 ainda; **sem** `TOKENS_PER_S`.

3. **Prefill multi-token × N layers (Task 3):** embed sequencial do prompt canônico; loop externo posição, interno `0..N_LAYER` (meta N=22); atualizar KV a cada posição; emitir checksum/checks por bloco. Preferência: N=22 no guest. Se inviável (critério Task 1): N subset + `PREFILL_PARTIAL_OK` + ADR. Atualizar `try_forward_canonical` / `ForwardError` (ex. `NoDecode` em vez de `NoFullPrefill`). Kernel glue se novos marcadores.

4. **Gates e docs (Task 4):** `verify-boot.sh`, `verify-harness.sh`, `run-harness-line-b.sh`, `run-harness-a-b-comparable.sh` (reason atualizado se 22L ok — ainda `INCONCLUSIVO`); `Makefile` timeouts se necessário. Docs + `tasks.md` + desfecho no `ROADMAP.md`. README se capa enganosa.

Ordem: 1 → 2 → 3 → 4. Uma fatia por vez. Motor na crate; kernel só serial.

## Arquivos prováveis

- `docs/adr/0014-prefill-22l-kv-linha-b.md` (novo)
- `docs/runtime-nativo-linha-b.md`, `docs/desenho-motor-inferencia-linha-b.md`
- `docs/harness-linha-a-b.md`, `docs/harness-a-b-comparavel.md`
- `docs/glossario.md` (`B_BLOCK` evolução se mudar)
- `AGENTS.md`, `README.md` (avaliar)
- `runtime-native/src/attn.rs`, `ffn.rs`, `lib.rs` (+ `kv.rs` se criado)
- `kernel/src/main.rs` (reemissão marcadores — glue fino)
- `scripts/verify-boot.sh`, `scripts/verify-harness.sh`, `scripts/run-harness-line-b.sh`, `scripts/run-harness-a-b-comparable.sh`
- `Makefile` (timeouts opcionais)
- `specs/prefill-22l-kv-linha-b/tasks.md`

## Dependências

- Etapa 33 (attn+FFN layer0, `no_gguf_full_prefill`) — **feita**
- Etapas 26/27/29 (BlockIO + layout) — **feitas**
- Etapas 19/20 (contrato serial; tipado kernel) — **feitas**
- ADR 0013 — fronteira: tokens = B38
- GGUF local + QEMU/OVMF
- **Não** depende de B38/B39, GPU guest, bare-metal, node, agent

## Verificação

Gate base em `AGENTS.md` + checks desta feature:

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

# Após Task 1
test -f docs/adr/0014-prefill-22l-kv-linha-b.md

# Após Task 2
cargo test -p ia-livre-runtime-native
make build

# Após Tasks 3–4 (sucesso 22L preferido)
./scripts/fetch-model.sh
make verify                    # PREFILL_22L_OK + KV_CACHE_OK; B_BLOCK=no_gguf_decode (ou doc)
make verify-harness            # proxy; sem TOKENS_PER_S
make verify-harness-comparable # INCONCLUSIVO; reason ≠ E33_no_gguf_full_prefill se 22L ok

# Subset fallback:
# gates exigem PREFILL_PARTIAL_OK + PREFILL_LAYERS=N + novo B_BLOCK; sem TOKENS_PER_S
```

Proibido em qualquer gate: `TOKENS_PER_S`, `LOAD_KIND=gguf` sem B38.