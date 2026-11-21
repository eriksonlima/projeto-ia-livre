# Spec — Definição verificável de “protótipo objetivo atingido” (Etapa 58)

Etapa 58 · Issue [#58](https://github.com/eriksonlima/projeto-ia-livre/issues/58) (ex-B52)  
Deps: B39 + B40 + B42 (mínimo) — cobertos por E44–E48 etc. (**feitas**).

---

## Resultado visível

Existe um **checklist canônico** em `docs/` que define, com critérios **verificáveis** e **estado atual honesto**, o que conta como “protótipo objetivo atingido” nas três frentes da meta:

1. **Hipótese A vs B** — decidível (`COMPROVA`/`REFUTA`) **ou** bloqueio honesto final documentado (hoje: instrumento existe; veredito **`INCONCLUSIVO`** por espécie subset em B).
2. **SO / USB metal** — boot ESP/USB em hardware com caminho de IA nativo mínimo **honesto** (artefato + guia + path metal; `METAL_OK` só com evidência real).
3. **Rede + autonomia host** — utilizáveis **sem** exigir o SO (`verify-node` / `verify-agent` verdes).

Espelho no `ROADMAP.md` e Memory Bank. Gate **opcional** confere presença do checklist + greps de marcadores-chave — **sem** fingir `COMPROVA` nem celebrar vitória indevida.

Esta etapa **define e espelha** o critério; **não** exige que as três frentes estejam todas “verdes de celebração” no momento do fechamento.

## Contexto fixo (não reinventar)

- Meta do protótipo: parágrafo em `BACKLOG.md` (Abertas / Promovidas) + `docs/product-context.md` / manifesto.
- Harness comparável: [`docs/harness-a-b-comparavel.md`](../../docs/harness-a-b-comparavel.md) — `VERDICT` ∈ {`COMPROVA`,`REFUTA`,`INCONCLUSIVO`}; `COMPROVA`/`REFUTA` só com espécie canônica (22L + `n_predict=32`); subset → **`INCONCLUSIVO`** (`E44_subset_generate_not_canonical_species_*` ou reason atual documentado).
- Boot metal: [`docs/boot-hardware-real.md`](../../docs/boot-hardware-real.md) — QEMU ≠ metal; `METAL_OK` só com log real; guia [`docs/guia-primeiro-boot-usb.md`](../../docs/guia-primeiro-boot-usb.md); path metal/SFS E48.
- Rede / autonomia: ADR [`0001`](../../docs/adr/0001-separacao-camadas-e-p2p.md); `make verify-node` / `make verify-agent` **independentes** do SO.
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: avaliar `README.md` em cada fatia.

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A** | Doc checklist único em `docs/` com três pilares + critérios grepáveis + **estado atual** (INCONCLUSIVO onde couber) + espelho ROADMAP/MB + gate opcional de presença/marcadores (sem exigir COMPROVA) | **Escolhida** |
| **B** | Declarar “objetivo atingido” agora porque E1–E57 existem | **Rejeitada** — celebração sem evidência; hipótese ainda INCONCLUSIVO |
| **C** | Exigir `COMPROVA` + `METAL_OK` no gate desta etapa para fechar | **Rejeitada** — inventaria vitória / bloqueia CI sem PC; conflita com “celebrar só com evidência” |
| **D** | Só texto no ROADMAP sem doc canônico nem gate | **Rejeitada** — não cumpre “checklist em docs/” + verificabilidade |
| **E** | Misturar meta com implementação de espécie canônica B ou novo boot metal | **Rejeitada** — fora; deps já cobertas; esta etapa é **definição** |

### Escolha: **A — checklist canônico + espelho + gate documental opcional**

| Peça | Nesta etapa |
|------|-------------|
| Checklist | Doc novo canônico (ex. `docs/prototipo-objetivo-atingido.md`) com: definição da meta; três pilares; para cada um — critério de “atingido”, comando/marcador de evidência, **estado atual** honesto, o que **não** conta |
| Hipótese | Estado atual = **`INCONCLUSIVO`** (geração subset em B ≠ espécie canônica); “decidível” = instrumento + regras de `COMPROVA`/`REFUTA` documentadas; bloqueio final só se explicitamente marcado como terminal |
| USB/metal | Critérios: artefato (`IMAGE_OK`) + caminho IA mínimo honesto (path metal/BlockIO documentado) + `METAL_OK` **quando** houver evidência; skip ≠ sucesso metal |
| Rede+autonomia | Critérios: `verify-node` + `verify-agent` verdes; ADR 0001; bridges ≠ substitutos |
| Celebração | Seção explícita: **proibido** declarar “objetivo atingido” / `COMPROVA` sem os critérios do checklist; verdades parciais ok |
| Espelho | `ROADMAP.md` (ponte/desfecho da etapa) + `memory-bank/activeContext.md` / `progress.md` apontando o checklist e o estado |
| Gate | Opcional: `make verify-prototipo-objetivo` (nome ajustável) — exige doc presente + greps de frases/marcadores-chave (ex. `INCONCLUSIVO`, pilares, `verify-node`/`verify-agent`, `METAL_OK` como critério — **não** exige corrida harness nem `COMPROVA`) |
| Glossário | Entrada curta “protótipo objetivo atingido” → checklist |

### Justificativa

- Fecha B52: critério auditável de “chegamos?” sem fraude de pesquisa.
- Estado atual honesto evita celebrar enquanto A/B for INCONCLUSIVO e metal depender de evidência.
- Gate leve torna o checklist regressável em CI sem hardware nem GGUF.

### Rejeitado (explícito)

- Declarar hipótese `COMPROVA`/`REFUTA` ou “objetivo atingido” sem cumprir o checklist.
- Inventar `TOKENS_PER_S` / `METAL_OK` / `NET_NATIVE_OK` no gate desta etapa.
- Exigir PC USB, QEMU harness comparable, ou GGUF no gate documental.
- Implementar espécie canônica 22L×32, novo loader, ou TCP no guest.
- Substituir `verify-node` / `verify-agent` por bridges.

## Fora de escopo

- Tornar B espécie canônica / mudar veredito harness.
- Nova evidência `METAL_OK` em PC físico nesta máquina.
- Mudanças em kernel, runtime, node, agent, harness (salvo greps/docs).
- Marketplace, Secure Boot assinado, multi-GPU como prova da meta.

## Critérios de aceite

- [ ] Existe `docs/prototipo-objetivo-atingido.md` (ou nome canônico equivalente) com os **três pilares**, critérios verificáveis (comandos/marcadores), e **estado atual** honesto (hipótese = `INCONCLUSIVO` onde aplicável).
- [ ] Seção “celebrar só com evidência”: o que falta para declarar objetivo atingido; proibições explícitas.
- [ ] Espelho no `ROADMAP.md` (Spec/ponte da Etapa 58) e Memory Bank (`activeContext` + `progress` apontam checklist + residual).
- [ ] Ponte curta a partir de glossário e/ou `product-context` / BACKLOG meta (sem duplicar manifesto).
- [ ] Gate opcional: presença do doc + greps de marcadores-chave; **não** exige `COMPROVA`; exit 0 sem USB/QEMU/GGUF (salvo se a impl. optar por só `test -f` + grep).
- [ ] AGENTS.md (Como verificar) documenta o gate se criado; README avaliado (`readme-por-fatia`).
- [ ] Gates existentes **não** regridem; nenhum texto da etapa afirma vitória indevida.

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| Checklist celebrar COMPROVA | Critério escrito + review; estado atual INCONCLUSIVO obrigatório |
| Gate exigir harness/metal | Proibido; só presença/greps documentais |
| Duplicar harness-a-b-comparavel | Checklist **aponta**; não redefine fórmulas R |
| Memory Bank desatualizar | Task dedicada de espelho no fechamento |
| Confundir “etapa feita” com “objetivo atingido” | Desfecho: definição entregue; meta global pode permanecer aberta |

Rollback: remover doc/gate novos; E1–E57 intactos.

## Etapa do roadmap

- Etapa 58 `em_andamento` — Definição verificável de “protótipo objetivo atingido”
- Issue: [#58](https://github.com/eriksonlima/projeto-ia-livre/issues/58)
- Pronto quando (roadmap): checklist em `docs/` (hipótese A/B decidível **ou** bloqueio honesto final; USB metal com boot+IA mínima; Rede+autonomia host verdes) + espelho no ROADMAP/Memory Bank; celebrar só com evidência.
