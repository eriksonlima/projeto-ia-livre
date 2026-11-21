# Spec — Sincronizar architecture/product + glossário pós-E30

Etapa 42 · Issue [#41](https://github.com/eriksonlima/projeto-ia-livre/issues/41) (ex-B35)  
Depende: Etapas **30–41** feitas (artefato bare-metal, Linha B fatiada, harness, host GPU/autonomia/rede).

---

## Resultado visível

`docs/architecture.md`, `docs/product-context.md` e um **glossário canônico** descrevem o ecossistema **como está hoje** (pós-E41), sem linguagem de etapas antigas nem bloqueios superseded:

1. **Inventário honesto** — o que existe no host (`runtime/`, `node/`, `agent/`, gates E8/E25/E41) vs no kernel/QEMU (`kernel/`, `runtime-native/`, bare-metal, OBS E37, `GPU_MGR=native` E38).
2. **Linha A vs Linha B** — metodologia, veredito atual (`INCONCLUSIVO` / `E33_no_gguf_full_prefill_22L_kv_inviable`), bloqueio **atual** em B (`no_gguf_full_prefill`), e distinção clara: proxy ≠ geração ≠ `TOKENS_PER_S` fingido.
3. **QEMU vs hardware real** — gate `verify-baremetal` / artefato ESP ≠ corrida QEMU; metal = evidência manual + `BAREMETAL_SKIP` / `METAL_OK` (E35); GGUF na mídia (E36) opt-in.
4. **Glossário** — `docs/glossario.md` (novo): nomenclatura manifesto + termos operacionais estáveis (marcadores, perfis, identidades GPU, skip honesto).
5. **README** — pontes mínimas para contratos/gates novos **sem** duplicar `AGENTS.md`.
6. **`AGENTS.md`** — só se houver contradição factual com os docs canônicos (esta etapa é docs-first; gate existente permanece).

**Proibido nesta etapa:** código de produto; ADR novo cosmético; reescrever manifesto; declarar hipótese comprovada sem evidência; atualizar `TOKENS_PER_S` ou gates de implementação.

---

## Contexto fixo (não reinventar)

- Fonte de princípios: [`docs/manifesto.md`](../../docs/manifesto.md) — **não reescrever**.
- Brief operacional: [`AGENTS.md`](../../AGENTS.md) — fonte de gates/comandos; architecture/product **resumem e ponteam**, não substituem.
- Estado Linha B canônico nos contratos: [`docs/runtime-nativo-linha-b.md`](../../docs/runtime-nativo-linha-b.md), [`docs/harness-a-b-comparavel.md`](../../docs/harness-a-b-comparavel.md), specs E29–E33 (desfechos com `B_BLOCK`).
- Bare-metal: [`docs/boot-hardware-real.md`](../../docs/boot-hardware-real.md), [`docs/gguf-baremetal-midia.md`](../../docs/gguf-baremetal-midia.md).
- GPU: stub E25 ≠ nativo E38 ≠ shard executado E41 — contratos respectivos em `docs/`.
- Implementações **já entregues** que architecture ainda trata como «implementação aberta»: protocolo v1 (`node/`, E23), autonomia v1+`calc` (`agent/`, E24/E40), descoberta bootstrap (E39).

### Lacunas conhecidas (auditoria — corrigir na implementação)

| Área | Sintoma atual | Alvo pós-sync |
|------|----------------|---------------|
| `architecture.md` — decisões | Para em E26; E14/E15 «sem implementação» | Refletir E23–E41; «entregue no host/kernel» vs «aberto» |
| `architecture.md` — harness | `no_gguf_path` / sem geração em B como estado corrente | `no_gguf_full_prefill`; proxy+layout+layer0; comparable INCONCLUSIVO documentado |
| `architecture.md` — fronteira | Tabela «Etapa 3 atual» | Mapa **entregas por camada** ou índice Etapas 4–42 (ponte `ROADMAP.md`) |
| `product-context.md` | «Etapa 3 só documentação»; métricas 4→6 apenas | Entregáveis atuais; hipótese + gates; participação Rede sem SO |
| Glossário | inexistente | `docs/glossario.md` alinhado a manifesto + marcadores `IA_LIVRE_*` |
| README | não aponta shard host / autonomia além v1 / OBS nativa | Pontes curtas + link AGENTS |

---

## Conteúdo obrigatório

### 1. `docs/glossario.md` (criar)

Em português. Mínimo:

- Nomes oficiais (manifesto): Projeto IA Livre, IA Livre, Rede IA Livre.
- **Linha A** / **Linha B**; **harness**; **veredito** (`COMPROVA`/`REFUTA`/`INCONCLUSIVO`).
- **Proxy Linha B** vs **runtime-native** vs **host `runtime/`** (llama-cpp).
- **QEMU** vs **bare-metal** / **metal**; `BAREMETAL_SKIP`, `METAL_OK`.
- **`B_BLOCK`** e evolução honesta (`no_gguf_forward` → `no_gguf_generate` → `no_gguf_decode` → `no_gguf_full_prefill`) — estado **atual** destacado.
- GPU: `host_stub`, `host_shard_exec`, `GPU_MGR=native`; skip honesto (`*_SKIP`).
- **Não** virar dump de todos os marcadores — link para contratos em `AGENTS.md` / docs por componente.

### 2. `docs/architecture.md` (sincronizar in-place)

Preservar estrutura útil (camadas, hipótese, referências). Atualizar:

- **Decisões tomadas:** entregas E23–E41 com link ao contrato/doc gate (não só desenho).
- **Decisões abertas:** remover ou riscar ~~itens fechados~~; manter o que **ainda** é pesquisa (prova harness, geração 22L em B, multi-GPU completo, etc.).
- **Estado Linha B:** alinhar ao desfecho E33; ADR 0013 se relevante como ponte.
- **Bare-metal e OBS:** E30/E35/E36/E37 na visão de camada 1.
- **Fronteira Etapas 4+:** substituir tabela obsoleta por «Mapa de entregas» ou seção «Estado do roadmap (ponte)» apontando `ROADMAP.md` — sem reescrever o roadmap inteiro.

### 3. `docs/product-context.md` (sincronizar)

- Remover/redigir «fronteira desta etapa = Etapa 3».
- Atualizar **métricas de sucesso** e **hipótese** com instrumento comparable + bloqueio honesto atual.
- Tabela de camadas: valor entregue **hoje** (ex.: Rede v1+bootstrap sem SO; autonomia v1+tool sandboxed no host).
- Ponte para glossário e architecture.

### 4. `README.md` (pontes)

Avaliar rule `readme-por-fatia`: adicionar só links que evitem capa GitHub enganosa (ex.: bare-metal já existe; acrescentar shard host, glossário, autonomia além v1 se omitidos). **Sem** colar gates do `AGENTS.md`.

### 5. `AGENTS.md` (condicional)

Editar **somente** se contradição factual direta (ex.: architecture cita gate inexistente). Preferir corrigir architecture; AGENTS já é canônico para operação.

---

## Fora de escopo

- Código em `kernel/`, `runtime/`, `runtime-native/`, `node/`, `agent/`, scripts de gate (salvo typo em doc referenciado — preferir corrigir doc)
- Nova etapa no roadmap; issues GitHub; Memory Bank (outra fatia)
- Benchmarks, mudança de `B_BLOCK`, implementação de geração 22L
- ADR novo sem decisão estrutural nova
- Tradução EN; redesign visual dos docs
- Atualizar todos os contratos satélite (só pontear quando architecture mencionar; correção profunda de cada contrato é backlog futuro se necessário)

---

## Critérios de aceite

- [ ] `docs/glossario.md` existe, em português, com termos mínimos acima e links para manifesto/contratos
- [ ] `docs/architecture.md` não afirma «Etapa 3 atual», «implementação node/agent aberta» nem bloqueio B desatualizado como estado corrente sem qualificação histórica
- [ ] `docs/architecture.md` documenta entregas E30–E41 materialmente (bare-metal, Linha B fatiada, comparable, A otimizada, metal/GGUF mídia, OBS, GPU nativo stub, WAN bootstrap, calc sandbox, shard host)
- [ ] Distinção **QEMU vs metal** e **skip honesto** explícita onde bare-metal/GPU/multi-GPU aparecem
- [ ] `docs/product-context.md` alinhado ao estado pós-E41; sem fronteira «só Etapa 3»
- [ ] `README.md` avaliado; pontes adicionadas se necessário; sem duplicar operacional do `AGENTS.md`
- [ ] `AGENTS.md` intacto **ou** diff mínimo justificado por inconsistência factual (registrar na fatia)
- [ ] Nenhum código de produto alterado
- [ ] Verificação da spec (checklist + greps de regressão textual) documentada na última task

---

## Riscos e rollback

- **Risco:** architecture vira cópia do `ROADMAP.md` → usar mapa resumido + links; roadmap permanece fonte de status por etapa.
- **Risco:** glossário obsoleto amanhã → fixar termos **estáveis**; evolução fina fica nos contratos por etapa.
- **Risco:** contradizer `AGENTS.md` → em dúvida, AGENTS vence para operação; architecture cita AGENTS.
- **Risco:** apagar histórico útil → marcar superseded em uma linha (`no_gguf_forward` histórico) em vez de apagar specs/ADRs.
- **Rollback:** reverter `docs/glossario.md`, diffs em architecture/product/README; etapa permanece `em_andamento`.

---

## Etapa do roadmap

- Etapa 42 — Sincronizar architecture/product + glossário pós-E30 (`em_andamento`, Issue [#41](https://github.com/eriksonlima/projeto-ia-livre/issues/41))
- Pronto quando (roadmap): `architecture.md` / README-AGENTS refletem estado atual sem ambiguidade.