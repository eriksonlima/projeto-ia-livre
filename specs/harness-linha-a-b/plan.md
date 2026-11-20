# Plan — Harness da hipótese Linha A vs Linha B

## Abordagem

Três fatias verticais até o Pronto quando da Etapa 9. Entrega = **instrumento de medição** (metodologia + Linha A reproduzível + stub Linha B + gate). **Não** runtime nativo no kernel; **não** prova da hipótese; **não** misturar com docs E5/E8.

### Task 1 — Metodologia + doc + contrato do slot B

1. Criar `docs/harness-linha-a-b.md` com: hipótese (ponte architecture/product-context); definição A vs B **nesta** etapa; carga canônica (modelo/prompt/`n-predict`/CPU); métricas e marcadores `IA_LIVRE_HARNESS_*`; limitação “A = referência pragmática, não tuning OS completo”; o que **não** conta como B; contrato do stub (`B_SKIP` até runtime nativo existir); aviso de que E5/E8 **não** são este harness.
2. Atualizar `docs/architecture.md`: fechar/apontar a decisão aberta do harness para esta doc.
3. Opcional barato: uma linha de ponte nas docs `runtime-inferencia-*-metricas.md` apontando o harness.
4. Esboçar em `AGENTS.md` (parcial) a existência do harness / path da doc — comando completo pode ficar para Tasks 2–3.
5. Avaliar `README.md` (`readme-por-fatia`); provavelmente cedo demais — registrar.

Critério parcial: metodologia legível; A e B definidos sem ambiguidade; hipótese não “provada”.

### Task 2 — Harness Linha A executável + stub Linha B

1. Script(s), ex.:
   - `scripts/run-harness-line-a.sh` — invoca `ia-livre-runtime` com carga canônica (`--n-gpu-layers 0`), normaliza/emite `IA_LIVRE_HARNESS_LINE=A`, `IA_LIVRE_HARNESS_OK`, `LOAD_S`, `TOKENS_PER_S`, `MODEL`, `N_PREDICT` (pode mapear a partir da saída do runtime ou reimprimir de forma canônica).
   - `scripts/run-harness-line-b.sh` — stub: imprime `IA_LIVRE_HARNESS_B_SKIP` + motivo; exit 0.
2. Preferir **subprocesso** do binário `target/debug/ia-livre-runtime` (ou path configurável) — não duplicar llama.cpp.
3. Documentar comandos em `AGENTS.md` (Como rodar harness).
4. Rodar manualmente Linha A uma vez no host e registrar números de exemplo **na doc do harness** (tabela “baseline A”, com hardware) — claramente rotulados como baseline, não prova.
5. `readme-por-fatia`: reavaliar.

Critério parcial: A reproduzível com marcadores; B só skip; sem números inventados de B.

### Task 3 — Gate `verify-harness` + AGENTS completo

1. `scripts/verify-harness.sh` + alvo Makefile `verify-harness`.
2. Política: build runtime se necessário; rodar A; exigir `IA_LIVRE_HARNESS_OK` + marcadores mínimos; rodar stub B e aceitar `IA_LIVRE_HARNESS_B_SKIP`; timeout (ex. 300s, `VERIFY_HARNESS_TIMEOUT`); **não** exigir QEMU/GPU.
3. Completar `AGENTS.md` → Como verificar (Etapa 9).
4. Confirmar que gates E5/E8/etc. não foram quebrados por acidente (pelo menos não alterar comportamento default do runtime além do necessário para o harness).
5. `readme-por-fatia`: se a capa omitir o harness e isso enganar, menção curta + ponte AGENTS; senão “considerado, não necessário”.
6. Não marcar roadmap `feita` nesta task — agente principal após gate + revisor.

### Valores canônicos (orientação)

| Item | Valor |
|------|--------|
| Modelo | TinyLlama 1.1B Chat v1.0 Q4_K_M |
| Prompt | `Complete em uma frase: O Projeto IA Livre é` |
| `--n-predict` | 32 |
| `--n-gpu-layers` (harness v1) | 0 (CPU) |
| Prefixo marcadores | `IA_LIVRE_HARNESS_` |
| Skip B | `IA_LIVRE_HARNESS_B_SKIP` |
| Make | `verify-harness` |

### Notas de implementação (orientação, não código aqui)

- Não commitar GGUF; `fetch-model.sh` como pré-requisito do gate A.
- Não tocar `kernel/`, `node/`, `agent/` salvo ponte documental.
- Se o runtime já emite `IA_LIVRE_LOAD_S` / `TOKENS_PER_S`, o script A pode reemitir sob namespace HARNESS_ — evita confundir logs de protótipo com harness.
- Evitar ADR nova só para o harness salvo escolha estrutural inesperada; a doc do harness + ponte em architecture bastam para esta etapa.

## Arquivos prováveis

- `docs/harness-linha-a-b.md` (Task 1; baseline A na Task 2)
- `docs/architecture.md` — apontar harness
- `docs/runtime-inferencia-cpu-metricas.md` / `docs/runtime-inferencia-gpu-metricas.md` — ponte opcional (Task 1)
- `scripts/run-harness-line-a.sh`, `scripts/run-harness-line-b.sh` (Task 2)
- `scripts/verify-harness.sh`, `Makefile` — `verify-harness` (Task 3)
- `AGENTS.md` — Como rodar / Como verificar / Estrutura
- `README.md` — só se `readme-por-fatia` exigir

Não editar como entrega de produto novo: `kernel/**`, `node/**`, `agent/**`; `runtime/**` só se for estritamente necessário para expor marcadores estáveis (preferir script wrapper).

## Dependências

- Etapas 1–8 feitas (runtime host gateado; modelo canônico)
- Rust + deps do runtime + GGUF via `./scripts/fetch-model.sh`
- Sem dependência de QEMU/UEFI, GPU, P2P ou agent para o gate do harness

## Verificação

1. Checklist de `spec.md` (critérios de aceite)
2. Gate: `make verify-harness` — A ok, B skip
3. Docs E5/E8 permanecem explícitas como **não**-harness
4. Após gate verde da etapa: agente principal chama `revisor-de-fatia`, atualiza ROADMAP/Memory Bank (fora do papel do especificador)
