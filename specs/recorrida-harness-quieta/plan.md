# Plan — Re-corrida harness A vs B quieta

## Abordagem

Três fatias até o Pronto quando da Etapa 28. Entrega = **protocolo quieto + evidência de re-corrida + gate sob esse protocolo**. **Não** implementa motor de inferência em B; **não** altera contratos E19–E27; **não** declara `COMPROVA`/`REFUTA` enquanto `no_gguf_infer_engine`.

O instrumento E22 (`run-harness-a-b-comparable` / `verify-harness-comparable`) já existe e já emite `INCONCLUSIVO` com reason E27. Esta etapa **disciplina a medição** (sem contenção) e **registra** uma corrida limpa.

### Task 1 — Protocolo quieto documentado

1. Criar `docs/harness-corrida-quieta.md` (preferido) **ou** seção clara em `docs/harness-a-b-comparavel.md` se consolidar for mais legível — preferir doc dedicada curta + ponte, para não misturar “critérios de veredito” com “como medir sem contenção”.
2. Conteúdo mínimo:
   - Motivação (T/s deprimido sob gates paralelos; remediação serial já vista em métricas CPU).
   - Pré-condições (sem outro verify/QEMU/runtime/agent concorrente).
   - Ordem canônica: comparable (A depois B) **ou** equivalente documentado; um alvo por vez.
   - Como registrar carga do host, timeout, data, marcadores (`VERDICT`, `VERDICT_REASON`, métricas A).
   - O que NÃO fazer (paralelo; inventar tokens em B; tratar quieto como prova).
   - Expectativa atual: `INCONCLUSIVO` + `B_BLOCK=no_gguf_infer_engine`.
3. Ponte curta em `docs/harness-a-b-comparavel.md` (e opcionalmente harness v1 / métricas CPU).
4. Avaliar `README.md` (`readme-por-fatia`); cedo demais → registrar.

Critério parcial: procedimento legível; quieto = requisito de medição, não mudança de veredito forçada.

### Task 2 — Tooling mínimo (opcional) + re-corrida quieta registrada

1. Decidir (e documentar a escolha):
   - **(a)** checklist-only no doc + instrução no início dos scripts/AGENTS, **ou**
   - **(b)** preflight mínimo (ex. detectar `qemu-system` / processos `verify-*` e avisar/sair com override env documentado).
   - Preferir **(a)** se **(b)** for frágil ou over-engineered; **(b)** só se couber em poucas linhas sem falsos positivos graves.
2. Executar `./scripts/run-harness-a-b-comparable.sh` **e/ou** `make verify-harness-comparable` sob o protocolo.
3. Registrar no doc quieto (ou seção “Evidência Etapa 28”) a saída relevante: `VERDICT`, `VERDICT_REASON`, métricas A (`LOAD_S` / `TOKENS_PER_S` se presentes), confirmação de ausência de `TOKENS_PER_S` em B / presença de `B_BLOCK` ou reason E27.
4. **Proibido:** fabricar throughput B; alterar kernel/loader para “passar” o quieto.
5. `readme-por-fatia`: reavaliar.

Critério parcial: evidência de uma corrida quieta no doc; tooling alinhado à decisão (a)/(b).

### Task 3 — Gate sob protocolo + pontes AGENTS/README

1. Confirmar `make verify-harness-comparable` verde sob protocolo quieto com `VERDICT=INCONCLUSIVO` + reason; falha se inventar tokens em B ou `COMPROVA` sem comparabilidade.
2. Se Task 2 adotou preflight: garantir que o gate documenta override/skip e não quebra CI sem causa (ou que o preflight é só aviso).
3. Atualizar `AGENTS.md` se “Como verificar” omitir o protocolo quieto deixar o gate enganoso; senão ponte curta / registrar que não foi necessário.
4. `README.md`: só se a capa ficar enganosa.
5. Não marcar ROADMAP Etapa 28 `feita` nesta task — agente principal após gate + revisor.
6. **Não** editar `kernel/**`, contratos E19–E27, `runtime/` como se fosse B, GPU manager.

### Marcadores / expectativa (orientação)

| Item | Valor esperado nesta etapa |
|------|----------------------------|
| `IA_LIVRE_HARNESS_VERDICT` | `INCONCLUSIVO` (enquanto sem motor B) |
| `IA_LIVRE_HARNESS_VERDICT_REASON` | Motivo grepável com E27 / `no_gguf_infer_engine` (ou equivalente honesto) |
| Métricas A | Presentes (`LOAD_S` / `TOKENS_PER_S` na agregação A) |
| Métricas B geração | **Ausentes** — não inventar |
| Gate | `make verify-harness-comparable` exit 0 com veredito honesto |
| Doc | `docs/harness-corrida-quieta.md` (preferido) |

## Arquivos prováveis

- `docs/harness-corrida-quieta.md` (Task 1; evidência Task 2)
- `docs/harness-a-b-comparavel.md` — ponte quieta (Task 1)
- Opcional: `docs/harness-linha-a-b.md`, `docs/runtime-inferencia-cpu-metricas.md` — uma linha de ponte
- Opcional: `scripts/run-harness-a-b-comparable.sh` / `scripts/verify-harness-comparable.sh` — preflight mínimo (Task 2)
- `AGENTS.md` — Como verificar / menção ao protocolo (Task 3)
- `README.md` — só se `readme-por-fatia` exigir

**Não editar:** `kernel/**`, contratos loader/stub E26–E27 como mudança de produto, `node/`, `agent/` (produto), GPU manager, inventar motor B.

## Dependências

| Dependência | Papel |
|-------------|--------|
| Etapa 22 | Instrumento comparable + `VERDICT` |
| Etapa 27 | `B_BLOCK=no_gguf_infer_engine` — motivo do `INCONCLUSIVO` |
| GGUF + QEMU | Linha A e B do comparable |
| Métricas CPU serial | Motivação / referência de medição sem contenção |

## Verificação

1. Checklist de `spec.md` (critérios de aceite).
2. Doc quieto cobre pré-condições / ordem / proibições / registro.
3. Corrida quieta registrada: `INCONCLUSIVO` + reason; sem `TOKENS_PER_S` em B.
4. `make verify-harness-comparable` sob protocolo → exit 0.
5. `make verify-harness` (v1) **não** precisa mudar; se tocado, não regredir.
6. Relato: o que foi e o que **não** foi verificado (ex. preflight omitido de propósito).
7. Após gate verde: agente principal chama `revisor-de-fatia`, atualiza ROADMAP/Memory Bank (fora do papel do especificador).
