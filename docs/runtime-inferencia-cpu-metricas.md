# Métricas — Runtime mínimo de inferência (CPU)

Protótipo da **Etapa 5** (camada 2). Valores obtidos no **host de referência** do autor.

> **Não** é o benchmark da hipótese de pesquisa (Linha A Linux otimizado vs Linha B IA Livre). Só registra o caminho mínimo load + geração em CPU.  
> Harness A vs B: [`harness-linha-a-b.md`](harness-linha-a-b.md).

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

Data da medição: 2026-11-20 (durante desenvolvimento; carga do sistema não controlada).

## Remediação serial (máquina sem gates paralelos)

Reexecução **um gate por vez** + 5 corridas solo do runtime (2026-11-20 ~22:42–22:43). Host ainda com load residual do desktop (~2–4), mas **sem** outros `verify-runtime` / harness / agent concorrentes.

### `make verify-runtime` (série)

| Métrica | Valor |
|---------|--------|
| `IA_LIVRE_LOAD_S` | **0.970 s** |
| `IA_LIVRE_TOKENS_PER_S` | **13.241 tok/s** |
| Gate | `GATE_OK` |

### Cinco corridas solo (`cargo run -p ia-livre-runtime -- … --n-predict 32`)

| # | `LOAD_S` | `TOKENS_PER_S` |
|---|----------|----------------|
| 1 | 0.961 | 13.427 |
| 2 | 0.980 | 13.419 |
| 3 | 0.954 | 13.361 |
| 4 | 0.984 | 13.702 |
| 5 | 0.962 | 13.124 |

**Mediana tok/s:** **13.419** (referência limpa para este host).  
**Faixa:** 13.124–13.702.

> Corridas sob contenção (vários agentes/gates em paralelo no mesmo host de 4 threads) deprimem o T/s e **não** devem ser usadas como capacidade do hardware. Gates do projeto só exigem a presença dos marcadores — não um mínimo de tok/s.

Comando:

```bash
make verify-runtime
# ou:
cargo run -p ia-livre-runtime -- --model models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf --n-predict 32
```

## Interpretação

Números são baseline do protótipo no hardware acima. Variam com carga do sistema, temperatura e threads do llama.cpp. Para a hipótese de pesquisa, use o harness comparável (`make verify-harness-comparable`) com máquina quieta e **sem** gates concorrentes — ver [`harness-a-b-comparavel.md`](harness-a-b-comparavel.md).
