# Spec — Licenças definitivas por componente

## Resultado visível

Existe uma **política de licenças por componente registrada no repositório**:

1. **Decisão documentada** (ADR) de qual licença cobre cada componente de primeira parte: `kernel`, `runtime`, `node`, `agent` e `docs`.
2. **Arquivos de licença no repo** (`LICENSE` / `NOTICE` ou equivalente) + metadados Cargo (`license` / SPDX) alinhados à decisão.
3. **Pontes** no manifesto (frase «a confirmar» atualizada), em `docs/architecture.md` (decisão aberta fechada) e na capa (`README.md` / `AGENTS.md` se couber).

A etapa **registra** a escolha no repositório. Não é opinião jurídica formal; a documentação deixa explícito que revisão jurídica futura pode ajustar.

## Contexto fixo (não reinventar)

- Manifesto — preferência (ainda «a confirmar»): **Apache 2.0** para infraestrutura; **GPLv3** onde preservação das liberdades de redistribuição for prioridade — [`docs/manifesto.md`](../../docs/manifesto.md) § Política open source.
- Decisão aberta em [`docs/architecture.md`](../../docs/architecture.md): «Licenças definitivas por componente».
- Componentes de código no workspace: `kernel/`, `runtime/`, `node/`, `agent/` ([`Cargo.toml`](../../Cargo.toml) raiz).
- Documentação institucional e técnica sob `docs/` (+ README/AGENTS/specs como superfície do projeto).
- Hoje: **sem** `LICENSE` / `NOTICE` na raiz; crates **sem** campo `license` no `Cargo.toml`.
- Dependências de terceiros (ex.: llama.cpp via `llama-cpp-2`, `uefi-rs`) mantêm licenças próprias — **não** relicenciar; só documentar.
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`; se não precisar, registrar.

## Decisão de política (única — obrigatória)

| Peça | Escolha nesta etapa |
|------|---------------------|
| Forma | **Registro no repo** (ADR + arquivos LICENSE/NOTICE + pontes) — não só ADR abstrato |
| Código de 1ª parte | **Apache License 2.0** para `kernel`, `runtime`, `node` e `agent` |
| Documentação (`docs/` e textos institucionais do repo) | **Apache License 2.0** (mesma família que a infra; evita dualismo desnecessário nesta etapa) |
| GPLv3 | **Não** aplicada a nenhum componente de 1ª parte nesta decisão; se no futuro algum artefato exigir copyleft, nova ADR/etapa com justificativa explícita |
| Alinhamento ao manifesto | Preferência «Apache 2.0 para infraestrutura» **confirmada** para todos os componentes listados; trecho «a confirmar» atualizado |
| Dependências de terceiros | Permanecem sob suas licenças; registrar aviso (NOTICE ou doc curto) — **sem** redistribuir textos completos de licenças alheias além do necessário |
| Orientação jurídica | Decisão **do projeto**; nota obrigatória: não substitui parecer jurídico; revisão futura pode ajustar |
| ADR | **Nova** (ex.: `docs/adr/0007-licencas-por-componente.md`) — status **aceita** |
| Arquivo canônico na raiz | `LICENSE` com o texto Apache-2.0; opcional `NOTICE` (atribuições / ponte a terceiros) |
| Metadados Cargo | Campo `license = "Apache-2.0"` (ou SPDX equivalente) em cada crate do workspace |
| Critério verificável | Checklist documental + presença dos arquivos; **sem** gate `make verify*` novo |

### Rejeitado (explícito)

- Relicenciar ou «embrulhar» llama.cpp / uefi / outras deps sob a licença do projeto.
- Aplicar GPLv3 «por precaução» sem justificativa de componente.
- Dual-license Apache+GPL nesta etapa (aumenta complexidade sem ganho claro).
- Reescrever o manifesto inteiro (só a política de licenças / frase a confirmar).
- Implementar features de produto ou mudar comportamento de runtime/kernel/node/agent.
- Fingir que a ADR dispensa compliance com licenças de terceiros no binário/distribuição.
- Orientação jurídica formal ou parecer de advogado como entregável desta etapa.

### Mapa por componente (a gravar na ADR e nos arquivos)

| Componente | Path | Licença de 1ª parte |
|------------|------|---------------------|
| Kernel IA Livre | `kernel/` | Apache-2.0 |
| Runtime de inferência | `runtime/` | Apache-2.0 |
| Nó Rede IA Livre | `node/` | Apache-2.0 |
| Ambiente de autonomia | `agent/` | Apache-2.0 |
| Documentação | `docs/` (+ textos de projeto listados na ADR) | Apache-2.0 |

Pesos GGUF / modelos em `models/` **não** são código do projeto; continuam com origens/licenças próprias (já na política open source do manifesto) — fora do mapa de crates; mencionar honestidade na ADR se couber uma linha.

## Conteúdo obrigatório

### 1. ADR (política)

- Contexto: decisão aberta em architecture + preferência do manifesto.
- Decisão: tabela por componente; Apache-2.0 para todos os listados; GPLv3 não usada agora (com motivo: todos são infra / alinhamento à preferência Apache).
- Consequências (+/−); o que **não** fica decidido (parecer jurídico, compliance fino de deps em distribuição, relicenciamento futuro).
- Nota explícita: decisão do projeto, não aconselhamento jurídico.

### 2. Arquivos no repositório

- `LICENSE` na raiz (texto Apache-2.0).
- `NOTICE` (ou `docs/licencas-terceiros.md` se preferir doc) com: copyright do Projeto IA Livre + aviso de que deps/bindings têm licenças próprias (nomear as relevantes: pelo menos llama.cpp / `llama-cpp-2`, `uefi`).
- `license = "Apache-2.0"` nos `Cargo.toml` de `kernel`, `runtime`, `node`, `agent` (e workspace se aplicável sem inventar crate raiz publicável).

### 3. Pontes

- `docs/manifesto.md`: substituir «decisão a confirmar» por decisão confirmada + ponte à ADR / LICENSE.
- `docs/architecture.md`: marcar licenças como decididas (link ADR); remover da lista de abertas.
- `README.md`: avaliar (`readme-por-fatia`) — menção curta à licença Apache-2.0 + ponte a `LICENSE` / ADR se a capa ficar enganosa sem isso (provável: sim, home do GitHub).
- `AGENTS.md` / `CONTRIBUTING.md`: ponte curta se a estrutura pública precisar (sem gate novo).

## Fora de escopo

- Relicenciar dependências de terceiros.
- Implementação de features de produto.
- Parecer jurídico externo.
- Mudança de governança ou princípios imutáveis do manifesto.
- Marcar a Etapa 17 como `feita` (agente principal + gate/revisor).
- Commit/push (agente principal).

## Critérios de aceite

- [ ] ADR 0007 (ou número fixado) com tabela por componente e nota de não-parecer-jurídico.
- [ ] `LICENSE` Apache-2.0 na raiz; NOTICE/doc de terceiros presente.
- [ ] Crates `kernel` / `runtime` / `node` / `agent` com `license` SPDX alinhado.
- [ ] Manifesto sem «a confirmar» na preferência de licenças; ponte à decisão.
- [ ] `architecture.md` sem «licenças» como decisão aberta; link à ADR.
- [ ] README avaliado e atualizado se a capa omitiria a licença.
- [ ] Sem código de produto além de metadados de licença nos `Cargo.toml`.

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| Escolher GPLv3 em um crate e Apache nos outros sem necessidade | Spec fixa Apache-2.0 em todos; desvio exige atualizar esta spec + ADR |
| Esquecer deps (llama.cpp) e parecer que o binário é «só Apache» | NOTICE/doc obrigatório nomeando deps relevantes |
| Reescrever manifesto além do trecho de licenças | Escopo: só política open source / frase a confirmar |
| Confundir pesos GGUF com código do projeto | ADR: uma linha de honestidade; `models/` gitignored |

Rollback: reverter commits da etapa; decisão volta a «aberta» em architecture até nova ADR.

## Etapa do roadmap

Etapa 17 — Licenças definitivas por componente (`em_andamento`, Issue [#17](https://github.com/eriksonlima/projeto-ia-livre/issues/17)).

**Pronto quando (roadmap):** licença por componente (kernel, runtime, node, agent, docs) registrada no repositório, alinhada ao manifesto.
