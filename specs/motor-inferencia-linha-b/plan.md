# Plan — Motor de inferência GGUF mínimo na Linha B

## Abordagem

1. **Contrato primeiro (Task 1):** ADR 0010 fixa a fronteira — crate `no_std`/`freestanding` separada (nome canônico), API mínima pós-ExitBoot, escopo TinyLlama Q4_K_M + prompt + `n-predict=32` CPU, e o critério explícito sucesso (`LOAD_KIND=gguf` + métricas medidas) vs fallback (`B_BLOCK` novo, ex. `no_gguf_forward`). Documentar rejeição de motor-no-`main.rs`, microbench-as-tokens e host-as-B. Atualizar pontes harness/quiet/comparável e `AGENTS.md`.

2. **Infra do motor (Task 2):** criar o membro do workspace; glue mínimo no kernel (chamar a crate após BlockIO + tipados E19); evoluir parse stub → layout/tensores honestos suficientes para um forward. Emitir marcadores intermediários. **Ainda sem** `TOKENS_PER_S` se não houver geração.

3. **Geração ou bloqueio (Task 3):** implementar Prefill/Decode + sampling mínimo no caminho canônico **ou**, se o desenho Task 1 declarar inviável no prazo, fechar com bloqueio novo + evidência intermediária (sem inventar tokens). Preferência: tentar o caminho que desbloqueia tokens.

4. **Instrumentação (Task 4):** se geração — medir `LOAD_S` / `TOKENS_PER_S` no guest; atualizar `run-harness-line-b.sh`, `verify-harness`, comparable e protocolo quieto. Se bloqueio — gates exigem o novo `B_BLOCK` e intermediários; comparable permanece `INCONCLUSIVO`. Alinhar docs ao desfecho real.

Ordem: 1 → 2 → 3 → 4. Uma fatia por vez. Não inventar números em nenhum passo.

## Arquivos prováveis

- `docs/adr/0010-*.md` (novo)
- `docs/desenho-motor-inferencia-linha-b.md` (novo) **e/ou** seção Etapa 29 em `docs/runtime-nativo-linha-b.md`
- `docs/harness-linha-a-b.md`, `docs/harness-a-b-comparavel.md`, `docs/harness-corrida-quieta.md`
- `docs/memoria-scheduler-impl-minima.md` (só se o motor exigir ajuste mínimo de consumo tipado)
- `AGENTS.md`, `README.md` (avaliar)
- `Cargo.toml` (workspace member)
- `runtime-native/` ou `infer-engine/` (crate nova — nome na Task 1)
- `kernel/src/main.rs` (glue mínimo; **não** motor produto)
- `kernel/Cargo.toml` (dependência path da crate)
- `scripts/run-harness-line-b.sh`, `scripts/verify-harness.sh`, `scripts/run-harness-a-b-comparable.sh`, `scripts/verify-harness-comparable.sh`, `scripts/verify-boot.sh` / `Makefile` se timeouts/`-m`
- Spec desta pasta: `tasks.md` marcado por fatia

## Dependências

- Etapas 26/27 (loader BlockIO + stub) — **feitas**
- Etapa 19/20 (contrato tipado + harness contract) — **feitas**
- Etapa 28 (corrida quieta) — **feita**; protocolo permanece
- ADR 0001 (separação camadas) — respeitar
- ADR 0009 (motor fora da E27) — esta etapa **é** o motor
- GGUF canônico local (`./scripts/fetch-model.sh`) + QEMU/OVMF
- **Não** depende de GPU, node, agent, bare-metal USB

## Verificação

Gate base em `AGENTS.md` + checks desta feature:

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

# Após Task 1: ADR + docs existem; decisão A documentada
test -f docs/adr/0010-*.md   # nome exato após Task 1
# + pontes em runtime-nativo / harness*

# Após Tasks 2–4 (caminho geração):
make build
make verify                  # marcadores motor + (se geração) evidência serial
./scripts/fetch-model.sh
make verify-harness          # B com LOAD_KIND=gguf + LOAD_S/TOKENS_PER_S medidos
make verify-harness-comparable

# OU caminho bloqueio novo:
# verify-harness exige B_BLOCK=<novo> + intermediários; sem TOKENS_PER_S; comparable INCONCLUSIVO
```

Checklist anti-fraude (sempre):

- Nenhum `TOKENS_PER_S` / `LOAD_S` / `LOAD_KIND=gguf` sem geração medida no guest
- Motor não está como produto engessado em `kernel/src/main.rs`
- Host `ia-livre-runtime` não conta como evidência de B
