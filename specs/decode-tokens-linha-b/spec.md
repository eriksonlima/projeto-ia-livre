# Spec — Decode + sampling + TOKENS_PER_S canônico na Linha B

## Resultado visível

**Geração canônica honesta** na Linha B (QEMU / IA Livre): loop **Decode autoregressivo** + **sampling** no motor `runtime-native`, sobre o Prefill/KV já existentes (E43), emitindo `TOKENS_PER_S` / `LOAD_S` **medidos** e marcadores Decode/sampling — **somente** se houver geração real no guest; `LOAD_KIND=gguf`; `B_BLOCK` **removido** ou **substituído** por motivo residual preciso; gate harness B (+ comparable) atualizado.

**Preferência:** `n-predict=32` (carga canônica TinyLlama Q4_K_M, prompt canônico, CPU) com Prefill+Decode+sampling plenos no QEMU.

**Realismo (obrigatório nesta spec):** Prefill guest ainda é subset **2 layers × 2 pos** (ADR 0014 / E43). Decode “TinyLlama canônico” pleno (22L × N tokens) no QEMU **debug** é provavelmente inviável no prazo. A etapa **deve** seguir caminho A→B honesto abaixo — **nunca** emitir `TOKENS_PER_S` sem loop decode real.

## Contexto fixo (não reinventar)

- **E43 desfecho:** Prefill subset guest `PREFILL_LAYERS=2` × `KV_N_POS=2` + `KV_CACHE_OK` / `PREFILL_PARTIAL_OK`; `FORWARD_FAIL=no_decode`; `B_BLOCK=no_gguf_prefill_22l`; comparable `E43_no_gguf_prefill_22l_subset_kv_ok`; **sem** `TOKENS_PER_S`.
- **Host release (referência):** 2L×16 ~7s; extrapolação 22L×16 ~250s host — **não** prova QEMU debug.
- **QEMU:** 22L×16 e até 2L×16 estourou timeout 600s em build **debug** (Makefile atual); motor em `runtime-native/`; kernel UEFI glue/serial.
- **Proxy:** `LOAD_KIND=proxy` permanece até geração real.
- **ADRs:** [`0013`](../../docs/adr/0013-geracao-canonica-fatiada-linha-b.md) (geração fatiada), [`0014`](../../docs/adr/0014-prefill-22l-kv-linha-b.md) (prefill/KV subset), [`0001`](../../docs/adr/0001-separacao-camadas-e-p2p.md) / [`0010`](../../docs/adr/0010-runtime-nativo-freestanding-linha-b.md) (motor fora do kernel).
- **Contratos:** [`docs/runtime-nativo-linha-b.md`](../../docs/runtime-nativo-linha-b.md), [`docs/harness-linha-a-b.md`](../../docs/harness-linha-a-b.md), [`docs/harness-a-b-comparavel.md`](../../docs/harness-a-b-comparavel.md).
- **Hipótese A vs B:** ainda **INCONCLUSIVO**; esta etapa (ex-B38) é o passo para `TOKENS_PER_S` em espécie — **proibido** inventar métricas.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A — Decode canônico + otimização** | Otimizar caminho guest (release UEFI / menos pos / matvec mais barato) + Decode autoregressivo com as **N layers disponíveis** no Prefill/KV; sampling mínimo; `n-predict=32` preferido (ou N documentado se parcial mas **medido**); `LOAD_KIND=gguf` + `TOKENS_PER_S` **só** com loop real | **Preferida** |
| **B — Decode mínimo documentado ou B_BLOCK novo** | Se A inviável após tentativa/otimização documentada: Decode mínimo (ex. 1–N tokens com subset de layers alinhado ao Prefill E43) **com** métricas reais **ou** `B_BLOCK` novo (ex. `no_gguf_decode_perf` / `no_gguf_decode`) **sem** inventar `TOKENS_PER_S` | **Fallback aceitável** |
| **C — Fraude** | Emitir `TOKENS_PER_S` / `LOAD_KIND=gguf` sem loop decode; host-as-B; microbench/proxy-as-tokens; manter `no_gguf_prefill_22l` sem avanço Decode | **Rejeitada** |

### Escolha: **A preferida; B só com evidência de inviabilidade**

