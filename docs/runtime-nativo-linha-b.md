# Runtime nativo / Linha B (mínimo) — Etapa 12

Caminho **honesto** para a Linha B no IA Livre (QEMU), sem TinyLlama no kernel e **sem** comprovar a hipótese A vs B.

Ponte harness: [`harness-linha-a-b.md`](harness-linha-a-b.md).  
Perfis A otimizada / GPU (metodologia; GPU-B futuro): [`harness-perfis-a-otimizada-gpu.md`](harness-perfis-a-otimizada-gpu.md).  
Pré-requisito kernel: [`kernel-pos-boot-services.md`](kernel-pos-boot-services.md) (`EXIT_BOOT_OK`).

## Decisão

| Peça | Escolha |
|------|---------|
| Ambiente | QEMU/UEFI — **não** host `ia-livre-runtime` (isso é Linha A) |
| Carga | Proxy: microbenchmark CPU/memória **pós-ExitBoot** |
| GGUF TinyLlama | **Ausente** nesta etapa |
| Hipótese | **Não** comprovada; métricas B **não** comparáveis a A |

> O desenho candidato que *diferenciaria* B de A de forma model-aware (classes `Weights`/`KvCache` + fases Prefill/Decode) está em [`desenho-memoria-scheduler-nativo.md`](desenho-memoria-scheduler-nativo.md) / ADR 0003. A **implementação mínima** no kernel (Etapa 19) está em [`memoria-scheduler-impl-minima.md`](memoria-scheduler-impl-minima.md) (`MEM_SCHED_*` / `TYPED_*`). O **consumidor** (shim host / evidência de contrato) é a Etapa 20 — ver [`runtime-contrato-nativo.md`](runtime-contrato-nativo.md). Este proxy `NATIVE_BENCH_*` **não** realiza o contrato sozinho; o harness B (E20) **também** observa `MEM_SCHED_*` e reemite `HARNESS_CONTRACT_*`. Evidência de contrato **≠** carga GGUF canônica e **não** emite `TOKENS_PER_S`.

## Marcadores kernel (COM1, após `EXIT_BOOT_OK`)

