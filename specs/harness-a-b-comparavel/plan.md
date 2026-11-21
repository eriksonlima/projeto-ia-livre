# Plan — Harness A vs B comparável (prova ou refutação da hipótese)

## Abordagem

Três fatias até o Pronto quando da Etapa 22. Entrega = **instrumento de comparação honesta** (metodologia + corrida/relatório + gate). **Não** implementa GGUF em B (B14/B15); **não** toca kernel da Etapa 19; **não** declara vitória sem evidência comparável.

Enquanto B for proxy: o caminho feliz do gate é `INCONCLUSIVO` com reason explícita. Quando B15 entregar GGUF real, o mesmo instrumento passa a poder emitir `COMPROVA`/`REFUTA` sem reescrever a metodologia.

### Task 1 — Metodologia comparável + critérios de veredito (doc)

1. Criar `docs/harness-a-b-comparavel.md` (preferido) **ou** seção inequívoca em `harness-linha-a-b.md` se a Task decidir consolidar — preferir doc dedicada para não misturar “instrumento v1” com “prova/refutação”.
2. Conteúdo mínimo:
   - Ponte hipótese (product-context / architecture) e harness v1 (A GGUF vs B proxy = **não** comparável).
   - Checklist de **pré-condição de comparabilidade** (modelo/quant/prompt/`n-predict`/accel/host; B ≠ proxy).
   - Tabela `COMPROVA` / `REFUTA` / `INCONCLUSIVO` + critério numérico mínimo (ex. `TOKENS_PER_S`) + **limites** (ruído, N=1, A pragmática, ausência GPU-B, dependência B15).
   - Marcadores do relatório (`IA_LIVRE_HARNESS_VERDICT=`, `VERDICT_REASON=`).
   - O que é proibido (inventar tokens em proxy; equivalência PROXY↔tokens; tratar `verify-harness` como prova).
3. Ponte curta em `docs/harness-linha-a-b.md` → doc nova (“comparável = Etapa 22”).
4. Avaliar `README.md` (`readme-por-fatia`); cedo demais → registrar.

Critério parcial: metodologia legível; `INCONCLUSIVO` é resultado de primeira classe.

### Task 2 — Script de corrida A vs B + relatório honesto

1. Script novo, ex. `scripts/run-harness-a-b-comparable.sh`:
   - Chama `run-harness-line-a.sh` e `run-harness-line-b.sh` (ou entrypoint B GGUF documentado quando B15 existir — detecção por marcadores/`LOAD_KIND`/env).
   - Agrega saída; emite `IA_LIVRE_HARNESS_VERDICT=…` + `IA_LIVRE_HARNESS_VERDICT_REASON=…`.
   - Se B tiver `PROXY=` / `LOAD_KIND=proxy` / sem `TOKENS_PER_S` em B → **obrigatório** `INCONCLUSIVO` (não `COMPROVA`/`REFUTA`).
   - Se ambas GGUF comparáveis → aplica critério da Task 1 → `COMPROVA` ou `REFUTA` (ou `INCONCLUSIVO` se dentro da margem de ruído / critério não decisório).
2. **Proibido:** fabricar `TOKENS_PER_S` para B; mapear `PROXY_MS` para tokens.
3. Documentar comando em `AGENTS.md` (Como rodar — parcial ok; gate na Task 3).
4. `readme-por-fatia`: reavaliar.

Critério parcial: uma corrida local com B proxy produz relatório `INCONCLUSIVO` + reason; sem métricas falsas.

### Task 3 — Gate/verify + pontes AGENTS/README

1. Escolher uma forma (documentar a escolha):
   - **(a)** alvo novo `make verify-harness-comparable` + `scripts/verify-harness-comparable.sh`, **ou**
   - **(b)** extensão documentada de `verify-harness` com modo/flag explícito — só se não quebrar o semântica atual (A+B proxy = ok do v1).
   - Preferir **(a)** para não confundir “harness v1 passa” com “comparável julgado”.
