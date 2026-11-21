# Tasks — Carga GGUF canônica na Linha B (mínimo honesto)

Uma task = uma fatia.

- [x] Task 1 — Contrato documental (caminho GGUF canônico em B + bloqueio honesto + deps B13/B14)
  - **Paralelo-seguro:** não depende de merge de B13/B14; não edita kernel nem specs das etapas irmãs.
  - **Pronto quando:** `docs/runtime-nativo-linha-b.md` e `docs/harness-linha-a-b.md` descrevem: (1) carga canônica alvo em B (TinyLlama 1.1B Chat v1.0 Q4_K_M, prompt canônico, `n-predict=32`); (2) pré-requisitos fortes Etapa 19/B13 e Etapa 20/B14; (3) tabela de marcadores de **sucesso GGUF** (`LOAD_KIND=gguf`, `LOAD_S`/`TOKENS_PER_S` só medidos) vs **bloqueio** (`B_BLOCK=…`, `LOAD_KIND=blocked`); (4) proxy Etapa 12 permanece distinto (`LOAD_KIND=proxy`) até GGUF real; (5) proibição de inventar métricas e de declarar hipótese comprovada; ponte mínima em `docs/architecture.md` se necessário; `AGENTS.md` menciona a intenção/cenários; README avaliado (`readme-por-fatia`). Sem código de produto além do necessário para docs.

- [x] Task 2 — Harness/gate alinhados ao contrato (stubs de bloqueio; sem inventar números)
  - README: avaliado; sem mudança (capa aponta AGENTS; não enganosa).
  - **Pronto quando:** `scripts/run-harness-line-b.sh` e `scripts/verify-harness.sh` (e ponte AGENTS) distinguem honestamente: proxy Etapa 12 (default de sucesso mínimo atual) **e/ou** caminho de bloqueio documentado (`B_BLOCK` / `LOAD_KIND=blocked`); **falham** se aparecerem `TOKENS_PER_S` / `LOAD_S` GGUF / `MODEL` TinyLlama em B **sem** evidência de carga real; mensagem de gate deixa claro “hipótese não comprovada”; `make verify-harness` continua verde no cenário proxy (ou proxy+bloqueio documentado) **sem** fingir GGUF no QEMU. README reavaliado. Integração profunda com B13/B14 **não** obrigatória nesta fatia.

- [ ] Task 3 — Integração harness ↔ contrato nativo (condicionada a B13 + B14)
  - **Condição:** só avançar implementação de ligação quando B13 e B14 estiverem verificáveis no branch/main adotado; caso contrário, registrar bloqueio honesto (docs + marcadores da Task 1/2) e **não** inventar carga — a fatia pode concluir como “bloqueio documentado / adiamento da ligação” com evidência.
  - **Pronto quando (se deps OK):** harness B (e, se necessário, ponto de entrada documentado no caminho nativo) consome o contrato de memória/scheduler + runtime nativo para preparar a carga canônica, com marcadores intermediários honestos; ainda **sem** emitir `TOKENS_PER_S` se a inferência GGUF não tiver corrido de ponta a ponta. **Pronto quando (se deps ausentes):** bloqueio `awaiting_b13_b14` (ou equivalente) documentado + gate coerente; sem métricas GGUF inventadas. README reavaliado.

- [ ] Task 4 — Carga GGUF real em B com métricas em espécie **ou** bloqueio final honesto
  - **Pronto quando:** um dos dois desfechos, ambos válidos para a Etapa 21: (a) corrida Linha B com TinyLlama Q4_K_M, prompt canônico, `n-predict=32`, emitindo `HARNESS_OK` + `LOAD_KIND=gguf` + `LOAD_S=` / `TOKENS_PER_S=` **medidos**, gate atualizado aceitando esse caminho; **ou** (b) inviabilidade confirmada → bloqueio final documentado, gate sem números inventados, proxy Etapa 12 permanece o instrumento mínimo. Em ambos: hipótese **não** comprovada; sem GPU manager; `AGENTS.md` / docs alinhados; README reavaliado; etapa pronta para revisão (não marcar `feita` aqui).
