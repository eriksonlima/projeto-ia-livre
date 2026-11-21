# Spec — Perfil harness GPU espelhado A/B (quando B gerar)

Etapa 56 · Issue [#56](https://github.com/eriksonlima/projeto-ia-livre/issues/56) (ex-B50)  
Depende: geração B (B39 / E44 — `TOKENS_PER_S` **subset**); E8 (accel host); E18 (metodologia perfis).

---

## Resultado visível

Existe uma **corrida A/B com perfil GPU documentado** e métricas **honestas**:

1. **Linha A** — host com aceleração real (CUDA canônico / Vulkan alternativa, ADR 0002), mesma carga canônica do harness, marcadores `HARNESS_*` (≠ `INFER_*` da Etapa 8).
2. **Linha B** — espelho **documentado** da limitação guest: B já gera tokens **subset** (E44), **sem** GPU nativa no guest nesta etapa; **proibido** inventar `HARNESS_ACCEL=cuda|vulkan` ou `TOKENS_PER_S` fictícios em B.
3. **Gate opt-in** — prova a corrida perfil GPU **ou** skip honesto sem GPU; **não** substitui `make verify-harness` / `verify-harness-comparable` default.
4. **Veredito** — permanece `INCONCLUSIVO` enquanto espécie B ≠ canônica (22L×32) **ou** modos de aceleração A≠B; **proibido** `COMPROVA`/`REFUTA` com espécie errada ou GPU só de um lado.

A etapa fecha quando o perfil está documentado, a corrida A (GPU) + B (subset honesto) é verificável com skip, e `AGENTS.md` cobre o gate — sem fingir prova da hipótese.

---

## Contexto fixo (não reinventar)

- E18 / [`docs/harness-perfis-a-otimizada-gpu.md`](../../docs/harness-perfis-a-otimizada-gpu.md): metodologia A otimizada + **perfil GPU** como roadmap; GPU-B = medição futura sem inventar tokens no proxy.
- E8 / ADR 0002: accel host no runtime (`IA_LIVRE_ACCEL` / `--n-gpu-layers`); gate `verify-runtime-gpu` — **namespace distinto** do harness.
- E22 / [`docs/harness-a-b-comparavel.md`](../../docs/harness-a-b-comparavel.md): veredito; checklist exige **mesmo modo de aceleração** no par; subset E44 → `INCONCLUSIVO`.
- E34: `PROFILE=A_otimizada` + `make verify-harness-a-otimizada` — padrão de **gate opt-in** a espelhar (CPU).
- E44: B emite `LOAD_KIND=gguf` + `TOKENS_PER_S` medidos; espécie **subset** ≠ 22L×32.
- E55: `GPU_REAL` path host — **≠** perfil harness; não misturar marcadores `GPU_REAL_*` com `HARNESS_*`.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A — A GPU host + B espelho doc (limitação guest)** | Corrida: A com offload real; B com tokens subset + `ACCEL=cpu` (ou marcador explícito de assimetria); docs atualizam E18 de “futuro” → “executável assimétrico / espelho honesto” | **Escolhida** |
| **B — Exigir GPU nativa em B (PCI/pass-through)** | Espelho simétrico só com accel no guest | **Rejeitada nesta etapa** — E55 é detecção/placement, não offload GGUF guest; deps de B50 = geração, não GPU guest |
| **C — Inventar ACCEL/TOKENS GPU em B** | Marcadores espelhados sem hardware | **Rejeitada** — fraude |
| **D — Só documentação (como E18)** | Sem runner/gate | **Rejeitada** — Pronto quando pede corrida + skip |
| **E — Gate default obrigatório** | Substituir `verify-harness` / comparable | **Rejeitada** — CI sem GPU; padrão E34 opt-in |
| **F — COMPROVA/REFUTA com A GPU vs B CPU/subset** | Veredito decisivo | **Rejeitada** — checklist de comparabilidade (mesmo accel + espécie canônica) falha → só `INCONCLUSIVO` |

### Escolha: **A — perfil GPU assimétrico documentado; gate opt-in com skip**

| Peça | Nesta etapa |
|------|-------------|
| A | Host: build feature `cuda`/`vulkan` + `--n-gpu-layers` > 0; carga canônica; `HARNESS_LINE=A` + `HARNESS_ACCEL=cuda\|vulkan` + load/tokens; perfil nomeado (ex. `A_gpu` / `PROFILE=A_gpu` — fixar na Task 1) |
| B | Guest/QEMU: reutilizar geração subset existente; `HARNESS_ACCEL=cpu` (ou `none`); **não** emitir accel GPU; tokens **medidos** subset ok; documentar assimetria |
| Espelho | Doc: o que “espelhado” significa agora = **mesmo modelo/prompt/n_predict** + relatório lado a lado + **limites honestos** (accel A≠B; espécie B subset) — **não** igualdade de acelerador |
| Skip | Sem GPU / CI: `IA_LIVRE_HARNESS_GPU_SKIP` (ou equivalente fixado) exit **0**; **sem** fingir `HARNESS_OK` GPU |
| Gate | **Novo opt-in** `make verify-harness-gpu` (nome fixado na Task 1); **não** substitui `verify-harness` / `verify-harness-comparable` / `verify-harness-a-otimizada` |
| Comparable | Se integrar perfil GPU no agregador: veredito **obrigatório** `INCONCLUSIVO` com reason grepável (assimetria accel e/ou subset); **falha** se emitir `COMPROVA`/`REFUTA` |
| Anti-fraude | Gate falha se `TOKENS` inventados em B; se `ACCEL` GPU em B sem caminho real; se sucesso GPU sem evidência host |

### Justificativa

- B50 / Pronto quando: “quando B gerar” — E44 já gera subset; fecha a corrida **sem** esperar GPU guest.
- E18 já previu A host possível hoje e B condicionado a acelerador real — esta etapa **executa A** e **atualiza o espelho B** para o estado pós-geração subset.
- Preserva honestidade do instrumento comparável (E22): assimetria de accel + espécie subset → `INCONCLUSIVO`.

### Rejeitado (explícito)

- Fingir GPU / `TOKENS_PER_S` em B.
- Declarar hipótese comprovada/refutada com A GPU vs B CPU/subset.
- Exigir pass-through / offload nativo em B.
- Tornar o gate GPU default no CI.
- Confundir com E8 (`INFER_*`), E55 (`GPU_REAL_*`) ou A_otimizada (CPU).

---

## Conteúdo obrigatório

### 1. Documentação

- Atualizar [`docs/harness-perfis-a-otimizada-gpu.md`](../../docs/harness-perfis-a-otimizada-gpu.md): perfil GPU **executável** (A); espelho B = assimétrico / limitação guest; marcadores; skip; ponte E44 subset.
- Ponte em [`docs/harness-a-b-comparavel.md`](../../docs/harness-a-b-comparavel.md): perfil GPU → `INCONCLUSIVO` até espécie canônica **e** mesmo accel.
- Ponte curta em harness v1 / runtime-nativo se necessário.
- `AGENTS.md`: Como rodar / Como verificar o gate opt-in.

### 2. Implementação mínima

- Runner A GPU (script novo ou extensão documentada de `run-harness-line-a.sh` com feature + `n-gpu-layers` > 0) emitindo `HARNESS_*` + `ACCEL` ≠ `cpu`.
- Agregação A/B (script dedicado ou estágio) que inclui B subset **sem** alterar métricas B inventadas.
- Skip path sem GPU (espelhar padrão `VERIFY_RUNTIME_GPU_SKIP` / `nvidia-smi`).

### 3. Gate

- `make verify-harness-gpu` (nome na Task 1).
- Com GPU: A com `ACCEL` ≠ `cpu` + métricas; B com tokens subset honestos + accel não-fingido; `HARNESS_OK` (ou marcadores dedicados) conforme contrato.
- Sem GPU: skip exit 0.
- Regressão: `verify-harness`, `verify-harness-comparable`, `verify-harness-a-otimizada`, `verify-runtime-gpu` sem mudança de semântica default.

---

## Fora de escopo

- GPU / offload GGUF no guest (PCI, CUDA in-kernel, pass-through como requisito).
- Espécie canônica 22L×32 em B (continua E44 subset → comparable `INCONCLUSIVO`).
- Multi-GPU / GPU manager (E25/E38/E41/E55 intocados como critério).
- Substituir gates harness v1 / comparable / A_otimizada.
- Mudanças em `node/`, `agent/`, kernel além do necessário para não regressar B.

---

## Critérios de aceite

- [ ] Doc E18 atualizada: perfil GPU A executável + espelho B honesto (assimetria / subset).
- [ ] Corrida verificável: A GPU real **ou** skip; B sem tokens/accel inventados.
- [ ] Gate opt-in documentado em `AGENTS.md`; verde com GPU e com skip.
- [ ] Comparable / docs: sem `COMPROVA`/`REFUTA` sob assimetria ou espécie subset.
- [ ] Sem regressão dos gates harness/runtime GPU existentes.
- [ ] README avaliado (`readme-por-fatia`).

---

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| Confundir E8 `INFER_*` com harness | Namespace `HARNESS_*` + docs |
| Veredito falso COMPROVA | Gate/docs forçam `INCONCLUSIVO` + anti-fraude |
| CI sem GPU quebra | Skip exit 0 (padrão E8/E34) |
| Inventar GPU em B | Contrato + greps no verify |

Rollback: remover runner/gate E56; restaurar doc E18 “GPU-B = roadmap”; gates v1 intactos.

---

## Etapa do roadmap

Etapa 56 — Perfil harness GPU espelhado A/B (quando B gerar)  
Issue: [#56](https://github.com/eriksonlima/projeto-ia-livre/issues/56)  
Status roadmap: `em_andamento`  
Pronto quando: corrida A/B com perfil GPU documentado e métricas honestas; skip se sem GPU; deps geração em B.  
Spec: `specs/harness-perfil-gpu-ab/`
