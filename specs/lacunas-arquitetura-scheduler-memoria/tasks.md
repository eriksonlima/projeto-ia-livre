# Tasks — Lacunas de arquitetura (scheduler / memória model-aware)

Uma task = uma fatia.

- [x] Task 1 — ADR da proposta candidata (classes de memória + hints de fase)
  - **Pronto quando:** existe ADR nova (ex.: `docs/adr/0003-memoria-model-aware-e-scheduler-fases.md`) com status aceita *no nível desenho*: decide a interface kernel↔runtime com classes mínimas `Weights` e `KvCache` e hints de scheduler `Prefill` / `Decode` (opcional `Idle`/`Load`); afirma fronteira ADR 0001 (inferência fora do kernel); lista consequências e o que **não** fica decidido (implementação, ABI, GPU manager); rejeita inferência no núcleo e cópia de SLM-OS/TensorOS/AgentOS como blueprint. Sem código de produto. README avaliado (`readme-por-fatia`).
  - **Feito:** ADR 0003; README considerado (sem mudança).

- [x] Task 2 — Doc de desenho do mecanismo nativo candidato
  - **Pronto quando:** `docs/desenho-memoria-scheduler-nativo.md` (ou nome alinhado à ADR) descreve motivação vs Linha A, ciclo de vida load→prefill→decode, contrato esboçado runtime→kernel, políticas candidatas do scheduler, não-objetivos e itens para implementação futura; inclui notas curtas de lacuna (SLM-OS, TensorOS, AgentOS) sem blueprint; deixa explícito que o proxy Linha B atual **não** implementa o contrato. Sem código de produto. README reavaliado.
  - **Feito:** doc completo; README considerado.

- [x] Task 3 — Pontes em architecture / harness e fechamento documental
  - **Pronto quando:** `docs/architecture.md` marca o desenho fino de memória/scheduler como **decidido no nível desenho** (link ADR + doc), mantendo a hipótese de pesquisa **não** comprovada; ponte mínima em `docs/runtime-nativo-linha-b.md` e/ou `docs/harness-linha-a-b.md` (desenho ≠ implementação ≠ prova); `AGENTS.md` aponta os docs se a estrutura pública precisar; README reavaliado; etapa pronta para revisão (não marcar `feita` aqui). Sem código de produto.
  - **Feito:** pontes + AGENTS; README considerado.
