# Harness — Hipótese Linha A vs Linha B

Instrumento de medição da **hipótese de pesquisa** do Projeto IA Livre (Etapa 9).  
Ponte: [`architecture.md`](architecture.md) (seção Hipótese) e [`product-context.md`](product-context.md).

> **Isto não prova a hipótese.** Define carga canônica na Linha A e um **caminho nativo mínimo** na Linha B (Etapa 12 = proxy pós-ExitBoot — **não** TinyLlama no IA Livre).  
> **A e B nesta etapa não são comparáveis** lado a lado para a hipótese (`TOKENS_PER_S` vs `PROXY_MS`).  
> **Não** confundir com as métricas dos protótipos: [`runtime-inferencia-cpu-metricas.md`](runtime-inferencia-cpu-metricas.md) (Etapa 5) e [`runtime-inferencia-gpu-metricas.md`](runtime-inferencia-gpu-metricas.md) (Etapa 8).

**Comparável (prova / refutação / inconclusivo):** Etapa 22 — [`harness-a-b-comparavel.md`](harness-a-b-comparavel.md) + `make verify-harness-comparable`. Enquanto B for proxy, o veredito honesto é `INCONCLUSIVO`.

Contrato do caminho B mínimo: [`runtime-nativo-linha-b.md`](runtime-nativo-linha-b.md).

## Definição nesta etapa

| Linha | Significado nesta etapa | Estado |
|-------|-------------------------|--------|
| **A** | Host Linux + `ia-livre-runtime` (llama.cpp), CPU, carga canônica GGUF | **Executável** |
| **B** | IA Livre (QEMU) + **proxy** pós-ExitBoot (microbenchmark); emite `HARNESS_*` com `LINE=B` | **Execução real mínima** (Etapa 12) — **não** é carga TinyLlama |

### Limitação da referência A

“Linux otimizado” na hipótese completa implica tuning de SO (sysctl, isolamento de CPU, etc.). No harness **v1** (gate), A é a **referência pragmática**: Ubuntu no host de referência + o mesmo binário `ia-livre-runtime` das Etapas 5/8, **sem** campanha de tuning.  
Metodologia dos perfis **A otimizada** e **GPU espelhado A/B** (Etapa 18): [`harness-perfis-a-otimizada-gpu.md`](harness-perfis-a-otimizada-gpu.md) — **não** substituem o gate v1 e **não** provam a hipótese.

### O que **não** conta como Linha B

- Rodar `ia-livre-runtime` no Linux host (isso é Linha A).
- Medir só o boot UEFI (`IA_LIVRE_BOOT_OK`) sem inferência.
- Copiar números das docs de métricas E5/E8.
- Inventar throughput/load para B.

## Carga canônica (harness v1)

| Item | Valor |
|------|--------|
| Modelo | TinyLlama 1.1B Chat v1.0 Q4_K_M |
| Arquivo | `models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf` |
| Prompt | `Complete em uma frase: O Projeto IA Livre é` |
| `--n-predict` | `32` |
| Aceleração | **CPU** (`--n-gpu-layers 0`) |
| Hardware | Mesmo host para A e (no futuro) B — ver tabela baseline |

Perfil GPU espelhado A/B fica **fora do gate** do harness v1; metodologia documentada na Etapa 18: [`harness-perfis-a-otimizada-gpu.md`](harness-perfis-a-otimizada-gpu.md) (GPU-B só quando houver GGUF/acelerador real em B).

## Marcadores (`IA_LIVRE_HARNESS_*`)

