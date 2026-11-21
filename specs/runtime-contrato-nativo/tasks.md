# Tasks — Runtime falando o contrato nativo (além do proxy Linha B)

Uma task = uma fatia.

- [x] Task 1 — Spec/docs: contrato runtime↔kernel documentado + marcadores/harness esperados (honesto)
  - **Pronto quando:** existe `docs/runtime-contrato-nativo.md` (ou path equivalente fixado na fatia) descrevendo: (1) superfície alinhada ao ADR 0003 / desenho (`Weights`/`KvCache`, Prefill/Decode); (2) relação com marcadores E19 (`TYPED_*`, `PHASE=`, `QUANTUM=`, `MEM_SCHED_OK`) **sem** inventar ABI incompatível; (3) marcadores do consumidor/shim host (`CONTRACT_*` / `RUNTIME_CONTRACT_OK` — nomes canônicos fixados); (4) harness B: PROXY (E12) vs evidência de contrato; **proibição** de `TOKENS_PER_S` / fingir GGUF em B; (5) hipótese **não** comprovada; shim host **≠** Linha B; (6) dependência E19 e avanço seguro via stub. Pontes em `docs/desenho-memoria-scheduler-nativo.md`, `docs/runtime-nativo-linha-b.md`, `docs/harness-linha-a-b.md` (e doc E19 se já existir). `AGENTS.md` menciona a intenção. README avaliado (`readme-por-fatia`). Sem implementação do shim além do necessário para docs.
  - **Não bloqueada por B13.**

- [x] Task 2 — Runtime host (ou crate auxiliar) exerce o contrato via shim/stub
  - **Pronto quando:** há binário/módulo no workspace que: (1) chama alloc tipado Weights e KvCache e/ou `set_phase` Prefill→Decode via shim alinhado à Task 1; (2) emite os marcadores canônicos no stdout; (3) conclui com `IA_LIVRE_RUNTIME_CONTRACT_OK` (ou nome fixado); (4) é verificável **sem** QEMU e **sem** exigir kernel E19 mergeado; (5) não quebra builds/gates existentes do runtime GGUF. `AGENTS.md` → Como rodar atualizado; README reavaliado. Sem editar `kernel/`.
  - **Não bloqueada por B13** (usa stub/shim).

- [x] Task 3 — Integração harness B / docs honestas (PROXY vs contrato) + gate documentado
  - **Pronto quando:** (1) docs/scripts deixam explícito PROXY vs contrato; (2) **nenhum** caminho B emite `TOKENS_PER_S` falso; (3) existe gate documentado do contrato host (alvo sugerido `make verify-runtime-contract` / script dedicado) que exige os marcadores da Task 2; (4) `make verify-harness` **não** regride (A GGUF + B proxy); (5) se o gate QEMU de contrato ainda não existir, está documentado como dependente da Task 4 / E19 — sem skip mentiroso que finja sucesso nativo. `AGENTS.md` → Como verificar; README reavaliado.
  - **Não bloqueada por B13** para o gate host; caminho nativo QEMU continua fora desta task.

- [x] Task 4 — Integração nativa QEMU contra contrato real da Etapa 19
  - **Desbloqueada:** Etapa 19 `feita` em `origin/main` (`MEM_SCHED_OK` / `TYPED_*` observáveis).
  - **Pronto quando:** harness B observa serial pós-exit com evidência do contrato E19, reemite `HARNESS_CONTRACT_*` honestos, **preserva** proxy E12 (`LOAD_KIND=proxy`), **não** emite `TOKENS_PER_S`/`LOAD_S`/GGUF fingido; hipótese não comprovada; gates `make verify`, `make verify-runtime-contract`, `make verify-harness`; docs alinhadas; sem editar mecanismo E19 no `kernel/` além de pontes script/docs.