2. Política do gate comparável:
   - Roda o script da Task 2; exige `VERDICT=` ∈ {COMPROVA, REFUTA, INCONCLUSIVO} + `VERDICT_REASON=`.
   - Exit 0 com `INCONCLUSIVO` se B não comparável.
   - Exit ≠ 0 se `COMPROVA`/`REFUTA` sem pré-condição; se B proxy emitir `TOKENS_PER_S`; se faltar reason.
   - Timeout documentado (reutilizar/`VERIFY_HARNESS_COMPARABLE_TIMEOUT` ou herdar `VERIFY_HARNESS_TIMEOUT`).
3. Completar `AGENTS.md` → Como verificar; Estrutura se houver script novo.
4. Ponte final na doc da Task 1 (como rodar o gate).
5. `readme-por-fatia`: menção curta na capa só se omitir enganar o visitante.
6. Não marcar ROADMAP Etapa 22 `feita` nesta task — agente principal após gate + revisor.
7. **Não** editar `kernel/**`, `AGENT_CLAIM.md`, nem specs/código da Etapa 19.

### Detecção B comparável (orientação)

| Sinal | Interpretação |
|-------|----------------|
| `IA_LIVRE_HARNESS_PROXY=` ou `LOAD_KIND=proxy` em B | **Não** comparável → `INCONCLUSIVO` |
| B com `HARNESS_TOKENS_PER_S=` + `LOAD_S=` + `MODEL=` GGUF canônico (sem PROXY) | Candidato a comparável (após checklist) |
| Env futuro (ex. `IA_LIVRE_HARNESS_B_GGUF=1`) | Opcional; preferir marcadores da corrida |

### Valores canônicos (orientação)

| Item | Valor |
|------|--------|
| Carga | Mesma do harness v1 (TinyLlama Q4_K_M, prompt fixo, `n-predict=32`, CPU) |
| Veredito | `IA_LIVRE_HARNESS_VERDICT=COMPROVA\|REFUTA\|INCONCLUSIVO` |
| Motivo | `IA_LIVRE_HARNESS_VERDICT_REASON=` (grepável, uma linha) |
| Script | `scripts/run-harness-a-b-comparable.sh` |
| Gate (preferido) | `make verify-harness-comparable` |
| Doc | `docs/harness-a-b-comparavel.md` |

## Arquivos prováveis

- `docs/harness-a-b-comparavel.md` (Task 1)
- `docs/harness-linha-a-b.md` — ponte curta (Task 1)
- `scripts/run-harness-a-b-comparable.sh` (Task 2)
- `scripts/verify-harness-comparable.sh`, `Makefile` — alvo novo (Task 3)
- `AGENTS.md` — Como rodar / Como verificar / Estrutura
- `README.md` — só se `readme-por-fatia` exigir
- Opcional: uma linha em `docs/product-context.md` / `architecture.md` apontando o instrumento de veredito

**Não editar:** `kernel/**`, `memory-bank/AGENT_CLAIM.md`, specs/código da Etapa 19 (`memoria-scheduler-*`), implementação B14/B15 (só consumir contrato quando existir).

## Dependências

- Etapas 9/12/18 feitas (harness v1 + proxy B + perfis documentados)
- Runtime host + GGUF para Linha A; QEMU para B proxy (já no `verify-harness`)
- **B15 / Etapa 21** para qualquer `COMPROVA`/`REFUTA` real — **não** bloqueia entrega com `INCONCLUSIVO`
- Sem GPU manager; sem depender de fechar Etapa 19

## Verificação

1. Checklist de `spec.md` (critérios de aceite)
2. Corrida com B proxy → `INCONCLUSIVO` + reason; gate comparável exit 0
3. Gate rejeita `COMPROVA` forjado / tokens em proxy (teste documental ou asserção no script)
4. `make verify-harness` (v1) **não** regride por acidente
5. Após gate verde da etapa: agente principal chama `revisor-de-fatia`, atualiza ROADMAP/Memory Bank (fora do papel do especificador)