Namespace distinto dos protótipos (`IA_LIVRE_INFER_OK`, `IA_LIVRE_LOAD_S`, etc.).

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_HARNESS_LINE=A` \| `B` | Qual linha acabou de rodar |
| `IA_LIVRE_HARNESS_OK` | Corrida da linha concluiu com sucesso (A obrigatório no gate) |
| `IA_LIVRE_HARNESS_LOAD_S=` | Tempo de load (s) — **só Linha A** (GGUF) |
| `IA_LIVRE_HARNESS_TOKENS_PER_S=` | Throughput — **só Linha A**; **proibido** em B nesta etapa |
| `IA_LIVRE_HARNESS_MODEL=` | A: GGUF; B: `proxy-post-exit-v1` (honesto) |
| `IA_LIVRE_HARNESS_N_PREDICT=` | A: 32; B: `0` |
| `IA_LIVRE_HARNESS_ACCEL=cpu` | Modo de aceleração |
| `IA_LIVRE_HARNESS_PROXY=post_exit_microbench` | **Só B** — carga é proxy, não GGUF |
| `IA_LIVRE_HARNESS_LOAD_KIND=proxy` | **Só B** |
| `IA_LIVRE_HARNESS_PROXY_MS=` / `PROXY_OPS=` | **Só B** — métricas medidas do microbenchmark |
| `IA_LIVRE_HARNESS_CONTRACT_BACKEND=native_qemu` | **Só B (E20)** — serial E19 observado |
| `IA_LIVRE_HARNESS_CONTRACT_MEM_SCHED=OK` | **Só B** — `MEM_SCHED_OK` no serial |
| `IA_LIVRE_HARNESS_CONTRACT_TYPED_*=OK` / `PHASE_*=OK` | **Só B** — evidência tipada/fases |
| `IA_LIVRE_HARNESS_B_SKIP` | Legado do stub; **não** no caminho de sucesso |

Fora do mínimo v1: joules, p95 multi-request, VRAM multi-tenant (candidatos da architecture).

## Contrato do slot Linha B

### Etapa 12 — proxy mínimo (+ Etapa 20 — evidência de contrato)

1. Kernel emite `EXIT_BOOT_OK` + `MEM_SCHED_*` / `TYPED_*` (E19) + `NATIVE_BENCH_*` (COM1).
2. `scripts/run-harness-line-b.sh` sobe QEMU, captura serial e reemite `HARNESS_LINE=B` + `HARNESS_OK` + marcadores **proxy** + `HARNESS_CONTRACT_*`.
3. Proxy **permanece** (`LOAD_KIND=proxy`); evidência de contrato **≠** GGUF canônico.
4. **Não** declara hipótese comprovada; A e B **não** são lado a lado comparáveis até B rodar a carga canônica GGUF.

### Contrato nativo (Etapa 20) vs Linha B

- **Shim host:** gate `make verify-runtime-contract` — **não** é Linha B.
- **QEMU + E19:** evidência reemitida no harness B (`HARNESS_CONTRACT_*`) — ver [`runtime-contrato-nativo.md`](runtime-contrato-nativo.md).
- **Proibido** `TOKENS_PER_S` / fingir GGUF em B.

### Etapa 21 — Carga GGUF canônica em B (mínimo honesto)

Contrato: [`runtime-nativo-linha-b.md`](runtime-nativo-linha-b.md) (seção Etapa 21) + [`../specs/carga-gguf-linha-b/spec.md`](../specs/carga-gguf-linha-b/spec.md).  
Deps 19/20 (MEM_SCHED + contrato) estão no caminho B; carga TinyLlama Q4_K_M em B ainda é o alvo desta etapa (**ou** bloqueio final honesto). Desenho: [`desenho-memoria-scheduler-nativo.md`](desenho-memoria-scheduler-nativo.md) (ADR 0003) — **desenho ≠ prova**.

| `LOAD_KIND` | Papel no slot B |
|-------------|-----------------|
| `proxy` | Etapa 12 — **default do gate** enquanto GGUF real não existir |
| `blocked` | Bloqueio honesto (`B_BLOCK=…`, ex. `awaiting_b13_b14`) — **sem** inventar `TOKENS_PER_S`/`LOAD_S` |
| `gguf` | Carga canônica real no QEMU/IA Livre (TinyLlama Q4_K_M, prompt, `n-predict=32`) com métricas **medidas** |

**Deps:** Etapas 19–32 **feitas** no path B. Estado atual do gate: `GGUF_NATIVE_LOADER=blockio_full` + tokenize/embed/camada parcial + `B_BLOCK=no_gguf_decode` (ADR [`0013`](adr/0013-geracao-canonica-fatiada-linha-b.md)). Proxy permanece até `LOAD_KIND=gguf` com tokens medidos.  
Quando A e B tiverem `LOAD_KIND=gguf` com métricas em espécie, a **prova/refutação** usa o instrumento comparável (Etapa 22) — **não** declarar vitória sem `TOKENS_PER_S` em B.

### Métricas em espécie em B

1. ~~B13 + B14~~ — Etapas 19/20 **feitas** (`CONTRACT_READY=1`).  
2. ~~Loader + mapa/dequant/op + tokenize/embed/camada~~ — Etapas 26–32.  
3. **Geração canônica (Prefill/Decode/sampling)** — ainda **ausente** (`no_gguf_decode`). `TOKENS_PER_S` em B = etapa futura (ex. B26).  
Desenho: [`desenho-memoria-scheduler-nativo.md`](desenho-memoria-scheduler-nativo.md) (ADR 0003) — **desenho ≠ prova**.
## Como rodar

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
./scripts/fetch-model.sh
cargo build -p ia-livre-runtime

# Linha A (host Linux + runtime)
./scripts/run-harness-line-a.sh

# Linha B (QEMU — proxy + evidência MEM_SCHED; não é TinyLlama)
./scripts/run-harness-line-b.sh

# Gate (A GGUF + B proxy + HARNESS_CONTRACT_*)
make verify-harness
```

Overrides opcionais: `IA_LIVRE_MODEL`, `IA_LIVRE_HARNESS_PROMPT`, `IA_LIVRE_HARNESS_N_PREDICT`, `IA_LIVRE_RUNTIME_BIN`.  
Detalhes: `AGENTS.md` → Como rodar / Como verificar (Etapa 9).

## Baseline Linha A (exemplo no host de referência)

Corrida única com a carga canônica (`n-predict=32`, CPU). **Baseline da referência**, não prova da hipótese.

| Campo | Valor |
|-------|--------|
| Host | Acer Nitro 5 (`eriksonlima-Nitro-AN515-51`) |
| OS | Ubuntu 24.04 (kernel 7.0.0-38-generic) |
| CPU | Intel Core i5-7300HQ @ 2.50 GHz (4 threads) |
| RAM | 16 GiB |
| Backend | `ia-livre-runtime` / llama.cpp, CPU (`n_gpu_layers=0`) |
| Modelo | `tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf` |
| `IA_LIVRE_HARNESS_LOAD_S` | 1.056 |
| `IA_LIVRE_HARNESS_TOKENS_PER_S` | 14.846 |
| Data | 2026-11-20 |
| Nota | Baseline A; **não** prova A≻B nem B≻A; números variam com carga do sistema |

## Relação com Etapas 5 e 8

| Doc | Papel |
|-----|--------|
| `runtime-inferencia-cpu-metricas.md` | Protótipo do caminho CPU no host |
| `runtime-inferencia-gpu-metricas.md` | Protótipo do caminho GPU no host |
| **Este arquivo** | Harness da hipótese A vs B |

O motor da Linha A no host **é** o mesmo `ia-livre-runtime`; o harness **reemite** métricas sob o namespace `HARNESS_` e fixa a metodologia comparável com o slot B.