| Peça | Escolha nesta etapa |
|------|---------------------|
| Onde | `runtime-native/` (Decode + sampling + logits/`output.weight` mínimo); kernel só glue/serial |
| Prefill/KV | Reutilizar subset E43 (ou estender se otimização permitir); **não** exigir 22L pleno como pré-condição de Decode mínimo |
| Decode | Autoregressivo: 1 token gerado por passo; atualizar KV; N passos (`n-predict=32` preferido) |
| Sampling | Mínimo verificável (ex. argmax / greedy); documentar política; marcador `SAMPLING_OK` (ou equivalente fixado na Task 1) |
| Sucesso forte | `RUNTIME_NATIVE_OK` + `DECODE_OK` + `SAMPLING_OK` + `LOAD_KIND=gguf` + `LOAD_S=` / `TOKENS_PER_S=` medidos + `N_PREDICT=` (32 ou N real) + `B_BLOCK` **omitido** |
| Sucesso parcial (ainda com tokens) | Decode com subset layers/pos + N&lt;32 documentado + métricas **reais** + `LOAD_KIND=gguf`; comparable pode deixar `INCONCLUSIVO` se espécie ≠ A plena — **nunca** fraudar razão |
| Fallback sem tokens | `B_BLOCK` **novo** (ex. `no_gguf_decode_perf`) — **≠** reutilizar `no_gguf_prefill_22l` se a natureza do bloqueio passou a ser Decode/perf; marcadores de tentativa Decode; **proibido** `TOKENS_PER_S` |
| Otimizações candidatas (Task 2) | Build **release** UEFI (opt-in documentado); reduzir `KV_N_POS` / layers só se já no subset; matvec/dequant mais barato — medir antes/depois |
| Hipótese | Sai de `INCONCLUSIVO` **somente** com métricas B reais em espécie; **proibido** forçar `COMPROVA` |
| ADR | **0015** (sugerido): Decode/sampling/TOKENS_PER_S; relação 0013/0014; critério inviável; proibição de métricas sem loop |

### Carga canônica (igual à Linha A — sucesso preferido)

| Item | Valor |
|------|--------|
| Modelo | TinyLlama 1.1B Chat v1.0 Q4_K_M |
| Prompt | `Complete em uma frase: O Projeto IA Livre é` |
| `n-predict` | `32` (preferido); se Decode parcial medido, documentar N real |
| Aceleração | CPU (`ACCEL=cpu`) |
| Ambiente | Guest QEMU Linha B (não host-as-B) |

### Contrato de marcadores (evolução E44)

Namespace kernel (UART COM1) + reemissão `IA_LIVRE_HARNESS_*`.

