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

> O desenho candidato que *diferenciaria* B de A de forma model-aware (classes `Weights`/`KvCache` + fases Prefill/Decode) está em [`desenho-memoria-scheduler-nativo.md`](desenho-memoria-scheduler-nativo.md) / ADR 0003. A **implementação mínima** no kernel (Etapa 19) está em [`memoria-scheduler-impl-minima.md`](memoria-scheduler-impl-minima.md) (`MEM_SCHED_*` / `TYPED_*`). Este proxy `NATIVE_BENCH_*` **não** realiza esse contrato — namespaces distintos; hipótese **ainda não** comprovada.

## Marcadores kernel (COM1, após `EXIT_BOOT_OK`)

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_NATIVE_BENCH_BEGIN` | Início do proxy |
| `IA_LIVRE_NATIVE_BENCH_OPS=<n>` | Operações medidas |
| `IA_LIVRE_NATIVE_BENCH_MS=<n>` | Duração aproximada (ms; TSC ÷ 2e9 documentado) |
| `IA_LIVRE_NATIVE_BENCH_OK` | Proxy concluído |

## O que o harness B reemite

`LINE=B`, `HARNESS_OK`, `PROXY=post_exit_microbench`, `LOAD_KIND=proxy`, `PROXY_MS=`, `PROXY_OPS=`, `MODEL=proxy-post-exit-v1`, `N_PREDICT=0`.

**Proibido:** `TOKENS_PER_S`, `LOAD_S` como load GGUF, nome do modelo TinyLlama, inventar números.

## Como observar

```bash
make verify          # kernel até NATIVE_BENCH_OK (Task 2+)
./scripts/run-harness-line-b.sh
make verify-harness  # A (GGUF) + B (proxy)
```
