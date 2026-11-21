# Spec — Forward GGUF mínimo em runtime-native (TOKENS_PER_S na Linha B)

## Resultado visível

Geração **canônica** na Linha B (QEMU / IA Livre) com a carga TinyLlama Q4_K_M, emitindo `LOAD_KIND=gguf` + `TOKENS_PER_S` / `LOAD_S` **medidos** (prompt / `n-predict=32` canônicos, CPU) via a crate `runtime-native`; harness B + comparable atualizados **sem inventar números**; ADR 0001 respeitado (motor fora do kernel); **ou** bloqueio honesto **novo** (mais preciso que `no_gguf_forward`) com avanço verificável além do layout E29.

Preferência forte da etapa: **chegar a tokens reais em B**. Fallback só após avanço intermediário real (mapa de tensores + dequant Q4_K + pelo menos um op) — nunca como atalho para fechar com números falsos.

## Contexto fixo (não reinventar)

- Etapa 29 **feita**: crate `ia-livre-runtime-native` (`runtime-native/`); `prepare()` → layout ok (`GGUF_STATUS=layout_ok` / `RUNTIME_NATIVE_LAYOUT_OK`); `try_forward_canonical` → `NoForwardImpl`; `B_BLOCK=no_gguf_forward`. ADR [`0010`](../../docs/adr/0010-runtime-nativo-freestanding-linha-b.md) / [`desenho-motor-inferencia-linha-b.md`](../../docs/desenho-motor-inferencia-linha-b.md).
- Etapa 27 **feita**: GGUF canônico (~638 MiB) na RAM do guest via BlockIO (`GGUF_NATIVE_LOADER=blockio_full`).
- Kernel pós-ExitBoot já chama `prepare` + `try_forward_canonical` (glue fino; motor **não** no `main.rs` como produto).
- Linha A (referência de espécie, **não** é B): `runtime/` + llama-cpp-2 host; `TOKENS_PER_S` / `LOAD_S` reais.
- Contrato Linha B: [`docs/runtime-nativo-linha-b.md`](../../docs/runtime-nativo-linha-b.md) — proxy E12 + contrato E19/E20 + loader + layout.
- Memória tipada: [`docs/memoria-scheduler-impl-minima.md`](../../docs/memoria-scheduler-impl-minima.md) — `Weights` / `KvCache` + Prefill/Decode.
- ADR [`0001`](../../docs/adr/0001-separacao-camadas-e-p2p.md): inferência **fora** do kernel.
- Hipótese A vs B: ainda **INCONCLUSIVO** enquanto B não emitir tokens em espécie.
- Infra QEMU: `-m 1536M`; disco raw `build/gguf-canon.gguf`.
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`; se não precisar, registrar.

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A** | Porta mínima completa de kernels Q4_K matmul + transformer TinyLlama (Prefill+Decode+sampling) de uma vez no guest | **Rejeitada como escopo único** — ambiciosa demais para uma etapa; risco de zero avanço verificável |
| **B** | Fatia vertical em `runtime-native`: (1) mapa de tensores nomeados + dequant Q4_K de ≥1 tensor; (2) matmul/attention stub **ou** passo forward parcial com marcadores; (3) se geração completa inviável — `B_BLOCK` novo mais preciso (ex. `no_gguf_attn` / `no_gguf_decode`) **com** progresso além de `no_gguf_forward` | **Escolhida** |
| **C** | Inventar `TOKENS_PER_S`; host-as-B; microbench-as-tokens / tipado-as-GGUF | **Rejeitada** — fraude de espécie/ambiente |

### Escolha: **B — fatia vertical em runtime-native (preferência a tokens)**

| Peça | Escolha nesta etapa |
|------|---------------------|
| Onde | Preferência forte: implementar o máximo possível **dentro** de `runtime-native/` (ADR 0010); kernel só glue/serial |
| Passo 1 | Evoluir `prepare`/API: índice de tensores **nomeados** (nome → tipo/dims/offset) + **dequant Q4_K** de pelo menos um tensor canônico (evidência serial / unit test) |
| Passo 2 | Um op honesto: matmul mínimo **ou** stub de attention com marcador claro **ou** um passo forward parcial (ex. embedding lookup / 1 camada) — não fingir transformer completo |
| Passo 3a (sucesso) | Prefill+Decode+sampling mínimos → geração canônica; `try_forward_canonical` Ok |
| Passo 3b (fallback) | `B_BLOCK` **novo** (≠ `no_gguf_forward`) documentando a lacuna restante (ex. `no_gguf_attn`, `no_gguf_decode`, `no_gguf_sampling`) **após** Passos 1–2 verificáveis |
| Escopo modelo | TinyLlama 1.1B Chat v1.0 **Q4_K_M** (já em RAM) |
| Prompt | `Complete em uma frase: O Projeto IA Livre é` |
| `n-predict` | `32` |
| Aceleração | **CPU** apenas (`ACCEL=cpu`) |
| Métricas | `LOAD_S` / `TOKENS_PER_S` **só** se medidos no guest na carga canônica |
| `LOAD_KIND` | `gguf` **só** com geração real; senão permanece `proxy` + bloqueio residual novo |
| Hipótese | Pode sair de `INCONCLUSIVO` **somente** com métricas B reais; **proibido** forçar `COMPROVA` |
| ADR | **0012** (sugerido): forward mínimo fatiado; rejeição A-como-única / C; relação 0001/0010/0011 |

### Justificativa

- E29 fechou o **layout** e deixou o bloqueio explícito: falta **forward**, não o path do arquivo.
- Opção A (porta completa de uma vez) historicamente resulta em “nada verificável no prazo” ou pressão por fraude — a fatia B garante progresso auditável mesmo se tokens não fecharem.
- Preferência a tokens: cada task empurra o máximo possível rumo a Prefill/Decode; o fallback exige **novo** `B_BLOCK` com evidência (tensor map + Q4_K + op), não reutilizar `no_gguf_forward` se a natureza do bloqueio mudou.
- Opção C destruiria o harness comparável e a hipótese.

### Rejeitado (explícito)

- Inventar `TOKENS_PER_S` / `LOAD_S` / `LOAD_KIND=gguf` / `MODEL=` TinyLlama sem geração medida no guest.
- Microbench E12 / tipado E19 rotulados como tokens canônicos.
- Contar Linha A / host `ia-livre-runtime` como evidência de B.
- Engessar llama.cpp / motor completo como produto em `kernel/src/main.rs`.
- Forçar `COMPROVA` / `REFUTA` sem métricas B em espécie.
- Bare-metal / USB (E30 já cobriu artefato; não misturar).
- GPU nativa / CUDA / Vulkan no guest.
- Alterar contratos da Linha A / carga canônica de A.
- Fechar a etapa só renomeando `no_gguf_forward` **sem** avanço (mapa + dequant + op).

### Carga canônica (igual à Linha A)

| Item | Valor |
|------|--------|
| Modelo | TinyLlama 1.1B Chat v1.0 |
| Quantização | Q4_K_M (GGUF) |
| Arquivo | `models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf` (guest: BlockIO / `build/gguf-canon.gguf`) |
| Prompt | `Complete em uma frase: O Projeto IA Livre é` |
| `--n-predict` / `N_PREDICT` | `32` |
| Aceleração | CPU |

### Contrato de marcadores (evolução)

Namespace kernel (serial COM1) + reemissão harness `IA_LIVRE_HARNESS_*`.

#### Sucesso com geração (caminho preferido)

| Marcador (kernel e/ou harness) | Significado |
|--------------------------------|-------------|
| `IA_LIVRE_RUNTIME_NATIVE_OK` | Geração mínima ok no guest |
| `LOAD_KIND=gguf` | Geração real no guest |
| `MODEL=` | Arquivo / id TinyLlama canônico |
| `N_PREDICT=32` | Igual à A |
| `LOAD_S=` / `TOKENS_PER_S=` | **Medidos** no guest (não inventados; não do proxy) |
| `ACCEL=cpu` | Sem GPU nativa |
| `B_BLOCK` | **Omitido** (ou residual só se lacuna honesta **além** da geração) |
| Intermediários | Tensor map / dequant / forward parcial podem permanecer como evidência de caminho |

#### Bloqueio honesto novo (caminho de fallback)

| Marcador | Significado |
|----------|-------------|
| Avanço intermediário | Ex.: `TENSOR_MAP_OK`, `Q4K_DEQUANT_OK`, `FORWARD_OP_OK` (nomes fixados na Task 1) — **obrigatórios** no fallback |
| `B_BLOCK=` | Motivo **novo** (ex. `no_gguf_attn`, `no_gguf_decode`, `no_gguf_sampling`) — **não** reutilizar `no_gguf_forward` se o bloqueio mudou |
| `TOKENS_PER_S` / `LOAD_S` / `LOAD_KIND=gguf` | **Proibidos** |
| Veredito comparável | Continua `INCONCLUSIVO` |

#### Critério de “inviável” (quando cair no fallback)

Escrito na Task 1 / ADR 0012. Exemplos honestos:

- Tokenizer / sampling mínimo ausente sem caminho seguro no prazo.
- Attention/KV completos inviáveis sem fraude após o op parcial.
- Timeout/RAM QEMU impede Prefill+Decode canônicos sem inventar métricas.

**Não** é “inviável”: falta de tempo sem entregar Passos 1–2.

#### Preservado / proibido

| Item | Regra |
|------|--------|
| Loader E26/E27 | `blockio_full` preservado |
| Layout E29 | `layout_ok` / crate `runtime-native` preservados e **estendidos** |
| Contrato E19/E20 | `HARNESS_CONTRACT_*` / `CONTRACT_READY=1` preservados; tipados só ajustados se o forward consumir |
| ADR 0001 / 0010 | Forward na crate; glue fino no kernel |
| Fraude | Sem tokens inventados; sem host-as-B; sem microbench-as-GGUF |

### Relação com o gate atual

- Hoje: harness B exige `GGUF_NATIVE_LOADER=blockio_full`, `GGUF_STATUS=layout_ok`, `B_BLOCK=no_gguf_forward`, **sem** `TOKENS_PER_S`; comparable → `INCONCLUSIVO`.
- Com geração: gate **passa** a exigir `RUNTIME_NATIVE_OK` + `LOAD_KIND=gguf` + `LOAD_S` / `TOKENS_PER_S` medidos + `N_PREDICT=32`; comparable pode emitir `COMPROVA`/`REFUTA`/`INCONCLUSIVO` **só** com regras honestas.
- Com bloqueio novo: gate exige intermediários + `B_BLOCK=<novo>` (≠ `no_gguf_forward` se natureza mudou); comparable `INCONCLUSIVO`; **continua** rejeitando tokens inventados.
- Timeouts: forward TinyLlama em QEMU provavelmente exige `VERIFY_*_TIMEOUT` maior — documentar.

## Conteúdo obrigatório

### 1. ADR 0012 + contrato de marcadores / critério inviável (Task 1)

- ADR [`docs/adr/0012-….md`](../../docs/adr/): escolha B fatiada; rejeição A-única / C; relação 0001/0010; critério sucesso vs fallback; nomes dos marcadores intermediários.
- Atualizar [`docs/desenho-motor-inferencia-linha-b.md`](../../docs/desenho-motor-inferencia-linha-b.md) e/ou seção Etapa 31 em [`docs/runtime-nativo-linha-b.md`](../../docs/runtime-nativo-linha-b.md).
- Pontes: `harness-linha-a-b.md`, `harness-a-b-comparavel.md`, `harness-corrida-quieta.md`.
- `AGENTS.md`: estado alvo; README avaliar (`readme-por-fatia`).

### 2. Mapa de tensores nomeados + dequant Q4_K (Task 2)

- Em `runtime-native/`: índice nome→info; dequant Q4_K de ≥1 tensor do GGUF canônico; evidência (unit test host e/ou marcador serial).
- Sem emitir `TOKENS_PER_S` nesta task.

### 3. Op parcial / tentativa de forward canônico **ou** bloqueio novo (Task 3)

- Preferência: estender `try_forward_canonical` rumo a Prefill+Decode+sampling → `RUNTIME_NATIVE_OK` + métricas.
- Mínimo aceitável se tokens inviáveis: ≥1 op honesto (matmul / embedding / camada parcial) + marcadores + `B_BLOCK` novo documentado.
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

## Critérios de aceite

- [ ] ADR 0012 + docs: decisão B; rejeições A-única/C; critério inviável explícito
- [ ] Mapa de tensores nomeados + dequant Q4_K verificáveis em `runtime-native`
- [ ] **Ou** geração canônica com `RUNTIME_NATIVE_OK` + `LOAD_KIND=gguf` + `LOAD_S`/`TOKENS_PER_S` medidos + `N_PREDICT=32` **ou** bloqueio honesto **novo** com intermediários (≥ mapa + dequant + um op) além de `no_gguf_forward`
- [ ] Harness B + comparable atualizados sem inventar números
- [ ] ADR 0001 / 0010 respeitados (forward na crate)
- [ ] Hipótese só muda de `INCONCLUSIVO` com evidência real em espécie
- [ ] `AGENTS.md` cobre o cenário; README avaliado
- [ ] Etapa pronta para o agente principal marcar `feita` após gate + revisor

## Riscos e rollback

- **Risco:** transformer TinyLlama Q4_K_M em `no_std` maior que a etapa → Tasks 1–2 + op parcial + `B_BLOCK` novo na 3; tokens em etapa futura **só** se o fallback for honesto.
- **Risco:** pressão por `COMPROVA` / tokens → regra dura: sem geração medida = sem `TOKENS_PER_S` / sem `LOAD_KIND=gguf`.
- **Risco:** reutilizar `no_gguf_forward` após progresso real → revisor exige `B_BLOCK` mais preciso.
- **Risco:** timeout / RAM 1536M → medir; aumentar timeout/`-m` só com doc.
- **Risco:** dequant/matmul incorretos “passando” gate → unit tests no GGUF canônico + marcadores intermediários.
- **Rollback:** restaurar `B_BLOCK=no_gguf_forward` + `NoForwardImpl`; docs/ADR de tentativa permanecem; intermediários podem ficar sem gate de tokens.

## Etapa do roadmap

- Etapa 31 — Forward GGUF mínimo em runtime-native (TOKENS_PER_S na Linha B) (`em_andamento`)
- Issue: [#31](https://github.com/eriksonlima/projeto-ia-livre/issues/31)
- Spec: `specs/forward-gguf-linha-b/`
- Pronto quando (roadmap): geração canônica na Linha B (QEMU) com `LOAD_KIND=gguf` + `TOKENS_PER_S`/`LOAD_S` **medidos** (carga TinyLlama Q4_K_M, prompt/`n-predict` canônicos, CPU) **ou** bloqueio honesto novo documentado; ADR 0001; harness atualizado sem inventar números; depende do layout E29 (`no_gguf_forward`).

> **Desfecho preferido:** `RUNTIME_NATIVE_OK` + `LOAD_KIND=gguf` + métricas medidas + `N_PREDICT=32`.  
> **Desfecho aceitável (fallback):** `B_BLOCK` novo (ex. `no_gguf_attn`) + mapa + dequant Q4_K + ≥1 op — cumpre o “ou” do Pronto quando **sem** fraude.

> **Agente principal:** `Spec: specs/forward-gguf-linha-b/` já aponta no `ROADMAP.md` da Etapa 31 — confirmar; não marcar a etapa `feita` aqui.
