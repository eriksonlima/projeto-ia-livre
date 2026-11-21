# Spec — Prefill completo 22L + KV cache viável na Linha B

## Resultado visível

**Prefill honesto** no guest QEMU (TinyLlama 1.1B Chat v1.0 Q4_K_M): todas as **22 camadas** transformer com atenção GQA + SwiGLU por bloco, sobre o prompt canônico (múltiplos tokens), com **KV cache alocado e viável** (escrita/leitura por posição), marcadores serial verificáveis — **sem** loop Decode, **sem** sampling, **sem** `TOKENS_PER_S`, **sem** `LOAD_KIND=gguf`.

**Caminho de fallback (subset):** se 22L + KV multi-token for inviável em QEMU (RAM, tempo, correção) **após** avanço verificável além de E33 — subset de camadas **documentado e equivalente em espécie** (ex. `N_PREFILL_LAYERS=8` com justificativa + projeção para 22) **ou** `B_BLOCK` novo mais preciso (ex. `no_gguf_kv_viable` / `no_gguf_prefill_22l`) com marcadores parciais honestos (`PREFILL_LAYERS=`, `KV_BYTES=`, `KV_N_POS=`).

Decode + sampling + métricas de geração = **backlog B38** (Etapa seguinte) — **fora desta etapa**.

## Contexto fixo (não reinventar)

- **E33 desfecho:** `ATTN_LAYER_OK` + `FFN_LAYER_OK` + `PREFILL_OK` (1 token × camada 0); `FORWARD_FAIL=no_full_prefill`; `B_BLOCK=no_gguf_full_prefill`. Comparable: `VERDICT_REASON=E33_no_gguf_full_prefill_22L_kv_inviable`.
- **`runtime-native/`:** `try_attn_layer0_single`, `try_ffn_layer0`, `try_prefill_layer0`; attn GQA blk.0; SwiGLU Q4_K; `CANONICAL_PROMPT_TOKEN_IDS`.
- **Modelo:** TinyLlama ~22 layers; `n_embd=2048`; `n_head=32`; `n_kv_head=4` (GQA); `head_dim=64`; ~201 tensors Q4_K_M em RAM via BlockIO (`GGUF_NATIVE_LOADER=blockio_full`).
- **Infra:** QEMU `-m 1536M` (ou valor documentado se Task 1 medir necessidade); `build/gguf-canon.gguf`.
- **Contratos:** [`docs/runtime-nativo-linha-b.md`](../../docs/runtime-nativo-linha-b.md), [`docs/memoria-scheduler-impl-minima.md`](../../docs/memoria-scheduler-impl-minima.md) (tipado kernel ≠ KV do motor, mas fases Prefill alinham semanticamente), ADR [`0013`](../../docs/adr/0013-geracao-canonica-fatiada-linha-b.md).
- **Gates atuais:** `verify-boot.sh` / `verify-harness.sh` exigem `PREFILL_OK` + `FORWARD_FAIL=no_full_prefill` + `B_BLOCK=no_gguf_full_prefill`; **sem** `TOKENS_PER_S`.
- **Hipótese A vs B:** permanece **INCONCLUSIVO** até B38 (tokens); esta etapa **não** muda o veredito para `COMPROVA`/`REFUTA`.
- ADR [`0001`](../../docs/adr/0001-separacao-camadas-e-p2p.md) / [`0010`](../../docs/adr/0010-runtime-nativo-freestanding-linha-b.md): motor em `runtime-native/`; kernel glue/serial.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A — 22L + KV multi-token reais** | Generalizar attn/FFN por `blk.N`; buffer KV por camada (K/V GQA); loop Prefill sobre **todos** os ids do prompt canônico; 22 iterações de bloco; marcadores `PREFILL_22L_OK` + `KV_CACHE_OK` | **Preferida** — cumpre o “Pronto quando” do roadmap se viável em QEMU |
| **B — Subset documentado** | Se A inviável após medição: N camadas &lt; 22 **fixadas em ADR/doc** + KV viável para N_pos tokens mínimos (≥2); `PREFILL_LAYERS=N` + razão explícita (RAM/timeout/correção); `B_BLOCK` novo ou residual honesto | **Fallback aceitável** — só com critério de inviável **escrito** e sem fingir 22L |
| **C — Fraude / atalho** | Emitir `TOKENS_PER_S`; `LOAD_KIND=gguf`; prefill “22L” sem KV; reutilizar `no_gguf_full_prefill` sem avanço; host-as-B | **Rejeitada** |

