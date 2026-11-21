# Tasks — Carga GGUF canônica na Linha B (mínimo honesto)

Uma task = uma fatia.

- [x] Task 1 — Contrato documental (caminho GGUF canônico em B + bloqueio honesto + deps B13/B14)
  - **Paralelo-seguro:** não depende de merge de B13/B14; não edita kernel nem specs das etapas irmãs.
  - **Pronto quando:** `docs/runtime-nativo-linha-b.md` e `docs/harness-linha-a-b.md` descrevem: (1) carga canônica alvo em B (TinyLlama 1.1B Chat v1.0 Q4_K_M, prompt canônico, `n-predict=32`); (2) pré-requisitos fortes Etapa 19/B13 e Etapa 20/B14; (3) tabela de marcadores de **sucesso GGUF** (`LOAD_KIND=gguf`, `LOAD_S`/`TOKENS_PER_S` só medidos) vs **bloqueio** (`B_BLOCK=…`, `LOAD_KIND=blocked`); (4) proxy Etapa 12 permanece distinto (`LOAD_KIND=proxy`) até GGUF real; (5) proibição de inventar métricas e de declarar hipótese comprovada; ponte mínima em `docs/architecture.md` se necessário; `AGENTS.md` menciona a intenção/cenários; README avaliado (`readme-por-fatia`). Sem código de produto além do necessário para docs.

- [x] Task 2 — Harness/gate alinhados ao contrato (stubs de bloqueio; sem inventar números)
  - README: avaliado; sem mudança (capa aponta AGENTS; não enganosa).
  - **Pronto quando:** `scripts/run-harness-line-b.sh` e `scripts/verify-harness.sh` (e ponte AGENTS) distinguem honestamente: proxy Etapa 12 (default de sucesso mínimo atual) **e/ou** caminho de bloqueio documentado (`B_BLOCK` / `LOAD_KIND=blocked`); **falham** se aparecerem `TOKENS_PER_S` / `LOAD_S` GGUF / `MODEL` TinyLlama em B **sem** evidência de carga real; mensagem de gate deixa claro “hipótese não comprovada”; `make verify-harness` continua verde no cenário proxy (ou proxy+bloqueio documentado) **sem** fingir GGUF no QEMU. README reavaliado. Integração profunda com B13/B14 **não** obrigatória nesta fatia.

- [x] Task 3 — Integração harness ↔ contrato nativo (condicionada a B13 + B14)
  - **Deps:** Etapas 19/20 **feitas** no main (merge em `etapa-b15`).
  - README: avaliado; sem mudança (capa aponta AGENTS; não enganosa).
  - **Pronto quando:** harness B exige serial MEM_SCHED + fases + proxy; emite `CONTRACT_READY=1`, `GGUF_TARGET_MODEL=` / `N_PREDICT=32` / `PROMPT=canonical_v1`, `GGUF_NATIVE_LOADER=absent`; **sem** `TOKENS_PER_S`/`LOAD_S`/`LOAD_KIND=gguf`. Docs + `verify-harness` alinhados.

- [x] Task 4 — Carga GGUF real em B com métricas em espécie **ou** bloqueio final honesto
  - README: avaliado; sem mudança.
  - **Desfecho (b):** inviabilidade confirmada no QEMU/IA Livre — sem loader GGUF / FS / motor de inferência pós-ExitBoot; `B_BLOCK=no_gguf_path`, `GGUF_STATUS=blocked`; proxy E12 permanece instrumento mínimo; gate sem números inventados. Hipótese **não** comprovada; sem GPU manager; docs/`AGENTS.md` alinhados. Etapa pronta para revisão pelo agente principal (marcar `feita` após gate + revisor).
