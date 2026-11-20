# Métricas — Runtime mínimo de inferência (CPU)

Protótipo da **Etapa 5** (camada 2). Valores obtidos no **host de referência** do autor.

> **Não** é o benchmark da hipótese de pesquisa (Linha A Linux otimizado vs Linha B IA Livre). Só registra o caminho mínimo load + geração em CPU.

## Ambiente

| Campo | Valor |
|-------|--------|
| Host | Acer Nitro 5 (`eriksonlima-Nitro-AN515-51`) |
| OS | Ubuntu 24.04 (kernel 7.0.0-38-generic) |
| CPU | Intel Core i5-7300HQ @ 2.50 GHz (4 threads) |
| RAM | 16 GiB |
| Backend | `llama-cpp-2` 0.1.161 / llama.cpp, **CPU** (`n_gpu_layers=0`) |
| Modelo | TinyLlama 1.1B Chat v1.0 Q4_K_M GGUF (`models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf`) |
| Prompt | `Complete em uma frase: O Projeto IA Livre é` |
| `--n-predict` | 32 (gate) |
| Sampler | greedy |

## Resultados (primeira medição estável)

| Métrica | Marcador | Valor |
|---------|----------|-------|
| Tempo de load (modelo + contexto) | `IA_LIVRE_LOAD_S` | **0.988 s** |
| Throughput de geração | `IA_LIVRE_TOKENS_PER_S` | **11.557 tok/s** |
| Sucesso | `IA_LIVRE_INFER_OK` | presente |

Comando:

```bash
make verify-runtime
# ou:
cargo run -p ia-livre-runtime -- --model models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf --n-predict 32
```

Data da medição: 2026-11-20.

## Interpretação

Números são baseline do protótipo no hardware acima. Variam com carga do sistema, temperatura e threads do llama.cpp. Para a hipótese de pesquisa, será necessário harness comparável (mesmo modelo, quantização e carga) — fora desta etapa.
