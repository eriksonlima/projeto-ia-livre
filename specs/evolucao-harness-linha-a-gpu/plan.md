# Plan — Evolução do harness (Linha A otimizada / perfil GPU)

## Abordagem

1. **Metodologia A otimizada** (Task 1): documentar o perfil «Linux otimizado» da Linha A — checklist, distinção vs baseline pragmática do harness v1, carga canônica e honestidade vs hipótese. Preferir doc dedicado **ou** seção nova em `harness-linha-a-b.md` (path fixado na task).
2. **Metodologia perfil GPU A/B** (Task 2): documentar espelho GPU (carga canônica + offload host na A; pré-condições para B; fronteira ADR 0002 / métricas E8 / ADR 0006); **sem** inventar números B GGUF.
3. **Pontes + decisão de gate** (Task 3): integrar em `harness-linha-a-b.md` / `architecture.md` / `AGENTS.md` se couber; **default** = gate permanece `make verify-harness`. Só adicionar script/gate se houver execução real dos perfis nesta etapa.

Ordem: A otimizada → GPU espelhado → pontes/gate (as pontes citam paths estáveis das Tasks 1–2).

## Arquivos prováveis

- `docs/harness-perfis-a-otimizada-gpu.md` (ou seções equivalentes em `docs/harness-linha-a-b.md`)
- `docs/harness-linha-a-b.md` — atualizar limitação «sem tuning» / «GPU fora do v1» → apontar perfis
- `docs/architecture.md` — hipótese / harness: metodologia evoluída; prova aberta
- `docs/runtime-inferencia-gpu-metricas.md` e/ou ADR 0002 — ponte curta «protótipo E8 ≠ perfil GPU do harness» (se necessário)
- `docs/runtime-nativo-linha-b.md` — ponte opcional (B ainda proxy; GPU-B futuro)
- `AGENTS.md` — só se precisar apontar doc/gate; **sem** inventar gate se não houver execução
- `README.md` — avaliar (`readme-por-fatia`)
- `scripts/run-harness-line-a.sh` / `verify-harness.sh` — **só** se Task 3 optar por execução real
- `specs/evolucao-harness-linha-a-gpu/tasks.md` — marcar fatias

## Dependências

- Etapas 9 e 12 feitas (harness v1 + B proxy).
- ADR 0002 / Etapa 8 disponíveis como referência de GPU host (não confundir com harness).
- Etapa 16 (ADR 0006) = desenho GPU manager — **não** implementar aqui.
- GGUF / QEMU só necessários se houver execução real de gate; checklist documental **não** exige corrida nova.

## Verificação

Gate desta etapa = **checklist documental** (+ gate de código **somente** se execução real for adotada):

```bash
# Sempre (metodologia)
test -f docs/harness-linha-a-b.md
# Doc dedicado OU seções equivalentes — path fixado nas tasks:
# test -f docs/harness-perfis-a-otimizada-gpu.md
grep -qiE 'otimizad|Linux otimizado|perfil GPU|espelhad' docs/harness-linha-a-b.md \
  docs/harness-perfis-a-otimizada-gpu.md 2>/dev/null || true
grep -qiE 'harness|perfil|otimizad|GPU' docs/architecture.md

# Se NÃO houver execução real nesta etapa:
# - AGENTS/docs afirmam que make verify-harness permanece o gate
# - Sem make verify-harness-gpu / verify-harness-optimized obrigatório

# Se HOUVER execução real: script + marcadores documentados + comando de gate
# make verify-harness   # não deve regredir (A CPU + B proxy)
```

Critério de pronto da etapa: metodologias A-otimizada e GPU-espelhado publicadas; hipótese não comprovada; B GGUF não inventado; gate alinhado à regra «só se execução real».
