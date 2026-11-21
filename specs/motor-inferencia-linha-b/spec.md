# Spec — Motor de inferência GGUF mínimo na Linha B

## Resultado visível

Geração **mínima** na Linha B (QEMU / IA Livre) com a carga canônica, emitindo `TOKENS_PER_S` / `LOAD_S` **medidos** comparáveis em espécie aos da Linha A; harness B + comparable atualizados **sem inventar números**; fronteira ADR 0001 respeitada (runtime nativo **fora** do kernel); **ou** bloqueio honesto **novo** documentado (ex. `B_BLOCK=no_gguf_forward`) com avanço intermediário verificável.

Preferência da etapa: **desbloquear tokens reais em B**. Bloqueio novo só se, após o desenho (Task 1) e o caminho de forward (Task 2), a geração mínima for inviável no prazo — nunca como atalho para fechar com números falsos.

## Contexto fixo (não reinventar)

- Etapa 27 **feita**: GGUF canônico (~638 MiB) na RAM via BlockIO; `GGUF_NATIVE_LOADER=blockio_full`; `GGUF_STATUS=tensors_stub_ok`; `B_BLOCK=no_gguf_infer_engine` — parse stub; **sem motor**. ADR [`0009`](../../docs/adr/0009-inferencia-linha-b-fatia-minima.md).
- Etapa 28 **feita**: protocolo corrida quieta; `VERDICT=INCONCLUSIVO` enquanto sem motor B. Doc: [`docs/harness-corrida-quieta.md`](../../docs/harness-corrida-quieta.md).
- Contrato Linha B: [`docs/runtime-nativo-linha-b.md`](../../docs/runtime-nativo-linha-b.md) — proxy E12 + contrato E19/E20 + loader BlockIO E26/E27.
- Memória tipada: [`docs/memoria-scheduler-impl-minima.md`](../../docs/memoria-scheduler-impl-minima.md) — `Weights` / `KvCache` + Prefill/Decode.
- Linha A (referência de espécie, **não** é B): `runtime/` + llama-cpp-2 host; `TOKENS_PER_S` / `LOAD_S` reais; prompt e n-predict canônicos.
- ADR [`0001`](../../docs/adr/0001-separacao-camadas-e-p2p.md): inferência **fora** do kernel — **proibido** engessar llama.cpp (ou motor completo) como produto dentro de `kernel/src/main.rs`.
- Infra QEMU atual: `-m 1536M`; disco raw `build/gguf-canon.gguf`; ESP com prefixo/`model.gguf.sz`.
- Hipótese A vs B: ainda **INCONCLUSIVO** até B emitir tokens em espécie (ou evidência que permita `REFUTA` honesta — fora do desejo desta etapa).
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`; se não precisar, registrar.

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A** | Crate `no_std` / freestanding separada (ex. `runtime-native/` ou `infer-engine/`) chamada pelo kernel **pós-ExitBoot**; consome buffer GGUF / `Weights`+`KvCache`; escopo TinyLlama Q4_K_M + prompt canônico + `n-predict=32` CPU | **Escolhida** |
| **B** | Portar / embutir llama.cpp (ou binding) **dentro** de `kernel/src/main.rs` como produto | **Rejeitada** — viola ADR 0001 |
| **C** | Rotular microbench E12 / tipado E19 como `TOKENS_PER_S` TinyLlama / `LOAD_KIND=gguf` | **Rejeitada** — fraude de espécie |
| **D** | Contar corrida host `ia-livre-runtime` como progresso de B | **Rejeitada** — fraude de ambiente |
| **E** | Só renomear `no_gguf_infer_engine` sem crate/código intermediário | **Rejeitada como desfecho único** — sem avanço verificável |

### Escolha: **A — crate freestanding + chamada pós-ExitBoot**

| Peça | Escolha nesta etapa |
|------|---------------------|
| Fronteira | Kernel = orquestração (loader BlockIO já feito, alloc tipado E19, serial); **motor** = crate separada `no_std`/`freestanding` no workspace |
| Nome sugerido | `runtime-native/` (crate `ia-livre-runtime-native`) **ou** `infer-engine/` — fixar na Task 1 / ADR 0010 |
| Chamada | Kernel pós-ExitBoot (após loader/`tensors_stub` + contrato tipado) invoca API mínima da crate; **não** vira monolito em `main.rs` |
| Escopo modelo | TinyLlama 1.1B Chat v1.0 **Q4_K_M** (GGUF já em RAM via BlockIO) |
| Prompt | `Complete em uma frase: O Projeto IA Livre é` |
| `n-predict` | `32` |
| Aceleração | **CPU** apenas (`ACCEL=cpu`); sem GPU nativa |
| Parse | Evoluir stub E27 → layout/tensores suficientes para forward (ou documentar lacuna honesta) |
| Forward | Prefill + Decode mínimos alinhados ao contrato E19 (consumir `Weights`/`KvCache` / phases) — alterar E19 **só** o necessário para o motor consumir |
| Métricas | `LOAD_S` / `TOKENS_PER_S` **só** se medidos no guest na carga canônica |
| `LOAD_KIND` | `gguf` **só** com geração real; senão permanece `proxy` + bloqueio residual |
| Bloqueio residual (se inviável) | Novo motivo documentado (ex. `B_BLOCK=no_gguf_forward`) — **não** fingir tokens; preferência é tentar geração |
| Hipótese | Pode sair de `INCONCLUSIVO` **somente** com métricas B reais em espécie; **proibido** forçar `COMPROVA` sem evidência |
| ADR | **0010** (sugerido): crate freestanding; rejeição B/C/D; escopo mínimo; relação com 0001/0009 |

### Justificativa

- E27 deixou explícito que o bloqueio é o **motor**, não o path do arquivo.
- ADR 0001 exige runtime fora do kernel: crate separada chamada pelo guest é a fronteira auditável.
- Portar llama.cpp inteiro no EFI é multi-etapa e conflita com “mínimo”; o mínimo desta etapa é **geração canônica medível** (ou bloqueio novo mais preciso que `no_gguf_infer_engine`).
- Inventar tokens (C) ou host-as-B (D) destruiria o harness comparável e a hipótese.

### Rejeitado (explícito)

- Inventar `TOKENS_PER_S` / `LOAD_S` / `LOAD_KIND=gguf` / `MODEL=` TinyLlama sem geração medida no guest.
- Microbench tipado ou proxy rotulado como tokens canônicos.
- Engessar llama.cpp / motor completo como produto em `kernel/src/main.rs`.
- Contar Linha A / host runtime como evidência de B.
- Forçar `COMPROVA` / `REFUTA` sem métricas B em espécie.
- Bare-metal / USB (B24), GPU manager nativo, multi-GPU.
- Alterar contratos E19 demo além do necessário para o motor consumir `Weights`/`KvCache`.
- Trocar a carga canônica da Linha A.

### Carga canônica (igual à Linha A)

| Item | Valor |
|------|--------|
| Modelo | TinyLlama 1.1B Chat v1.0 |
| Quantização | Q4_K_M (GGUF) |
| Arquivo | `models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf` (guest: `build/gguf-canon.gguf` / BlockIO) |
| Prompt | `Complete em uma frase: O Projeto IA Livre é` |
| `--n-predict` / `N_PREDICT` | `32` |
| Aceleração | CPU |

### Contrato de marcadores (evolução)

Namespace kernel (serial COM1) + reemissão harness `IA_LIVRE_HARNESS_*`.

#### Sucesso com geração mínima (caminho preferido)

| Marcador (kernel e/ou harness) | Significado |
|--------------------------------|-------------|
| Evidência do motor nativo | Marcador de crate/engine (ex. `NATIVE_INFER_BEGIN` / `RUNTIME_NATIVE_OK` — nome fixado na Task 1) |
| `LOAD_KIND=gguf` | Geração real no guest |
| `MODEL=` | Arquivo / id TinyLlama canônico |
| `N_PREDICT=32` | Igual à A |
| `LOAD_S=` / `TOKENS_PER_S=` | **Medidos** no guest (não inventados; não do proxy) |
| `ACCEL=cpu` | Sem GPU nativa |
| `B_BLOCK` | **Omitido** ou motivo residual só se ainda houver lacuna honesta **além** da geração |
| Proxy E12 | Pode permanecer como evidência lateral **ou** deixar de ser o `LOAD_KIND` principal quando `gguf` existir — documentar na Task 1 |

#### Bloqueio honesto novo (caminho de fallback)

| Marcador | Significado |
|----------|-------------|
| Avanço intermediário | Parse/layout/forward parcial com marcadores honestos (ex. `GGUF_STATUS=layout_ok` / `FORWARD_STUB_OK`) |
| `B_BLOCK=` | Motivo **novo** (ex. `no_gguf_forward`) — não reutilizar `no_gguf_infer_engine` se o bloqueio mudou de natureza |
| `TOKENS_PER_S` / `LOAD_S` / `LOAD_KIND=gguf` | **Proibidos** |
| Veredito comparável | Continua `INCONCLUSIVO` |

#### Preservado / proibido

| Item | Regra |
|------|--------|
| Loader E26/E27 | `blockio_full` + artefato raw preservados |
| Contrato E19/E20 | `HARNESS_CONTRACT_*` / `CONTRACT_READY=1` preservados; E19 só ajustado se o motor precisar consumir tipados |
| ADR 0001 | Motor **não** vira produto no `main.rs` do kernel |
| Fraude | Sem tokens inventados; sem host-as-B; sem microbench-as-GGUF |

### Relação com o gate atual

- Hoje: harness B exige `GGUF_NATIVE_LOADER=blockio_full`, `GGUF_STATUS=tensors_stub_ok`, `B_BLOCK=no_gguf_infer_engine`, **sem** `TOKENS_PER_S`; comparable → `INCONCLUSIVO`.
- Com geração: gate **passa** a exigir `LOAD_KIND=gguf` + `LOAD_S` / `TOKENS_PER_S` medidos + ausência de fraude; comparable pode emitir `COMPROVA`/`REFUTA`/`INCONCLUSIVO` **só** com regras honestas (não forçar `COMPROVA`).
- Com bloqueio novo: gate exige marcadores intermediários + `B_BLOCK=<novo>`; comparable permanece `INCONCLUSIVO`; **continua** rejeitando tokens inventados.
- Timeouts: forward TinyLlama em QEMU pode exigir `VERIFY_*_TIMEOUT` maior — documentar.

## Conteúdo obrigatório

### 1. ADR 0010 + documentação de desenho (Task 1)

- ADR [`docs/adr/0010-….md`](../../docs/adr/): crate freestanding; API mínima; rejeição B/C/D; escopo TinyLlama; relação 0001/0009.
- Doc de desenho (ex. `docs/desenho-motor-inferencia-linha-b.md` **ou** seção Etapa 29 em `runtime-nativo-linha-b.md`): fronteira kernel×crate, fluxo pós-ExitBoot, marcadores, critério sucesso vs bloqueio novo.
- Pontes: `harness-linha-a-b.md`, `harness-a-b-comparavel.md`, `harness-corrida-quieta.md` (texto do slot B / veredito).
- `AGENTS.md`: Como rodar/verificar o estado alvo; README avaliar (`readme-por-fatia`).

### 2. Crate + parse/layout + wire pós-ExitBoot (Task 2)

- Novo membro do workspace (`runtime-native/` ou nome fixado); `no_std` / freestanding; API mínima documentada.
- Kernel: chamar a crate após loader/contrato; **sem** engrossar o produto no `main.rs` além do glue.
- Evoluir parse stub → layout/tensores / seed tipado honesto o suficiente para forward (ou falha serial clara).
- Sem emitir `TOKENS_PER_S` nesta task se ainda não houver geração.

### 3. Geração mínima canônica **ou** bloqueio novo (Task 3)

- Preferência: Prefill+Decode + sampling mínimo → ≥1 token gerado com caminho a 32 predict documentado; evidência serial de geração.
- Se inviável após Task 1–2: `B_BLOCK` novo (ex. `no_gguf_forward`) + marcadores intermediários verificáveis; **zero** tokens inventados.
- Critério de “inviável” deve estar escrito na Task 1 (ex.: ausência de tokenizer/dequant/matmul mínima no prazo sem fraude).

### 4. Métricas + harness B + comparable (Task 4)

- Se geração: emitir `LOAD_S` / `TOKENS_PER_S` medidos; `LOAD_KIND=gguf`; atualizar `run-harness-line-b.sh`, `verify-harness`, comparable / quiet protocol.
- Se bloqueio: gates exigem bloqueio novo + intermediários; comparable `INCONCLUSIVO`; sem `TOKENS_PER_S`.
- Docs/`AGENTS.md` finais alinhados ao desfecho real.

## Fora de escopo

- Bare-metal / USB boot (B24)
- GPU manager nativo / CUDA / Vulkan no guest
- Forçar `COMPROVA` sem métricas B reais
- Alterar contratos E19 demo além do necessário para o motor consumir `Weights`/`KvCache`
- Port completo de llama.cpp como produto no kernel
- libp2p / mudanças em `node/`
- Autonomy / mudanças em `agent/` (exceto se consumir métricas — não nesta etapa)
- Trocar carga canônica da Linha A
- Filesystem maduro / multi-tenant / ABI estável além do glue mínimo

## Critérios de aceite

- [ ] ADR 0010 + doc de desenho: crate freestanding; ADR 0001 respeitado; rejeições B/C/D explícitas
- [ ] Crate no workspace chamada pós-ExitBoot; glue de kernel mínimo
- [ ] **Ou** geração mínima canônica com `LOAD_S` / `TOKENS_PER_S` **medidos** e `LOAD_KIND=gguf` **ou** bloqueio honesto **novo** com intermediários verificáveis
- [ ] Harness B + comparable atualizados sem inventar números
- [ ] Loader E26/E27 e contrato E19/E20 preservados onde couber
- [ ] Hipótese só muda de `INCONCLUSIVO` com evidência real em espécie
- [ ] `AGENTS.md` cobre o cenário; README avaliado
- [ ] Etapa pronta para o agente principal marcar `feita` após gate + revisor

## Riscos e rollback

- **Risco:** motor TinyLlama Q4_K_M em `no_std` maior que uma etapa → fatiar: Tasks 1–2 + bloqueio novo na 3; tokens ficam para etapa futura **só** se o bloqueio for honesto e intermediário for real.
- **Risco:** pressão por `COMPROVA` / tokens → regra dura: sem geração medida = sem `TOKENS_PER_S` / sem `LOAD_KIND=gguf`.
- **Risco:** violações ADR 0001 (código de motor no `main.rs`) → revisor rejeita; mover para a crate.
- **Risco:** timeout QEMU / RAM 1536M apertada com workspace do motor → medir; aumentar timeout/`-m` só com doc.
- **Risco:** tokenizer / dequant / sampling incompletos → falha serial honesta ou `no_gguf_forward`, não números inventados.
- **Rollback:** restaurar `B_BLOCK=no_gguf_infer_engine` + stub E27; docs/ADR de tentativa permanecem como registro; crate pode ficar stub sem gate de tokens.

## Etapa do roadmap

- Etapa 29 — Motor de inferência GGUF mínimo na Linha B (`em_andamento`)
- Issue: [#29](https://github.com/eriksonlima/projeto-ia-livre/issues/29)
- Spec: `specs/motor-inferencia-linha-b/`
- Pronto quando (roadmap): geração mínima na Linha B (QEMU/IA Livre) com a carga canônica emitindo `TOKENS_PER_S` / `LOAD_S` **medidos** comparáveis em espécie aos de A; harness B + comparable atualizados sem inventar números; ADR 0001 respeitado (runtime nativo fora do kernel); ou bloqueio honesto novo documentado; depende do loader E26/E27.

> **Desfecho preferido:** `LOAD_KIND=gguf` + métricas medidas em B.  
> **Desfecho aceitável (fallback):** bloqueio novo (ex. `no_gguf_forward`) + código/docs intermediários verificáveis — cumpre o “ou” do Pronto quando **sem** fraude.

> **Agente principal:** `Spec: specs/motor-inferencia-linha-b/` já aponta no `ROADMAP.md` da Etapa 29 — confirmar; não marcar a etapa `feita` aqui.