### Escolha: **A preferida; B só com evidência de inviabilidade**

| Peça | Escolha nesta etapa |
|------|---------------------|
| Onde | `runtime-native/` (generalizar `attn`/`ffn` por índice de layer; módulo `kv` ou equivalente); kernel só glue/serial |
| Escopo forward | **Somente Prefill** (fase de processar prompt); logits finais podem ser checksum — **sem** argmax / **sem** decode autoregressivo |
| Tokens | **Todos** os `CANONICAL_PROMPT_TOKEN_IDS` (multi-token); mínimo aceitável no fallback: **≥2 posições** com KV escrito |
| Camadas | **22** (`blk.0` … `blk.21`); fallback: N documentado + equivalente (ex. mesmas ops, menos blocos) |
| KV | Por layer: K e V com shape GQA (`n_kv_head × head_dim × n_pos`); alloc no guest com marcador `KV_BYTES=`; prova write/read ou checksum por posição |
| Sucesso forte | Omitir `FORWARD_FAIL=no_full_prefill`; `B_BLOCK` → `no_gguf_decode` (ou omitido se doc fechar só decode residual); `PREFILL_LAYERS=22`; `KV_CACHE_OK` |
| Sucesso subset | `PREFILL_LAYERS=N` (N&lt;22); ADR critério; `B_BLOCK` novo se ainda bloquear decode; **proibido** `PREFILL_LAYERS=22` mentiroso |
| Métricas | **Proibido** `TOKENS_PER_S` / `LOAD_S` GGUF / `LOAD_KIND=gguf` nesta etapa |
| ADR | **0014** (sugerido): prefill 22L + KV; relação 0013; fronteira com B38 (decode) |

### Parâmetros TinyLlama (referência fixa)

| Parâmetro | Valor |
|-----------|-------|
| `n_layer` | 22 |
| `n_embd` | 2048 |
| `n_head` / `n_kv_head` | 32 / 4 (GQA) |
| `head_dim` | 64 |
| `n_ff` | 5632 |
| Prompt canônico | `Complete em uma frase: O Projeto IA Livre é` (+ BOS conforme E32) |

Tensores por bloco: `blk.N.attn_norm`, `attn_q/k/v`, `attn_output`, `ffn_norm`, `ffn_gate/up/down` (nomes GGUF canônicos).

### Contrato de marcadores (evolução E43)

Namespace kernel (UART COM1) + reemissão `IA_LIVRE_HARNESS_RUNTIME_NATIVE_*`.

#### Sucesso — prefill 22L + KV (preferido)

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_RUNTIME_NATIVE_PREFILL_LAYERS=22` | Loop completou 22 blocos |
| `IA_LIVRE_RUNTIME_NATIVE_KV_BYTES=<n>` | Bytes totais do buffer KV |
| `IA_LIVRE_RUNTIME_NATIVE_KV_N_POS=<p>` | Posições no cache (≥ len prompt) |
| `IA_LIVRE_RUNTIME_NATIVE_KV_CACHE_OK` | Alloc + uso verificável |
| `IA_LIVRE_RUNTIME_NATIVE_PREFILL_22L_OK` | Prefill multi-token × 22L ok |
| `IA_LIVRE_RUNTIME_NATIVE_FORWARD_FAIL=` | **Ausente** ou só residual de decode (`no_decode`) |
| `B_BLOCK` | `no_gguf_decode` (decode ainda ausente) **ou** omitido conforme Task 1 |
| Intermediários E33 | `ATTN_LAYER_OK`, `FFN_LAYER_OK`, `PREFILL_OK` podem permanecer |

#### Sucesso parcial — subset honesto

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_RUNTIME_NATIVE_PREFILL_LAYERS=<N>` | N&lt;22 documentado |
| `IA_LIVRE_RUNTIME_NATIVE_KV_*` | Como acima, coerente com N e N_pos |
| `IA_LIVRE_RUNTIME_NATIVE_PREFILL_PARTIAL_OK` | Subset verificável |
| `B_BLOCK=` | Novo (ex. `no_gguf_prefill_22l`, `no_gguf_kv_viable`) — **≠** `no_gguf_full_prefill` se natureza mudou |
| `TOKENS_PER_S` / `LOAD_KIND=gguf` | **Proibidos** |

#### Preservado

