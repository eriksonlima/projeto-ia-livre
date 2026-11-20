# Tasks — GPU manager no kernel / multi-GPU (desenho)

Uma task = uma fatia.

- [x] Task 1 — ADR do escopo candidato (GPU manager + multi-GPU + fronteira host)
  - **Pronto quando:** existe ADR nova (ex.: `docs/adr/0006-gpu-manager-multi-gpu.md`) com status aceita *no nível desenho*: delimita **host ADR 0002** (single-GPU llama.cpp) vs **GPU manager nativo** (mecanismos no kernel); define escopo mínimo do manager (**enumeração**, **afinidade** de memória/dispositivo, **hints de placement**); escolhe **pipeline/layer sharding** como estratégia multi-GPU preferida (tensor/expert/RDMA = futuro); afirma fronteira ADR 0001 (inferência fora do kernel) e complementaridade com ADR 0003; lista consequências e o que **não** fica decidido (implementação, ABI, driver in-kernel); rejeita tratar Etapa 8 como manager nativo. Sem código de produto. README avaliado (`readme-por-fatia`).
  - **Feito:** `docs/adr/0006-gpu-manager-multi-gpu.md`; README considerado (sem mudança — doc interna).

- [ ] Task 2 — Doc de desenho do GPU manager e multi-GPU
  - **Pronto quando:** `docs/desenho-gpu-manager-multi-gpu.md` (ou nome alinhado à ADR) descreve motivação vs offload host, tabela fronteira ADR 0002 × caminho nativo, contrato esboçado runtime→kernel (list_devices / alloc+affinity / placement + fase), ciclo com Prefill/Decode, estratégia pipeline/layer sharding e alternativas nomeadas, não-objetivos e itens para implementação futura; deixa explícito que `kernel/`/`runtime/` atuais **não** implementam o manager nem multi-GPU. Sem código de produto. README reavaliado.

- [ ] Task 3 — Pontes em architecture / ADR 0002 / métricas e fechamento documental
  - **Pronto quando:** `docs/architecture.md` marca GPU manager / multi-GPU como **decidido no nível desenho** (link ADR + doc), mantendo implementação e prova **abertas**; ponte mínima em `docs/adr/0002-aceleracao-gpu-host-llama-cpp.md` e/ou `docs/runtime-inferencia-gpu-metricas.md` (host ≠ manager nativo); ponte opcional em `docs/desenho-memoria-scheduler-nativo.md` se complementaridade com 0003 precisar ficar explícita; `AGENTS.md` aponta os docs se a estrutura pública precisar; README reavaliado; etapa pronta para revisão (não marcar `feita` aqui). Sem código de produto.
