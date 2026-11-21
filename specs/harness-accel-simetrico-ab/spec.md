# Spec — Accel GPU simétrica A/B no harness

Etapa 64 · Issue [#73](https://github.com/eriksonlima/projeto-ia-livre/issues/73) (ex-B59)  
Depende: E56 (`make verify-harness-gpu` = A_gpu + B CPU subset → `INCONCLUSIVO` por assimetria); E22 (comparável); ADR [`0022`](../../docs/adr/0022-bloqueio-final-hipotese-ab.md) (pilar 1 = `BLOQUEIO_FINAL`).

---

## Resultado visível

Existe uma **corrida A/B com o mesmo perfil de aceleração documentado**, verificável e honesta:

1. **Perfil simétrico CPU (`sym_cpu`)** — A e B com `HARNESS_ACCEL=cpu` (ou equivalente documentado), mesma carga canônica onde couber, gate opt-in verificável.
2. **Simetria GPU** — **inviável** no QEMU guest atual (sem device GPU / sem passthrough). ADR nova (ex. **0023**) declara isso até B60 (PCI passthrough); o caminho E56 (`A_gpu` + B CPU) permanece **assimétrico** com veredito/reason honestos (`INCONCLUSIVO` / assimetria), **não** como “simetria GPU”.
3. **Anti-fraude** — **proibido** emitir `HARNESS_ACCEL=cuda|vulkan` na Linha B sem device real no guest; **proibido** `COMPROVA` fabricado; skip sem GPU no caminho GPU (E56) preservado.
4. **Pilar 1** — permanece `BLOQUEIO_FINAL` (ADR 0022). Esta etapa **não** busca `COMPROVA` nem espécie canônica.

A etapa fecha quando `sym_cpu` é corrida verificável **e** a inviabilidade da simetria GPU (até B60) está em ADR + docs/gate alinhados — sem fingir accel em B.

---

## Contexto fixo (não reinventar)

- E56 / [`docs/harness-perfis-a-otimizada-gpu.md`](../../docs/harness-perfis-a-otimizada-gpu.md): `A_gpu` executável; B espelho **assimétrico**; `make verify-harness-gpu`; skip sem GPU; **proibido** ACCEL fingido em B.
- E22 / [`docs/harness-a-b-comparavel.md`](../../docs/harness-a-b-comparavel.md): checklist exige **mesmo modo de aceleração** no par para veredito decisivo; assimetria → `INCONCLUSIVO`.
- E44: B gera subset (`LOAD_KIND=gguf`, `TOKENS_PER_S` medidos); espécie ≠ 22L×32.
- ADR 0022: pilar 1 = `BLOQUEIO_FINAL`; reabertura só com critérios da ADR.
- Backlog **B60**: GPU real no guest (PCI/pass-through) — **fora** desta etapa.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A — `sym_cpu` verificável + ADR “GPU simétrica inviável até B60”** | Fecha Pronto quando com par A/B **mesmo** accel (CPU); documenta que simetria GPU exige passthrough; atualiza E56 como caminho **assimétrico** honesto (não “simétrico GPU”) | **Escolhida** |
| **B — Exigir GPU simétrica agora (passthrough em B)** | Ambos GPU reais no par | **Rejeitada nesta etapa** — B60 ainda no backlog; QEMU guest sem GPU |
| **C — Emitir `ACCEL=cuda/vulkan` em B sem device** | “Simetria” só de marcador | **Rejeitada** — fraude |
| **D — Só docs, sem gate `sym_cpu`** | ADR + texto, sem corrida | **Rejeitada** — Pronto quando pede corrida verificável |
| **E — Tratar E56 como simetria GPU** | Renomear A_gpu+B CPU como simétrico | **Rejeitada** — mentira metodológica |
| **F — Buscar `COMPROVA` via perfil accel** | Veredito decisivo | **Rejeitada** — ADR 0022 + espécie subset |

### Escolha: **A — perfil `sym_cpu` + ADR de inviabilidade GPU simétrica**

| Peça | Nesta etapa |
|------|-------------|
| `sym_cpu` | Corrida A+B com **mesmo** accel CPU documentado; marcadores `HARNESS_*` + `HARNESS_ACCEL=cpu` em **ambos**; perfil nomeado `sym_cpu` (fixar na Task 1) |
| GPU simétrica | ADR **0023** (número fixado na Task 1 se livre): **inviável** até guest com device real (B60); reabertura só com passthrough/evidência |
| E56 / `verify-harness-gpu` | Permanece opt-in; docs/gate deixam explícito: **assimetria** A_gpu vs B CPU → `INCONCLUSIVO` + reason grepável de assimetria (atualizar se o reason atual for genérico demais); **não** rebrand como simétrico |
| Skip | Sem GPU no caminho GPU: `HARNESS_GPU_SKIP` / `VERIFY_HARNESS_GPU_SKIP` exit **0** (já E56); `sym_cpu` **não** depende de GPU |
| Anti-fraude | Gate falha se B emitir `ACCEL=cuda\|vulkan` sem device; falha se `COMPROVA`/`REFUTA` sob assimetria accel ou espécie subset |
| Gates default | `verify-harness` / `verify-harness-comparable` **não** substituídos |

### Justificativa

- Pronto quando exige **mesmo** perfil accel (ambos GPU **ou** ambos CPU). Com B sem GPU guest, só **ambos CPU** é realizável agora.
- ADR explícita evita que leitores interpretem E56 como “simetria GPU” ou cobrem ACCEL fingido em B.
- B60 fica o caminho legítimo para reabrir simetria GPU — sem inventar etapa de passthrough aqui.
- Pilar 1 / ADR 0022 intactos: veredito tipicamente `INCONCLUSIVO`; ≠ `COMPROVA`.

### Rejeitado (explícito)

- PCI passthrough / GPU guest real (B60).
- `HARNESS_ACCEL=cuda|vulkan` em B sem device.
- `COMPROVA` / espécie canônica / reabrir ADR 0022.
- `METAL_OK` fabricado.
- Substituir gates harness v1 / comparable default.

---

## Conteúdo obrigatório

### 1. Documentação + ADR

- ADR nova (ex. `docs/adr/0023-simetria-gpu-harness-inviavel.md`): simetria GPU A/B inviável até passthrough (B60); `sym_cpu` = perfil simétrico atual; E56 = assimétrico honesto.
- Atualizar [`docs/harness-perfis-a-otimizada-gpu.md`](../../docs/harness-perfis-a-otimizada-gpu.md): seção `sym_cpu` + distinção clara vs `A_gpu` assimétrico.
- Ponte em [`docs/harness-a-b-comparavel.md`](../../docs/harness-a-b-comparavel.md): mesmo accel ↔ `sym_cpu`; assimetria GPU → `INCONCLUSIVO` (reason); sem `COMPROVA`.
- Glossário / ponte curta se necessário.

### 2. Implementação mínima

- Runner/agregação do perfil `sym_cpu` (script novo ou estágio documentado) emitindo A e B com `ACCEL=cpu`.
- Ajuste do caminho E56 (docs + verify): reason/marcadores de **assimetria** explícitos; **nunca** ACCEL GPU em B.
- Skip GPU (E56) preservado.

### 3. Gate

- Gate opt-in para `sym_cpu` (nome fixado na Task 1 — ex. `make verify-harness-sym-cpu` **ou** estágio documentado sob target existente, desde que grepável).
- `make verify-harness-gpu` continua: skip sem GPU **ou** A_gpu + B sem ACCEL fingido + `INCONCLUSIVO` (assimetria).
- `AGENTS.md`: Como rodar / Como verificar.
- Regressão: `verify-harness`, `verify-harness-comparable`, `verify-harness-gpu` (semântica default).

---

## Fora de escopo

- PCI passthrough / GPU no guest (B60).
- Fingir `ACCEL` GPU em B.
- `COMPROVA` / espécie canônica 22L×32 / reabrir ADR 0022.
- `METAL_OK` / boot metal.
- Multi-GPU / GPU manager nativo como requisito.
- Mudanças em `node/`, `agent/`, kernel além do necessário para não regressar B.

---

## Critérios de aceite

- [ ] Perfil `sym_cpu` documentado e corrida A/B com **mesmo** accel CPU verificável.
- [ ] ADR (ex. 0023): simetria GPU inviável até B60; E56 = assimétrico, não simétrico.
- [ ] Skip sem GPU no caminho GPU; **proibido** `ACCEL` fingido em B (gate falha se violar).
- [ ] Veredito honesto (`INCONCLUSIVO` / assimetria); **≠** `COMPROVA` fabricado.
- [ ] `AGENTS.md` cobre gates; regressões harness intactas.
- [ ] README avaliado (`readme-por-fatia`).

---

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| Confundir E56 com simetria GPU | ADR 0023 + docs explícitas “assimétrico” |
| Fingir ACCEL em B “para fechar” | Greps anti-fraude no verify |
| Leitor esperar COMPROVA | ADR 0022 + reason INCONCLUSIVO |
| Duplicar gate sem valor | Preferir um target `sym_cpu` claro; não substituir v1 |

Rollback: remover runner/gate `sym_cpu` e ADR 0023; restaurar docs E56; gates v1/GPU intactos.

---

## Etapa do roadmap

Etapa 64 — Accel GPU simétrica A/B no harness  
Issue: [#73](https://github.com/eriksonlima/projeto-ia-livre/issues/73)  
Status roadmap: `em_andamento`  
Pronto quando: corrida A/B com o **mesmo** perfil de aceleração (ambos GPU ou ambos CPU documentado); skip sem GPU; **proibido** `ACCEL` fingido em B; veredito honesto (tipicamente `INCONCLUSIVO` até espécie/GPU guest); ≠ `COMPROVA` fabricado.  
Spec: `specs/harness-accel-simetrico-ab/`
