# Plan — Bloqueio final documentado da hipótese A/B

## Abordagem

1. **ADR terminal + reabertura (Task 1):** emitir ADR **0022** (preferida) distinguindo inviabilidade **operacional** (0020 passo N≥8; 0021 canônico 22L×32) de **bloqueio terminal** do **pilar 1** / hipótese no gate atual. Incluir: evidência encadeada; o que **não** muda no instrumento (teto 2L×1, `INCONCLUSIVO`); **critérios de reabertura** concretos; ponte a E58/checklist. Atualizar ponte em 0021 (“B58 = E61”) se necessário. **Sem** expandir espécie guest. **Sem** editar hot path.

2. **Checklist + docs de produto (Task 2):** atualizar `docs/prototipo-objetivo-atingido.md` pilar 1 → estado **atingido via bloqueio final** (não COMPROVA); glossário (entrada ADR 0022 / “bloqueio terminal”); `product-context.md`; notas em `harness-a-b-comparavel.md` / `runtime-native-perf-especie.md` (hipótese fechada no checklist até reabertura; instrumento permanece honesto). README avaliar (`readme-por-fatia`).

3. **Gate documental + AGENTS (Task 3):** estender `scripts/verify-prototipo-objetivo.sh` (e/ou `verify-runtime-native-perf.sh`) para exigir presença de ADR 0022 (ou marcadores de bloqueio terminal + reabertura) e coerência do pilar 1; espelhar em `AGENTS.md` / `Makefile` se gate novo ou greps novos. Confirmar que **nenhum** gate passa a exigir `COMPROVA`.

Ordem: 1 → 2 → 3. Uma fatia por vez. Preferir docs/ADR; zero código de runtime/kernel salvo se Task 3 tocar só scripts de verify.

## Arquivos prováveis

- `docs/adr/0022-*.md` (**Task 1**; nome final na fatia, ex. `0022-bloqueio-final-hipotese-ab.md`)
- `docs/adr/0021-*.md`, `docs/adr/0020-*.md` (ponte; sem reescrever decisão E59/E60)
- `docs/prototipo-objetivo-atingido.md` (pilar 1)
- `docs/glossario.md`, `docs/product-context.md`
- `docs/harness-a-b-comparavel.md`, `docs/runtime-native-perf-especie.md` (notas)
- `scripts/verify-prototipo-objetivo.sh` e/ou `scripts/verify-runtime-native-perf.sh`
- `AGENTS.md`, `Makefile` (se gate/grep), `README.md` (avaliar)
- `specs/bloqueio-final-hipotese-ab/tasks.md`
- **Não esperado:** `runtime-native/`, `kernel/`, harness runners de geração

## Dependências

- Etapas 58/59/60 + ADR 0016/0020/0021 — **feitas**
- **Não** depende de METAL_OK, GPU guest, espécie canônica no guest, B55

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Após Task 1
test -f docs/adr/0022-*.md   # ou extensão inequívoca documentada em 0021
grep -qiE 'terminal|reabertura|pilar 1' docs/adr/0022-*.md

# Após Task 2
grep -qiE 'bloqueio final|terminal' docs/prototipo-objetivo-atingido.md
grep -q '0022\|bloqueio final' docs/glossario.md docs/harness-a-b-comparavel.md 2>/dev/null || true
# comparable: sem COMPROVA como estado; INCONCLUSIVO/teto ou reason terminal

# Após Task 3
make verify-prototipo-objetivo
# e/ou make verify-runtime-native-perf — conforme extensão escolhida
# Esperado: OK documental; proibido exigir COMPROVA
```

Proibido: inventar tokens; COMPROVA com subset; expandir espécie guest; celebrar hipótese comprovada.
