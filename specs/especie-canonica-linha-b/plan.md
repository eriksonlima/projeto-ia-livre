# Plan — Espécie canônica Linha B (22L × n_predict=32)

## Abordagem

1. **Decisão + contrato (Task 1):** com ADR [`0020`](../../docs/adr/0020-runtime-native-passo-intermediario-inviavel.md) em mãos, documentar se existe **caminho novo** realista nesta fatia (SIMD guest / GPU guest / outro) ou se o desfecho é **B** (inviável canônico). Contrato E60 em `docs/` (extensão de `runtime-native-perf-especie.md` **ou** doc curto dedicado, ex. `docs/especie-canonica-linha-b.md`) + ponte 0016/0020/comparable + reserva ADR **0021**. **Sem** expandir espécie no guest ainda. **Sem** editar hot path “só mais 10%” fingindo caminho novo.

2. **Desfecho A ou B (Task 2):**
   - **Se A (improvável sem caminho novo):** implementar o caminho novo → guest 22L×32 com métricas medidas → `verify-harness-comparable` sem reason teto/subset; veredito por margem R.
   - **Se B (esperado):** emitir ADR **0021** (espécie canônica inviável no gate atual); atualizar `harness-a-b-comparavel.md` / glossário / `runtime-native-perf-especie.md`; ponte explícita **B58**; `AGENTS.md` se gate/doc novo; comparable **permanece** INCONCLUSIVO + reason de teto; **proibido** COMPROVA. README avaliar (`readme-por-fatia`).

3. **Alinhamento gate/docs (Task 3, só se Task 2 deixar lacuna):** garantir greps/`Makefile`/`AGENTS.md` coerentes com o desfecho (presença ADR 0021 **ou** marcadores canônicos em B); `make verify-harness-comparable` continua honesto (aceita INCONCLUSIVO/teto no caminho B). Se Task 2 já fechar docs+ADR+AGENTS, Task 3 pode ser no-op documentado na fatia.

Ordem: 1 → 2 → (3 se necessário). Uma fatia por vez. Preferir **poucas tasks curtas**; não reabrir otimização E59 sem técnica nova.

## Arquivos prováveis

- `docs/especie-canonica-linha-b.md` e/ou extensão de `docs/runtime-native-perf-especie.md` (contrato E60)
- `docs/adr/0021-*.md` (**se** desfecho B; nome final na Task 2)
- `docs/adr/0020-*.md`, `docs/adr/0016-*.md` (ponte; sem reescrever decisão E59)
- `docs/harness-a-b-comparavel.md`, `docs/glossario.md`, `docs/runtime-nativo-linha-b.md`
- `docs/prototipo-objetivo-atingido.md` (ponte B58 / pilar 1 — só menção se necessário)
- `AGENTS.md`, `Makefile`, `README.md` (avaliar)
- **Só se A:** `runtime-native/src/`, `kernel/src/main.rs`, `scripts/run-harness-line-b.sh`, `scripts/run-harness-a-b-comparable.sh`, `scripts/verify-harness-comparable.sh`
- `specs/especie-canonica-linha-b/tasks.md`

## Dependências

- Etapas 44/45/59 + ADR 0016/0020 — **feitas**
- GGUF + QEMU só se tentar A
- **Não** depende de METAL_OK, GPU guest, node, agent, B58 (B58 é sucessor documental)

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

# Após Task 1
test -f docs/especie-canonica-linha-b.md -o -f docs/runtime-native-perf-especie.md
# decisão A/B + ponte 0020 documentada

# Após Task 2 — sucesso B (esperado)
test -f docs/adr/0021-*.md
grep -q 'INCONCLUSIVO\|teto\|0021\|B58' docs/harness-a-b-comparavel.md docs/especie-canonica-linha-b.md docs/runtime-native-perf-especie.md 2>/dev/null || true
make verify-harness-comparable   # continua válido com INCONCLUSIVO/teto; sem COMPROVA fingido

# Após Task 2 — sucesso A (só com caminho novo)
./scripts/fetch-model.sh
make verify-harness-comparable
# B: PREFILL_LAYERS=22, N_PREDICT=32; VERDICT_REASON sem teto/subset
```

Proibido: inventar tokens; COMPROVA com subset; remover reason de teto sem espécie canônica real.
