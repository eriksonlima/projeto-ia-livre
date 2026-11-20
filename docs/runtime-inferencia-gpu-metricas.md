# Métricas — Runtime com aceleração GPU (host)

Protótipo da **Etapa 8** (camada 2 no host). Valores obtidos no **host de referência** do autor.

> **Não** é o benchmark da hipótese de pesquisa (Linha A vs Linha B). Só registra o caminho load + geração com offload GPU via llama.cpp, comparável às métricas CPU da Etapa 5.  
> Harness A vs B: [`harness-linha-a-b.md`](harness-linha-a-b.md).  
> **Host ≠ GPU manager nativo / multi-GPU:** este doc é Etapa 8 (ADR 0002). Desenho candidato: [`desenho-gpu-manager-multi-gpu.md`](desenho-gpu-manager-multi-gpu.md) / ADR [`0006`](adr/0006-gpu-manager-multi-gpu.md).

## Ambiente

| Campo | Valor |
|-------|--------|
| Host | Acer Nitro 5 (`eriksonlima-Nitro-AN515-51`) |
| OS | Ubuntu 24.04 (kernel 7.0.0-38-generic) |
| CPU | Intel Core i5-7300HQ @ 2.50 GHz (4 threads) |
| GPU | NVIDIA GeForce GTX 1050 (4 GiB); também Intel HD 630 |
| Driver NVIDIA | 535.309.01 (CUDA *driver* 12.2; **sem** `nvcc` / CUDA Toolkit no PATH) |
| Backend efetivo | `llama-cpp-2` 0.1.161 / llama.cpp, feature Cargo **`vulkan`** |
| Backend canônico (ADR 0002) | CUDA — **inviável neste host** sem toolkit; Vulkan = alternativa documentada |
| Vulkan SDK (build) | LunarG 1.3.296.0 em `~/.local/opt/1.3.296.0` (user-space) |
| Modelo | TinyLlama 1.1B Chat v1.0 Q4_K_M GGUF (mesmo da Etapa 5) |
| Prompt | `Complete em uma frase: O Projeto IA Livre é` |
| `--n-predict` | 32 |
| `--n-gpu-layers` | 99 (offload máximo pragmático; 23/23 layers no TinyLlama) |
| Sampler | greedy |

## Resultados (primeira medição estável)

| Métrica | Marcador | Valor |
|---------|----------|-------|
| Tempo de load (modelo + contexto) | `IA_LIVRE_LOAD_S` | **2.564 s** |
| Throughput de geração | `IA_LIVRE_TOKENS_PER_S` | **54.750 tok/s** |
| Aceleração | `IA_LIVRE_ACCEL` | **vulkan** |
| Layers pedidas | `IA_LIVRE_N_GPU_LAYERS` | **99** |
| Sucesso | `IA_LIVRE_INFER_OK` | presente |

Observação de runtime (stderr do llama.cpp): `offloaded 23/23 layers to GPU` (dispositivo Vulkan NVIDIA GTX 1050).

## Comparável à Etapa 5 (mesmo modelo / prompt / n-predict)

| Modo | `IA_LIVRE_ACCEL` | Load (s) | tok/s | Fonte |
|------|------------------|----------|-------|--------|
| CPU (`n_gpu_layers=0`, build default) | `cpu` | ~0.96–1.0 | ~10.7–11.6 | `docs/runtime-inferencia-cpu-metricas.md` + re-medição no gate |
| GPU Vulkan (`--features vulkan`, `--n-gpu-layers 99`) | `vulkan` | 2.564 | 54.750 | esta doc |

Load GPU maior que CPU nesta medição (upload de tensores / init Vulkan); throughput de geração ~5× o CPU no mesmo host.

Comando (host com Vulkan SDK / libs):

```bash
export VULKAN_SDK="$HOME/.local/opt/1.3.296.0/x86_64"   # ajuste se outro path
export PATH="$VULKAN_SDK/bin:$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LD_LIBRARY_PATH="$VULKAN_SDK/lib:${LD_LIBRARY_PATH:-}"

cargo run -p ia-livre-runtime --features vulkan -- \
  --model models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
  --n-predict 32 \
  --n-gpu-layers 99
```

Data da medição: 2026-11-20.

## Fallback CPU

| Situação | Comportamento |
|----------|----------------|
| Build default (sem `--features`) | CPU; `make verify-runtime` |
| `--features vulkan` + `--n-gpu-layers 0` | CPU no mesmo binário GPU-capable |
| Sem GPU / toolkit / feature | Não emitir `IA_LIVRE_ACCEL≠cpu` como sucesso de aceleração; usar CPU ou gate skip (Task 3) |
| CUDA | Preferido quando houver toolkit (`nvcc`); neste host faltou → Vulkan |

## Interpretação

Prova de **caminho** de aceleração no host (camada 2), não de GPU manager no kernel nem multi-GPU. Números variam com carga, driver e qual dispositivo Vulkan o llama.cpp escolhe (Intel iGPU vs NVIDIA).