| Item | Regra |
|------|--------|
| Loader / layout | `blockio_full`, `layout_ok` |
| Proxy harness | `LOAD_KIND=proxy` até B38 |
| Comparable | Pode atualizar `VERDICT_REASON` se prefill 22L ok (ainda **INCONCLUSIVO** sem tokens) |
| Contrato E19 | `HARNESS_CONTRACT_*` preservado |

### Critério de “inviável” (subset / novo B_BLOCK)

Só **depois** de:

1. Generalização attn/FFN para ≥2 layers verificável (unit test host e/ou serial), **e**
2. Protótipo KV single-layer multi-pos verificável, **e**
3. Medição QEMU (tempo verify, pico RAM estimado).

Exemplos honestos:

- OOM ou fragmentação no guest com 22L × full prompt × KV real.
- Timeout `VERIFY_*` &gt; limite documentado mesmo com `VERIFY_TIMEOUT` estendido **uma vez** (registrar).
- Bug numérico em layer &gt;K que impede confiança sem escopo de etapa maior.

**Não** é inviável: “demorado mas passa gate”; fechar sem generalizar layer 1→N; manter `no_gguf_full_prefill` sem novos marcadores.

### Rejeitado (explícito)

- Decode autoregressivo, sampling, argmax, `output.weight` como geração (B38).
- `TOKENS_PER_S`, `LOAD_S`, `LOAD_KIND=gguf`, `RUNTIME_NATIVE_OK` como geração completa.
- Prefill “22L” sem KV multi-token (1 token só = estado E33).
- Microbench / contrato tipado kernel rotulados como prefill GGUF.
- llama.cpp no kernel; alterar Linha A; GPU guest; bare-metal USB nesta etapa.
- Forçar `COMPROVA` no comparable.

## Fora de escopo

- Loop Decode N=32 + sampling + `TOKENS_PER_S` (**B38**)
- Re-corrida comparable “limpa” (**B39**, deps B38)
- Metal / USB / imagem ESP além do path QEMU atual
- GPU nativa no guest
- Multi-GPU / shard / node / agent
- ABI estável do KV além do mínimo verificável

## Critérios de aceite

- [ ] ADR 0014 (+ docs): decisão A preferida / B fallback; critério inviável; fronteira B38; nomes de marcadores
- [ ] attn/FFN generalizados por `layer_idx` (≥2 layers testadas)
- [ ] KV cache mínimo multi-token alocado e usado no prefill (marcadores `KV_*`)
- [ ] **Ou** prefill **22L** + `PREFILL_22L_OK` + KV viável **ou** subset documentado + marcadores parciais + `B_BLOCK` honesto novo
- [ ] **Sem** `TOKENS_PER_S` / `LOAD_KIND=gguf` fingido
- [ ] `verify` + `verify-harness` atualizados ao desfecho; comparable ainda `INCONCLUSIVO` (sem tokens)
- [ ] `AGENTS.md` cobre cenário; README avaliado (`readme-por-fatia`)
- [ ] Pronto para marcar Etapa 43 `feita` após gate + revisor

## Riscos e rollback

- **Risco:** RAM 1536M insuficiente para KV 22L × prompt — medir na Task 1; aumentar `-m` só com doc; ou cair em subset B.
- **Risco:** tempo QEMU — estender timeout documentado; não pular layers.
- **Risco:** duplicar código layer0/layerN — extrair funções por índice sem refactor excessivo.
- **Risco:** gate ainda exige `no_gguf_full_prefill` após sucesso — Task 4 **deve** alinhar scripts.
- **Rollback:** restaurar `try_prefill_layer0` only + `B_BLOCK=no_gguf_full_prefill`; ADR/docs da tentativa permanecem.

## Etapa do roadmap

- **Etapa 43** — Prefill completo 22L + KV cache viável na Linha B (`em_andamento`)
- Issue: [#43](https://github.com/eriksonlima/projeto-ia-livre/issues/43) (ex-B37)
- Spec: `specs/prefill-22l-kv-linha-b/`
- Pronto quando: prefill 22L (ou subset documentado) + KV viável no QEMU Linha B, marcadores serial; **sem** fingir `TOKENS_PER_S`.

> **Desfecho preferido:** `PREFILL_22L_OK` + `KV_CACHE_OK` + `PREFILL_LAYERS=22` + `B_BLOCK=no_gguf_decode` (ou equivalente documentado).  
> **Desfecho aceitável:** subset N + `PREFILL_PARTIAL_OK` + critério ADR + novo `B_BLOCK` — **sem** fraude de camada completa.