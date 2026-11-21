# Spec — Geração canônica Prefill+Decode+sampling na Linha B (TOKENS_PER_S)

## Resultado visível

Geração **canônica** na Linha B (QEMU / IA Livre) com TinyLlama 1.1B Chat v1.0 Q4_K_M: `LOAD_KIND=gguf` + `TOKENS_PER_S` / `LOAD_S` **medidos** (prompt canônico, `n-predict=32`, CPU) + `RUNTIME_NATIVE_OK`; harness B + comparable atualizados **sem inventar números**; ADR 0001 respeitado (motor em `runtime-native/`); **ou** bloqueio honesto **novo** (≠ `no_gguf_generate`) com avanço verificável além do op parcial E31 — preferência: embedding lookup + ≥1 camada transformer parcial evidenciados.

Preferência forte da etapa: **chegar a tokens reais em B**. Fallback só após avanço intermediário real (tokenização mínima + embedding + camada parcial) — nunca como atalho para fechar com números falsos.

## Contexto fixo (não reinventar)

- Etapa 31 **feita**: mapa de tensores nomeados + dequant Q4_K (≥1 bloco) + op parcial (`forward_op_dot_self`); `B_BLOCK=no_gguf_generate`; `FORWARD_FAIL=no_generate`. ADR [`0012`](../../docs/adr/0012-forward-gguf-fatiado-linha-b.md).
- Estado `runtime-native`: `prepare`, `find_tensor`, Q4_K dequant (1 bloco), `forward_op_dot_self`; **sem** Prefill/Decode/sampling.
- Modelo em RAM do guest: TinyLlama Q4_K_M ~638 MiB; ~201 tensors; vocab 32000; dim 2048.
- Etapas 26/27: GGUF completo via BlockIO (`GGUF_NATIVE_LOADER=blockio_full`).
- Etapa 29: crate `ia-livre-runtime-native` + `layout_ok` (ADR [`0010`](../../docs/adr/0010-runtime-nativo-freestanding-linha-b.md)).
- Linha A (referência de espécie, **não** é B): `runtime/` + llama-cpp-2; `TOKENS_PER_S` / `LOAD_S` reais.
- Contrato Linha B: [`docs/runtime-nativo-linha-b.md`](../../docs/runtime-nativo-linha-b.md) — proxy E12 + contrato E19/E20 + loader + mapa/dequant/op.
- Memória tipada: [`docs/memoria-scheduler-impl-minima.md`](../../docs/memoria-scheduler-impl-minima.md) — `Weights` / `KvCache` + Prefill/Decode.
- ADR [`0001`](../../docs/adr/0001-separacao-camadas-e-p2p.md): inferência **fora** do kernel.
- Hipótese A vs B: **INCONCLUSIVO** enquanto B não emitir tokens em espécie.
- Infra QEMU: `-m 1536M`; disco raw `build/gguf-canon.gguf`.
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`; se não precisar, registrar.

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A** | Porta completa do transformer TinyLlama (todas as camadas + KV + sampling) de uma vez no guest | **Rejeitada como escopo único** — grande demais; risco de zero avanço verificável |
| **B** | Fatia vertical em `runtime-native`: (1) tokenização mínima + embedding lookup (`token_embd` Q4_K) + marcadores; (2) ≥1 camada parcial (attn **ou** FFN) honesta; (3) loop decode N tokens **ou** `B_BLOCK` novo (`no_gguf_transformer` / `no_gguf_decode` / …) **com** embedding+camada evidenciados; (4) harness se tokens existirem | **Escolhida** |
| **C** | Inventar `TOKENS_PER_S`; host-as-B; microbench/tipado/op-parcial-as-tokens; reutilizar `no_gguf_generate` sem avanço | **Rejeitada** — fraude de espécie/ambiente |

### Escolha: **B — geração fatiada em runtime-native (preferência a tokens)**

| Peça | Escolha nesta etapa |
|------|---------------------|
| Onde | Preferência forte: implementar em `runtime-native/` (ADR 0010/0012); kernel só glue/serial |
| Passo 1 | Tokenização mínima (prompt canônico → ids) + **embedding lookup** no tensor `token_embd` (Q4_K) + marcadores serial |
| Passo 2 | Uma **camada transformer parcial** honesta (attn **ou** FFN) com dequant/matmul reais — não fingir stack completa |
| Passo 3a (sucesso) | Prefill + Decode + sampling mínimos → N tokens (`n-predict=32` ou N documentado se parcial mas medido); `try_forward_canonical` Ok; `RUNTIME_NATIVE_OK` |
| Passo 3b (fallback) | `B_BLOCK` **novo** (ex. `no_gguf_transformer`, `no_gguf_decode`, `no_gguf_sampling`) — **≠** `no_gguf_generate` — **após** Passos 1–2 verificáveis (embedding + camada) |
| Escopo modelo | TinyLlama 1.1B Chat v1.0 **Q4_K_M** (já em RAM) |
| Prompt | `Complete em uma frase: O Projeto IA Livre é` |
| `n-predict` | `32` (sucesso canônico); se decode parcial medido, documentar N real — **nunca** inventar taxa |
| Aceleração | **CPU** apenas (`ACCEL=cpu`) |
| Métricas | `LOAD_S` / `TOKENS_PER_S` **só** se medidos no guest na carga canônica com geração real |
| `LOAD_KIND` | `gguf` **só** com geração real; senão permanece `proxy` + bloqueio residual novo |
| Hipótese | Pode sair de `INCONCLUSIVO` **somente** com métricas B reais; **proibido** forçar `COMPROVA` |
| ADR | **0013** (sugerido): geração canônica fatiada; rejeição A-única / C; relação 0001/0010/0012; critério inviável |

### Justificativa

- E31 fechou mapa + dequant + op e deixou o bloqueio explícito: falta **geração** (Prefill/Decode/sampling), não o path do arquivo nem o dequant básico.
- Transformer completo TinyLlama no guest é multi-etapa; fatia B garante progresso auditável (embedding + camada) mesmo se tokens não fecharem.
- Preferência a tokens: cada task empurra rumo a Prefill/Decode; o fallback exige **novo** `B_BLOCK` com evidência (embedding + camada), não reutilizar `no_gguf_generate` se a natureza do bloqueio mudou.
- Opção C destruiria o harness comparável e a hipótese.

### Rejeitado (explícito)

- Inventar `TOKENS_PER_S` / `LOAD_S` / `LOAD_KIND=gguf` / `MODEL=` TinyLlama sem geração medida no guest.
- Microbench E12 / tipado E19 / op parcial E31 rotulados como tokens canônicos.
- Contar Linha A / host `ia-livre-runtime` como evidência de B.
- Engessar llama.cpp / motor completo como produto em `kernel/src/main.rs`.
- Forçar `COMPROVA` / `REFUTA` sem métricas B em espécie.
- Bare-metal / USB (E30); GPU nativa no guest.
- Alterar contratos da Linha A / carga canônica de A.
- Fechar a etapa só renomeando `no_gguf_generate` **sem** avanço (embedding + camada parcial).

### Carga canônica (igual à Linha A)

| Item | Valor |
|------|--------|
| Modelo | TinyLlama 1.1B Chat v1.0 |
| Quantização | Q4_K_M (GGUF) |
| Arquivo | `models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf` (guest: BlockIO / `build/gguf-canon.gguf`) |
| Prompt | `Complete em uma frase: O Projeto IA Livre é` |
| `--n-predict` / `N_PREDICT` | `32` |
| Aceleração | CPU |
| Dim / vocab (referência) | dim 2048; vocab ~32000; ~201 tensors |

### Contrato de marcadores (evolução)

Namespace kernel (serial COM1) + reemissão harness `IA_LIVRE_HARNESS_*`.

#### Sucesso com geração (caminho preferido)

| Marcador (kernel e/ou harness) | Significado |
|--------------------------------|-------------|
| `IA_LIVRE_RUNTIME_NATIVE_OK` | Geração mínima ok no guest |
| `LOAD_KIND=gguf` | Geração real no guest |
| `MODEL=` | Arquivo / id TinyLlama canônico |
| `N_PREDICT=32` | Igual à A (ou N real documentado se escopo parcial medido — Task 1 fixa) |
| `LOAD_S=` / `TOKENS_PER_S=` | **Medidos** no guest (não inventados; não do proxy) |
| `ACCEL=cpu` | Sem GPU nativa |
| `B_BLOCK` | **Omitido** (ou residual só se lacuna honesta **além** da geração) |
| Intermediários | Tokenize / embedding / camada parcial podem permanecer como evidência de caminho |

#### Bloqueio honesto novo (caminho de fallback)

| Marcador | Significado |
|----------|-------------|
| Avanço intermediário | Ex.: `TOKENIZE_OK`, `EMBED_OK`, `LAYER_PARTIAL_OK` (nomes fixados na Task 1) — **obrigatórios** no fallback |
| Preservados E31 | `TENSOR_MAP_OK`, `Q4K_DEQUANT_OK`, `FORWARD_OP_OK` (ou equivalentes reemitidos) |
| `B_BLOCK=` | Motivo **novo** (ex. `no_gguf_transformer`, `no_gguf_decode`, `no_gguf_sampling`) — **não** reutilizar `no_gguf_generate` se o bloqueio mudou |
| `TOKENS_PER_S` / `LOAD_S` / `LOAD_KIND=gguf` | **Proibidos** |
| Veredito comparável | Continua `INCONCLUSIVO` |

#### Critério de “inviável” (quando cair no fallback)

Escrito na Task 1 / ADR 0013. Exemplos honestos:

- Attention/KV/FFN completos inviáveis sem fraude após embedding + camada parcial.
- Loop decode / sampling mínimo ausente sem caminho seguro no prazo (timeout/RAM QEMU).
- Tokenizer suficiente para prompt canônico inviável **sem** entregar embedding+camada (neste caso o fallback ainda exige avanço além de `no_gguf_generate`).

**Não** é “inviável”: falta de tempo sem entregar Passos 1–2 (tokenize + camada).

#### Preservado / proibido

| Item | Regra |
|------|--------|
| Loader E26/E27 | `blockio_full` preservado |
| Layout E29 + mapa/dequant/op E31 | preservados e **estendidos** |
| Contrato E19/E20 | `HARNESS_CONTRACT_*` / `CONTRACT_READY=1` preservados |
| ADR 0001 / 0010 / 0012 | Geração na crate; glue fino no kernel; fatia vertical |
| Fraude | Sem tokens inventados; sem host-as-B; sem microbench/op-as-GGUF |

### Relação com o gate atual

- Desfecho E32: harness B exige `blockio_full`, `layout_ok`, tokenize/embed/camada, `B_BLOCK=no_gguf_decode`, **sem** `TOKENS_PER_S`; comparable → `INCONCLUSIVO`.
- Com geração: gate **passa** a exigir `RUNTIME_NATIVE_OK` + `LOAD_KIND=gguf` + `LOAD_S` / `TOKENS_PER_S` medidos + `N_PREDICT=32`; comparable pode emitir `COMPROVA`/`REFUTA`/`INCONCLUSIVO` **só** com regras honestas.
- Com bloqueio novo: gate exige intermediários (tokenize + embedding + camada) + `B_BLOCK=<novo>` (≠ `no_gguf_generate`); comparable `INCONCLUSIVO`; **continua** rejeitando tokens inventados.
- Timeouts: Prefill/Decode TinyLlama em QEMU provavelmente exige `VERIFY_*_TIMEOUT` maior — documentar.

## Conteúdo obrigatório

### 1. ADR 0013 + contrato de marcadores / critério inviável (Task 1)

- ADR [`docs/adr/0013-….md`](../../docs/adr/): escolha B fatiada; rejeição A-única / C; relação 0001/0010/0012; critério sucesso vs fallback; nomes dos marcadores intermediários (tokenize / embed / camada).
- Atualizar [`docs/desenho-motor-inferencia-linha-b.md`](../../docs/desenho-motor-inferencia-linha-b.md) e seção Etapa 32 em [`docs/runtime-nativo-linha-b.md`](../../docs/runtime-nativo-linha-b.md).
- Pontes: `harness-linha-a-b.md`, `harness-a-b-comparavel.md`, `harness-corrida-quieta.md`.
- `AGENTS.md`: estado alvo; README avaliar (`readme-por-fatia`).

### 2. Tokenização mínima + embedding lookup (Task 2)

- Em `runtime-native/`: prompt canônico → ids mínimos; lookup no `token_embd` (Q4_K) com evidência (unit test host e/ou marcador serial).
- Sem emitir `TOKENS_PER_S` nesta task.

### 3. Camada parcial + tentativa de Prefill/Decode/sampling **ou** bloqueio novo (Task 3)

- Preferência: attn **ou** FFN parcial → estender até loop decode N tokens + sampling → `RUNTIME_NATIVE_OK` + métricas.
- Mínimo aceitável se tokens inviáveis: embedding (Task 2) + ≥1 camada parcial + marcadores + `B_BLOCK` novo documentado (≠ `no_gguf_generate`).
- Zero tokens inventados.

### 4. Harness B + comparable + docs finais (Task 4)

- Se geração: `LOAD_KIND=gguf`, `LOAD_S` / `TOKENS_PER_S`, gates atualizados; comparable honesto.
- Se bloqueio: gates exigem intermediários + `B_BLOCK=<novo>`; comparable `INCONCLUSIVO`.
- Docs/`AGENTS.md` alinhados ao desfecho real.

## Fora de escopo

- Bare-metal / USB (E30)
- GPU nativa / CUDA / Vulkan no guest
- Forçar `COMPROVA` sem métricas B reais
- Alterar Linha A (carga, gate A, llama-cpp-2)
- Port completo de llama.cpp no kernel
- libp2p / `node/` / `agent/`
- Filesystem maduro / multi-tenant / ABI estável além do glue mínimo
- Todas as camadas TinyLlama obrigatórias se o caminho de sucesso parcial medido for documentado na Task 1 (sucesso canônico = `n-predict=32` completo)

## Critérios de aceite

- [ ] ADR 0013 + docs: decisão B; rejeições A-única/C; critério inviável explícito
- [ ] Tokenização mínima + embedding lookup verificáveis em `runtime-native`
- [x] **Ou** geração canônica com `RUNTIME_NATIVE_OK` + `LOAD_KIND=gguf` + `LOAD_S`/`TOKENS_PER_S` medidos + `N_PREDICT=32` **ou** bloqueio honesto **novo** com intermediários (≥ tokenize/embed + camada parcial) além de `no_gguf_generate` → desfecho: `no_gguf_decode`
- [ ] Harness B + comparable atualizados sem inventar números
- [ ] ADR 0001 / 0010 / 0012 respeitados (geração na crate; fatia vertical)
- [ ] Hipótese só muda de `INCONCLUSIVO` com evidência real em espécie
- [ ] `AGENTS.md` cobre o cenário; README avaliado
- [ ] Etapa pronta para o agente principal marcar `feita` após gate + revisor

## Riscos e rollback

- **Risco:** transformer TinyLlama Q4_K_M completo em `no_std` maior que a etapa → Tasks 1–2 + camada parcial + `B_BLOCK` novo na 3; tokens em etapa futura **só** se o fallback for honesto.
- **Risco:** pressão por `COMPROVA` / tokens → regra dura: sem geração medida = sem `TOKENS_PER_S` / sem `LOAD_KIND=gguf`.
- **Risco:** reutilizar `no_gguf_generate` após progresso real → revisor exige `B_BLOCK` mais preciso.
- **Risco:** timeout / RAM 1536M / dim 2048 × vocab → medir; aumentar timeout/`-m` só com doc; embedding row-wise (não materializar matriz inteira se possível).
- **Risco:** dequant/matmul/attn incorretos “passando” gate → unit tests no GGUF canônico + marcadores intermediários.
- **Rollback:** restaurar `B_BLOCK=no_gguf_generate` + `FORWARD_FAIL=no_generate`; docs/ADR de tentativa permanecem; intermediários podem ficar sem gate de tokens.

## Etapa do roadmap

- Etapa 32 — Geração canônica Prefill+Decode+sampling na Linha B (TOKENS_PER_S) (`em_andamento`)
- Issue: [#42](https://github.com/eriksonlima/projeto-ia-livre/issues/42)
- Spec: `specs/geracao-canonica-linha-b/`
- Pronto quando (roadmap): geração canônica no guest com `LOAD_KIND=gguf` + `TOKENS_PER_S`/`LOAD_S` medidos (TinyLlama Q4_K_M, prompt/`n-predict=32`, CPU) + `RUNTIME_NATIVE_OK`; harness atualizado; **ou** bloqueio honesto novo com avanço além de `no_gguf_generate`; ADR 0001; depende Etapa 31.

> **Desfecho preferido:** `RUNTIME_NATIVE_OK` + `LOAD_KIND=gguf` + métricas medidas + `N_PREDICT=32`.  
> **Desfecho aceitável (fallback):** `B_BLOCK` novo (ex. `no_gguf_decode`) + tokenize/embed + ≥1 camada parcial — cumpre o “ou” do Pronto quando **sem** fraude.

> **Agente principal:** `Spec: specs/geracao-canonica-linha-b/` já aponta no `ROADMAP.md` da Etapa 32 — confirmar; não marcar a etapa `feita` aqui.