#### Sucesso — geração com tokens (preferido)

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_RUNTIME_NATIVE_DECODE_OK` | Loop Decode ≥1 token real |
| `IA_LIVRE_RUNTIME_NATIVE_SAMPLING_OK` | Sampling aplicado (política documentada) |
| `IA_LIVRE_RUNTIME_NATIVE_N_PREDICT=<n>` | Tokens gerados / alvo |
| `IA_LIVRE_RUNTIME_NATIVE_OK` | Geração mínima ok no guest |
| `LOAD_KIND=gguf` | Geração real (harness) |
| `LOAD_S=` / `TOKENS_PER_S=` | **Medidos** no guest (wall-clock da geração) |
| `B_BLOCK` | **Omitido** |
| `FORWARD_FAIL=no_decode` | **Ausente** |
| Prefill/KV E43 | Podem permanecer (`PREFILL_*`, `KV_*`) coerentes com N layers usadas |

#### Fallback — sem tokens / perf inviável

| Marcador | Significado |
|----------|-------------|
| Tentativa Decode | Ex. `DECODE_ATTEMPT=1`, `DECODE_FAIL=<reason>` (nomes fixados Task 1) |
| `B_BLOCK=` | Novo (ex. `no_gguf_decode_perf`, `no_gguf_decode`) — **≠** `no_gguf_prefill_22l` se o bloqueio mudou |
| `TOKENS_PER_S` / `LOAD_KIND=gguf` | **Proibidos** |
| Comparable | `INCONCLUSIVO` + `VERDICT_REASON` atualizado (ex. `E44_no_gguf_decode_perf`) |

#### Regra dura

> **Nunca** emitir `TOKENS_PER_S` (nem `LOAD_KIND=gguf` de geração) sem loop Decode real que produziu ≥1 token no guest.

### Critério de “inviável” (cair em B)

Só **depois** de:

1. Contrato ADR 0015 + marcadores (Task 1), **e**
2. Otimização tentada ou descartada com medição (release UEFI e/ou redução de custo documentada) (Task 2), **e**
3. Implementação de Decode+sampling mínimo exercitada em host e/ou guest com evidência de falha de perf/timeout/correção (Task 3).

Exemplos honestos:

- Timeout `VERIFY_*` / QEMU debug mesmo com release opt-in e **uma** extensão de timeout documentada.
- Decode 1 token × subset 2L ainda &gt; limite de gate após otimização.
- Bug numérico que impede confiança sem escopo maior (registrar; não inventar taxa).

**Não** é inviável: “não deu tempo” sem tentar Decode; emitir métricas do host como B; pular otimização sem medição.

### Rejeitado (explícito)

- `TOKENS_PER_S` / `LOAD_S` / `LOAD_KIND=gguf` sem Decode real.
- Contar Linha A / `ia-livre-runtime` host como evidência de B.
- Microbench E12 / tipado E19 / Prefill E43 rotulados como geração.
- Forçar `COMPROVA` sem métricas B em espécie.
- llama.cpp no kernel; GPU guest; bare-metal USB nesta etapa.
- Alterar carga/gate da Linha A.
- Manter `no_gguf_prefill_22l` após avanço Decode sem renomear o bloqueio residual.

## Fora de escopo

- Prefill 22L pleno obrigatório (já tentado E43; pode ser trabalho futuro se Decode mínimo fechar)
- Re-corrida comparable “limpa” além do update honesto de reason/veredito (**B39** se existir no backlog)
- Metal / USB / imagem ESP além do path QEMU
- GPU nativa no guest; multi-GPU; node; agent
- Tokenizer/vocab completo além do necessário ao Decode
- ABI estável / multi-tenant

## Critérios de aceite

- [ ] ADR 0015 (+ docs): preferência A; fallback B; critério inviável; marcadores; proibição de métricas sem Decode
- [ ] Otimização guest documentada (tentada ou descartada com evidência) antes de declarar inviável
- [ ] **Ou** Decode+sampling no guest com `TOKENS_PER_S` / `LOAD_KIND=gguf` medidos + `B_BLOCK` omitido **ou** Decode mínimo documentado com tokens reais **ou** `B_BLOCK` novo sem inventar métricas
- [ ] Gate harness B atualizado ao desfecho; comparable coerente (tokens → possível `COMPROVA`/`REFUTA`/`INCONCLUSIVO` honesto; sem tokens → `INCONCLUSIVO` + reason E44)
- [ ] Motor em `runtime-native/`; kernel só glue/serial
- [ ] `AGENTS.md` cobre cenário; README avaliado (`readme-por-fatia`)
- [ ] Pronto para marcar Etapa 44 `feita` após gate + revisor

## Riscos e rollback

- **Risco:** QEMU debug continua lento demais mesmo com Decode 1 token — Task 2 (release) + Task 3 fallback `no_gguf_decode_perf`.
- **Risco:** pressão por `COMPROVA` / métricas → regra dura: sem Decode real = sem `TOKENS_PER_S`.
- **Risco:** Prefill 2L torna logits “não canônicos” vs A — documentar espécie; comparable pode permanecer `INCONCLUSIVO` mesmo com tokens se checklist exigir 22L — **não** fingir equivalência.
- **Risco:** gate ainda exige `no_gguf_prefill_22l` / `FORWARD_FAIL=no_decode` após sucesso — Task 4 **deve** alinhar scripts.
- **Rollback:** restaurar `FORWARD_FAIL=no_decode` + `B_BLOCK=no_gguf_prefill_22l`; ADR/docs da tentativa permanecem.

## Etapa do roadmap

- **Etapa 44** — Decode + sampling + TOKENS_PER_S canônico na Linha B (`em_andamento`)
- Issue: [#44](https://github.com/eriksonlima/projeto-ia-livre/issues/44) (ex-B38)
- Spec: `specs/decode-tokens-linha-b/`
- Pronto quando: geração canônica em B emite `TOKENS_PER_S` (e marcadores Decode/sampling) honestos; `B_BLOCK` removido ou substituído; gate harness B atualizado.

> **Desfecho preferido:** `DECODE_OK` + `SAMPLING_OK` + `RUNTIME_NATIVE_OK` + `LOAD_KIND=gguf` + `TOKENS_PER_S`/`LOAD_S` medidos + `N_PREDICT=32` (ou N documentado) + `B_BLOCK` omitido.  
> **Desfecho aceitável:** Decode mínimo com subset + métricas reais **ou** `B_BLOCK` novo (ex. `no_gguf_decode_perf`) sem fraude — cumpre o “ou” implícito do Pronto quando **sem** inventar números.
