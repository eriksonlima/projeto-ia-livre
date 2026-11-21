# Harness A vs B comparável — prova ou refutação (Etapa 22)

Instrumento de **comparação honesta** da hipótese de pesquisa (Linha A vs Linha B).  
Ponte: [`product-context.md`](product-context.md), [`architecture.md`](architecture.md), harness v1 [`harness-linha-a-b.md`](harness-linha-a-b.md).

> **Isto não declara a hipótese comprovada por default.**  
> Enquanto a Linha B for proxy (Etapa 12) ou não tiver a carga GGUF canônica (depende de B15 / Etapa 21), o veredito **obrigatório** é `INCONCLUSIVO`.  
> `make verify-harness` (A GGUF + B proxy) **não** é prova A vs B.

## Relação com o harness v1

| Documento / alvo | Papel |
|------------------|--------|
| [`harness-linha-a-b.md`](harness-linha-a-b.md) + `make verify-harness` | Instrumento v1: A executável; B = proxy — **não** lado a lado |
| [`runtime-nativo-linha-b.md`](runtime-nativo-linha-b.md) | Contrato B mínimo (proxy pós-ExitBoot) |
| [`harness-perfis-a-otimizada-gpu.md`](harness-perfis-a-otimizada-gpu.md) | Perfis A otimizada / GPU — **limites**, não substituto de GGUF A/B |
| **Este arquivo** + `make verify-harness-comparable` | Veredito `COMPROVA` / `REFUTA` / `INCONCLUSIVO` |
| [`harness-corrida-quieta.md`](harness-corrida-quieta.md) | Protocolo serial (Etapa 28): um gate por vez; evidência limpa |

## Pré-condição de comparabilidade (checklist)

Todas as caixas devem estar verdadeiras para permitir `COMPROVA` ou `REFUTA`:

1. **Mesmo modelo/quantização** — TinyLlama 1.1B Chat v1.0 Q4_K_M (ou equivalente documentado da mesma quant).
2. **Mesmo prompt** — `Complete em uma frase: O Projeto IA Livre é`.
3. **Mesmo `n-predict`** — `32` (salvo desvio documentado nas duas linhas).
4. **Mesmo modo de aceleração no par** — no mínimo CPU↔CPU (`n-gpu-layers=0` / equivalente).
5. **Mesmo host de medição** — A e B medidos no mesmo hardware de referência.
6. **B não é proxy** — ausência de `IA_LIVRE_HARNESS_PROXY=` / `LOAD_KIND=proxy`; presença de métricas GGUF em B (`HARNESS_LOAD_S=`, `HARNESS_TOKENS_PER_S=`, `MODEL=` GGUF canônico).

Se qualquer item falhar → veredito = **`INCONCLUSIVO`** (não `COMPROVA`/`REFUTA`).

## Critérios de veredito

### Quando **não** comparável

| Veredito | Condição |
|----------|----------|
| `INCONCLUSIVO` | B proxy; GGUF em B ausente; falha de corrida; checklist incompleto; métricas de tipos diferentes (`TOKENS_PER_S` vs `PROXY_MS`) |

### Quando **comparável** (ambas GGUF, checklist ok)

Critério numérico mínimo (harness comparável v1): razão `R = TOKENS_PER_S(B) / TOKENS_PER_S(A)` com margem de ruído **5%** (corrida única; SO ruidoso).

| Veredito | Condição |
|----------|----------|
| `COMPROVA` | `R ≥ 1.05` — B claramente acima de A (hipótese sustentada nesta corrida) |
| `REFUTA` | `R ≤ 0.95` — B claramente abaixo de A |
| `INCONCLUSIVO` | `0.95 < R < 1.05` — dentro da margem; ou critério não aplicável |

> Uma corrida com margem 5% **não** fecha a hipótese para sempre — é evidência desta execução. Limites abaixo.

## Limites explícitos

- **N=1** por padrão (sem p95 / multi-request).
- **A pragmática** (Ubuntu + runtime host) ≠ campanha completa de «Linux otimizado» (Etapa 18).
- **GPU-B / A otimizada** só entram se ambas as linhas tiverem o mesmo perfil real; senão citam-se como limite, não como vitória.
- **Dependência B15:** sem carga GGUF canônica em B, só `INCONCLUSIVO`.
- **Proxy ≠ tokens:** é **proibido** converter `PROXY_MS` / `PROXY_OPS` em `TOKENS_PER_S` ou inventar throughput B.
- Métricas dos protótipos E5/E8 **não** substituem este relatório.

## Marcadores do relatório

Namespace adicional ao harness v1:

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_HARNESS_VERDICT=COMPROVA\|REFUTA\|INCONCLUSIVO` | Veredito da corrida comparável |
| `IA_LIVRE_HARNESS_VERDICT_REASON=` | Motivo/limites em **uma linha** grepável |

Também reemite (ou preserva na agregação) os marcadores A e B da corrida (`LINE=`, `OK`, load/tokens ou proxy).

## O que é proibido

- Declarar hipótese comprovada sem checklist de comparabilidade.
- Inventar `TOKENS_PER_S` (ou load GGUF) para B proxy.
- Tratar `make verify-harness` (B proxy) como se já fosse prova A vs B.
- Equivalência inventada PROXY↔tokens.
- GPU manager / multi-GPU como critério desta etapa.

## Como rodar

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

./scripts/fetch-model.sh
cargo build -p ia-livre-runtime

# Corrida A + B + veredito (com B proxy → INCONCLUSIVO)
./scripts/run-harness-a-b-comparable.sh

# Gate do instrumento comparável
make verify-harness-comparable
```

Timeout: `VERIFY_HARNESS_COMPARABLE_TIMEOUT` (default herda `VERIFY_HARNESS_TIMEOUT`, 300s).  
Detalhes: `AGENTS.md` → Como rodar / Como verificar (Etapa 22).

## Estado atual (host de referência)

Com B = proxy + attn/FFN/prefill layer0 (Etapa 33, `no_gguf_full_prefill`): o instrumento **deve** emitir `INCONCLUSIVO` com reason `E33_no_gguf_full_prefill_22L_kv_inviable` (bloqueio estrutural 22L/KV — ≠ ausência genérica de tokens). Hipótese **não** comprovada nem refutada. ADR [`0013`](adr/0013-geracao-canonica-fatiada-linha-b.md).

**A_otimizada (opt-in, Etapa 34):** `IA_LIVRE_HARNESS_A_PROFILE=A_otimizada` usa `run-harness-line-a-optimized.sh` no lado A; veredito permanece honesto (ainda `INCONCLUSIVO` enquanto B não tiver tokens). Gate dedicado: `make verify-harness-a-otimizada`.

Para medição sem contenção de benchmarks: seguir [`harness-corrida-quieta.md`](harness-corrida-quieta.md).