Ordem: `MEM_SCHED_*` / `TYPED_*` (E19) **antes** do proxy.

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_NATIVE_BENCH_BEGIN` | Início do proxy |
| `IA_LIVRE_NATIVE_BENCH_OPS=<n>` | Operações medidas |
| `IA_LIVRE_NATIVE_BENCH_MS=<n>` | Duração aproximada (ms; TSC ÷ 2e9 documentado) |
| `IA_LIVRE_NATIVE_BENCH_OK` | Proxy concluído |

## O que o harness B reemite

`LINE=B`, `HARNESS_OK`, `PROXY=post_exit_microbench`, `LOAD_KIND=proxy`, `PROXY_MS=`, `PROXY_OPS=`, `MODEL=proxy-post-exit-v1`, `N_PREDICT=0`, mais `HARNESS_CONTRACT_BACKEND=native_qemu` + `HARNESS_CONTRACT_MEM_SCHED=OK` + tipados/fases (E20).

**Proibido:** `TOKENS_PER_S`, `LOAD_S` como load GGUF, nome do modelo TinyLlama, inventar números.

## Como observar

```bash
make verify          # kernel até NATIVE_BENCH_OK (Task 2+)
./scripts/run-harness-line-b.sh
make verify-harness  # A (GGUF) + B (proxy)
```

## Etapa 21 — Caminho GGUF canônico em B (mínimo honesto)

Contrato da etapa: [`../specs/carga-gguf-linha-b/spec.md`](../specs/carga-gguf-linha-b/spec.md).  
Ponte harness: [`harness-linha-a-b.md`](harness-linha-a-b.md) (slot B).

### Carga canônica alvo (igual à Linha A)

| Item | Valor |
|------|--------|
| Modelo | TinyLlama 1.1B Chat v1.0 |
| Quantização | Q4_K_M (GGUF) |
| Arquivo | `models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf` |
| Prompt | `Complete em uma frase: O Projeto IA Livre é` |
| `--n-predict` | `32` |
| Aceleração (v1) | CPU (`n-gpu-layers=0`) |

### Pré-requisitos fortes

| Dep | Papel |
|-----|--------|
| **Etapa 19 / B13** | Memória model-aware + scheduler por fases (impl. mínima) no kernel pós-ExitBoot |
| **Etapa 20 / B14** | Runtime falando o contrato nativo (além do proxy) |

Sem B13+B14 verificáveis, **não** há carga GGUF real em B. O proxy da Etapa 12 **permanece** o instrumento mínimo do gate.

### Três `LOAD_KIND` (mutuamente honestos)

| `LOAD_KIND` | Quando | Métricas |
|-------------|--------|----------|
| `proxy` | Etapa 12 — default atual do gate B | `PROXY_MS` / `PROXY_OPS` — **sem** `TOKENS_PER_S` |
| `blocked` | Etapa 21 — GGUF ainda inviável | `B_BLOCK=<motivo>` (ex. `no_gguf_path`; legado `awaiting_b13_b14`); **sem** inventar load/tokens |
| `gguf` | Etapa 21 — só com carga real no QEMU/IA Livre | `LOAD_S` / `TOKENS_PER_S` **medidos**; `MODEL` = GGUF canônico; `N_PREDICT=32` |

### Marcadores — sucesso GGUF em B (futuro / condicionado)

Só após evidência real de carga no ambiente IA Livre:

- `IA_LIVRE_HARNESS_LINE=B`
- `IA_LIVRE_HARNESS_OK`
- `IA_LIVRE_HARNESS_LOAD_KIND=gguf`
- `IA_LIVRE_HARNESS_MODEL=` (arquivo TinyLlama canônico)
- `IA_LIVRE_HARNESS_N_PREDICT=32`
- `IA_LIVRE_HARNESS_LOAD_S=` / `IA_LIVRE_HARNESS_TOKENS_PER_S=` (**medidos**)
- `IA_LIVRE_HARNESS_ACCEL=cpu`

**Não** emitir `PROXY=…` neste caminho.

### Marcadores — bloqueio honesto (default enquanto GGUF real ausente)

Informativo / stub; **não** substitui o caminho proxy do gate mínimo:

- `IA_LIVRE_HARNESS_LINE=B`
- `IA_LIVRE_HARNESS_LOAD_KIND=blocked` (via `LOAD_KIND_GGUF=blocked` no modo `block-status`)
- `IA_LIVRE_HARNESS_B_BLOCK=no_gguf_path` (deps 19/20 ok; sem loader GGUF no QEMU)
- `IA_LIVRE_HARNESS_GGUF_STATUS=blocked`
- `IA_LIVRE_HARNESS_CONTRACT_READY=1` (MEM_SCHED + fases observados — Etapas 19/20)

**Proibido** em `blocked` e em `proxy`: inventar `TOKENS_PER_S` / `LOAD_S` GGUF; apontar `MODEL=` TinyLlama sem carga real; declarar hipótese comprovada.

### Integração harness ↔ contrato (Etapa 21 Task 3)

Com Etapas 19/20 verificáveis no serial QEMU, `scripts/run-harness-line-b.sh`:

1. Exige `MEM_SCHED_OK` + tipados + fases Prefill/Decode + `NATIVE_BENCH_*` (contrato + proxy).
2. Reemite `HARNESS_CONTRACT_*` e **`HARNESS_CONTRACT_READY=1`** (deps nativas ok para *preparar* a carga).
3. Declara o **alvo** canônico sem fingir carga: `GGUF_TARGET_MODEL=`, `GGUF_TARGET_N_PREDICT=32`, `GGUF_TARGET_PROMPT=canonical_v1`.
4. Declara `GGUF_NATIVE_LOADER=absent` + `GGUF_STATUS=blocked` + `B_BLOCK=no_gguf_path`.
5. **Não** emite `TOKENS_PER_S` / `LOAD_S` / `LOAD_KIND=gguf` / `MODEL=` TinyLlama.

`HARNESS_MODEL=` permanece `proxy-post-exit-v1`. Rodar `ia-livre-runtime` no host continua sendo **Linha A**.

### Estado atual (após merge E19/E20 + Tasks 3–4)

- ~~`awaiting_b13_b14`~~ — Etapas 19 e 20 **feitas**; `CONTRACT_READY=1` no harness B.
- Bloqueio final honesto: **`no_gguf_path`** — sem loader GGUF / FS maduro / motor de inferência no kernel UEFI pós-ExitBoot; proxy E12 = instrumento mínimo do gate.
- Hipótese A vs B **não** comprovada. GPU manager **fora**. Métricas em espécie em B ficam para quando existir loader real (fora do mínimo desta etapa).
