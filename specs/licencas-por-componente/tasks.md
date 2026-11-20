# Tasks — Licenças definitivas por componente

Uma task = uma fatia.

- [x] Task 1 — ADR da política de licenças por componente
  - **Pronto quando:** existe ADR nova (ex.: `docs/adr/0007-licencas-por-componente.md`) com status **aceita**: tabela Apache-2.0 para `kernel`, `runtime`, `node`, `agent` e `docs`; justifica **não** usar GPLv3 nesta etapa (todos os componentes listados = infraestrutura / alinhamento à preferência do manifesto); nota explícita de que **não** é parecer jurídico e que revisão futura pode ajustar; lista o que não fica decidido (compliance fino de distribuição de deps, pesos GGUF); rejeita relicenciar terceiros. Sem arquivos `LICENSE` ainda (Task 2) e sem reescrever o manifesto inteiro. README avaliado (`readme-por-fatia`).
  - **Feito:** `docs/adr/0007-licencas-por-componente.md`; README considerado (sem mudança nesta fatia).

- [ ] Task 2 — Arquivos LICENSE / NOTICE e metadados Cargo
  - **Pronto quando:** `LICENSE` Apache-2.0 na raiz do repositório; `NOTICE` e/ou `docs/licencas-terceiros.md` com copyright do projeto + aviso de deps relevantes (`llama-cpp-2`/llama.cpp, `uefi`, etc.) sob licenças próprias; `license = "Apache-2.0"` nos `Cargo.toml` de `kernel`, `runtime`, `node` e `agent`. Sem mudança de lógica de produto. README reavaliado.

- [ ] Task 3 — Pontes manifesto / architecture / README e fechamento documental
  - **Pronto quando:** `docs/manifesto.md` atualiza a preferência (remove «decisão a confirmar») e aponta ADR + `LICENSE`; `docs/architecture.md` marca licenças por componente como **decididas** (link ADR) e remove o item da lista de abertas; `README.md` menciona Apache-2.0 / ponte a `LICENSE` se a capa do GitHub ficaria enganosa sem isso (senão registrar que foi considerado); ponte curta em `AGENTS.md` e/ou `CONTRIBUTING.md` se a estrutura pública precisar; etapa pronta para revisão (não marcar `feita` aqui). Sem código de produto além do já feito na Task 2.
