# Tasks — Ambiente de autonomia além do protótipo (v1 utilizável)

Uma task = uma fatia.

- [ ] Task 1 — ADR do escopo da autonomia v1 utilizável
  - **Pronto quando:** existe ADR nova (ex.: `docs/adr/0005-autonomia-v1-utilizavel.md`) com status aceita *no nível desenho*: decide autonomia v1 no **host** (sem exigir SO IA Livre); UX CLI **one-shot** com `--prompt`; allowlist de ferramentas **`note` / `recall` / `help`**; política de memória JSONL com injeção das últimas **N** entradas; critério verificável mínimo documentado (prova de ≥2 ferramentas + política de memória, sem quebrar E7); afirma fronteira ADR 0001; **rejeita** P2P, kernel, marketplace, RAG, multi-agente, shell/rede na v1; lista consequências e o que **não** fica decidido (implementação, REPL, integração Rede). Sem código de produto. README avaliado (`readme-por-fatia`).

- [ ] Task 2 — Doc de desenho da autonomia v1 e critério verificável
  - **Pronto quando:** `docs/desenho-autonomia-v1.md` (ou nome alinhado à ADR) descreve motivação vs protótipo Etapa 7, tabela fronteira E7×v1×futuro, contratos das três ferramentas, política de memória (kinds, N, injeção), cenário e marcadores do critério verificável mínimo (relação com `make verify-agent`), alternativas consideradas; deixa explícito que `agent/` atual **não** implementa a v1 completa. Sem código de produto. README reavaliado.

- [ ] Task 3 — Pontes em architecture / protótipo de autonomia e fechamento documental
  - **Pronto quando:** `docs/architecture.md` marca a forma/escopo da autonomia v1 como **decidida no nível desenho** (link ADR + doc), mantendo implementação **aberta**; ponte mínima em `docs/ambiente-autonomia-prototipo.md` (Etapa 7 = protótipo; Etapa 15 = desenho ≠ código); `AGENTS.md` aponta os docs se a estrutura pública precisar; README reavaliado; etapa pronta para revisão (não marcar `feita` aqui). Sem código de produto.
