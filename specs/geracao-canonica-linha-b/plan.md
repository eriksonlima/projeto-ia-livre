# Plan — Geração canônica Prefill+Decode+sampling na Linha B (TOKENS_PER_S)

## Abordagem

1. **Contrato primeiro (Task 1):** ADR 0013 fixa a escolha **B fatiada** — progresso em `runtime-native` (tokenize mínimo + embedding `token_embd` + ≥1 camada parcial) com preferência forte a Prefill+Decode+sampling canônicos; fallback = `B_BLOCK` novo mais preciso que `no_gguf_generate`. Documentar rejeição de porta-tudo-de-uma-vez como escopo único (A) e de fraude (C). Fixar nomes dos marcadores intermediários e o critério de “inviável”. Atualizar pontes harness/quiet/comparável e `AGENTS.md`.

2. **Tokenize + embedding (Task 2):** em `runtime-native/`, prompt canônico → ids mínimos; lookup no tensor `token_embd` (Q4_K) com evidência (unit test no host com GGUF local e/ou marcador serial). Reutilizar `find_tensor` / dequant E31. **Ainda sem** `TOKENS_PER_S`.

3. **Camada / geração ou bloqueio (Task 3):** preferência — uma camada parcial (attn **ou** FFN) e, se viável, loop Prefill+Decode+sampling (`n-predict=32`) emitindo `RUNTIME_NATIVE_OK` + métricas medidas. Se inviável após Task 1–2 + camada: `B_BLOCK=<novo>` (ex. `no_gguf_transformer` / `no_gguf_decode`) **≠** `no_gguf_generate`. Nunca inventar tokens. Glue de kernel mínimo (serial) se necessário.

4. **Instrumentação (Task 4):** se geração — atualizar `run-harness-line-b.sh`, `verify-harness`, comparable/quiet para `LOAD_KIND=gguf` + `LOAD_S`/`TOKENS_PER_S` + `N_PREDICT=32` + `RUNTIME_NATIVE_OK`. Se bloqueio — gates exigem intermediários (tokenize/embed/camada) + novo `B_BLOCK`; comparable `INCONCLUSIVO`. Alinhar docs ao desfecho real.

Ordem: 1 → 2 → 3 → 4. Uma fatia por vez. Não inventar números em nenhum passo. Preferir implementação na crate; kernel só orquestra.

## Arquivos prováveis

- `docs/adr/0013-*.md` (novo)
- `docs/desenho-motor-inferencia-linha-b.md` (atualizar Etapa 32)
- `docs/runtime-nativo-linha-b.md` (estado pós-E31 → E32)
- `docs/harness-linha-a-b.md`, `docs/harness-a-b-comparavel.md`, `docs/harness-corrida-quieta.md`
- `AGENTS.md`, `README.md` (avaliar)
- `runtime-native/src/lib.rs` (+ módulos `tokenize`, `embed`, `layer` / `generate` se fatiar arquivos)
- `runtime-native/Cargo.toml` (só se deps `no_std` mínimas)
- `kernel/src/main.rs` (glue/serial fino; **não** motor produto)
- `scripts/run-harness-line-b.sh`, `scripts/verify-harness.sh`, `scripts/run-harness-a-b-comparable.sh`, `scripts/verify-harness-comparable.sh`, `scripts/verify-boot.sh` / `Makefile` (timeouts)
- Spec desta pasta: `tasks.md` marcado por fatia

## Dependências

- Etapa 31 (mapa + dequant Q4_K + op; `no_gguf_generate`) — **feita**
- Etapas 26/27/29 (BlockIO full + crate + layout) — **feitas**
- Etapas 19/20 (contrato tipado + harness contract) — **feitas**
- ADR 0001 / 0010 / 0012 — respeitar
- GGUF canônico local (`./scripts/fetch-model.sh`) + QEMU/OVMF
- **Não** depende de GPU, node, agent, bare-metal USB, mudança na Linha A

## Verificação

Gate base em `AGENTS.md` + checks desta feature:

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

# Após Task 1: ADR 0013 + docs de decisão B
test -f docs/adr/0013-*.md   # nome exato após Task 1

# Após Task 2: unit tests / marcadores tokenize + embed
cargo test -p ia-livre-runtime-native
make build

# Após Tasks 3–4 (caminho geração):
make verify
./scripts/fetch-model.sh
make verify-harness          # B: LOAD_KIND=gguf + LOAD_S/TOKENS_PER_S + RUNTIME_NATIVE_OK
make verify-harness-comparable

# OU caminho bloqueio novo:
# verify-harness exige tokenize/embed/camada + B_BLOCK=<novo> ≠ no_gguf_generate;
# sem TOKENS_PER_S; comparable INCONCLUSIVO
```

Checklist anti-fraude (sempre):

- Nenhum `TOKENS_PER_S` / `LOAD_S` / `LOAD_KIND=gguf` sem geração medida no guest
- Geração não está como produto engessado em `kernel/src/main.rs`
- Host `ia-livre-runtime` não conta como evidência de B
- Fallback sem embedding+camada **não** fecha a etapa
- Não reutilizar `no_gguf_generate` após avanço real
