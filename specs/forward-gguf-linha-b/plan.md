# Plan — Forward GGUF mínimo em runtime-native (TOKENS_PER_S na Linha B)

## Abordagem

1. **Contrato primeiro (Task 1):** ADR 0012 fixa a escolha **B fatiada** — progresso em `runtime-native` (mapa de tensores + dequant Q4_K + op) com preferência forte a tokens canônicos; fallback = `B_BLOCK` novo mais preciso que `no_gguf_forward`. Documentar rejeição de porta-tudo-de-uma-vez como escopo único (A) e de fraude (C). Fixar nomes dos marcadores intermediários e o critério de “inviável”. Atualizar pontes harness/quiet/comparável e `AGENTS.md`.

2. **Fundação do forward (Task 2):** em `runtime-native/`, evoluir além de `LayoutReport` contagens — índice de tensores **nomeados** (nome → tipo/dims/offset no buffer GGUF) e **dequant Q4_K** de pelo menos um tensor do modelo canônico. Unit test no host (GGUF local) +/ou marcador serial. **Ainda sem** `TOKENS_PER_S`.

3. **Op / geração ou bloqueio (Task 3):** preferência — estender `try_forward_canonical` para Prefill+Decode+sampling mínimos (prompt canônico, `n-predict=32`) e emitir `RUNTIME_NATIVE_OK` + métricas medidas. Se inviável após Task 1–2: entregar ≥1 op honesto (matmul / embedding / camada parcial) + marcadores + `B_BLOCK=<novo>`. Nunca inventar tokens. Glue de kernel mínimo (serial) se necessário.

4. **Instrumentação (Task 4):** se geração — atualizar `run-harness-line-b.sh`, `verify-harness`, comparable/quiet para `LOAD_KIND=gguf` + `LOAD_S`/`TOKENS_PER_S` + `N_PREDICT=32`. Se bloqueio — gates exigem intermediários + novo `B_BLOCK`; comparable `INCONCLUSIVO`. Alinhar docs ao desfecho real.

Ordem: 1 → 2 → 3 → 4. Uma fatia por vez. Não inventar números em nenhum passo. Preferir implementação na crate; kernel só orquestra.

## Arquivos prováveis

- `docs/adr/0012-*.md` (novo)
- `docs/desenho-motor-inferencia-linha-b.md` (atualizar Etapa 31)
- `docs/runtime-nativo-linha-b.md` (estado pós-E29 → E31)
- `docs/harness-linha-a-b.md`, `docs/harness-a-b-comparavel.md`, `docs/harness-corrida-quieta.md`
- `AGENTS.md`, `README.md` (avaliar)
- `runtime-native/src/lib.rs` (+ módulos `tensor_map`, `q4k`, `forward` se fatiar arquivos)
- `runtime-native/Cargo.toml` (só se deps `no_std` mínimas)
- `kernel/src/main.rs` (glue/serial fino; **não** motor produto)
- `scripts/run-harness-line-b.sh`, `scripts/verify-harness.sh`, `scripts/run-harness-a-b-comparable.sh`, `scripts/verify-harness-comparable.sh`, `scripts/verify-boot.sh` / `Makefile` (timeouts)
- Spec desta pasta: `tasks.md` marcado por fatia

## Dependências

- Etapa 29 (crate + layout + `no_gguf_forward`) — **feita**
- Etapas 26/27 (BlockIO full) — **feitas**
- Etapas 19/20 (contrato tipado + harness contract) — **feitas**
- ADR 0001 / 0010 — respeitar
- GGUF canônico local (`./scripts/fetch-model.sh`) + QEMU/OVMF
- **Não** depende de GPU, node, agent, bare-metal USB, mudança na Linha A

## Verificação

Gate base em `AGENTS.md` + checks desta feature:

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

# Após Task 1: ADR 0012 + docs de decisão B
test -f docs/adr/0012-*.md   # nome exato após Task 1

# Após Task 2: unit tests / marcadores de mapa + dequant
cargo test -p ia-livre-runtime-native
make build

# Após Tasks 3–4 (caminho geração):
make verify
./scripts/fetch-model.sh
make verify-harness          # B: LOAD_KIND=gguf + LOAD_S/TOKENS_PER_S + RUNTIME_NATIVE_OK
make verify-harness-comparable

# OU caminho bloqueio novo:
# verify-harness exige intermediários + B_BLOCK=<novo> ≠ no_gguf_forward (se natureza mudou);
# sem TOKENS_PER_S; comparable INCONCLUSIVO
```

Checklist anti-fraude (sempre):

- Nenhum `TOKENS_PER_S` / `LOAD_S` / `LOAD_KIND=gguf` sem geração medida no guest
- Forward não está como produto engessado em `kernel/src/main.rs`
- Host `ia-livre-runtime` não conta como evidência de B
- Fallback sem mapa+dequant+op **não** fecha a etapa
