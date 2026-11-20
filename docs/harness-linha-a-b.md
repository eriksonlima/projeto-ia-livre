# Harness — Hipótese Linha A vs Linha B

Instrumento de medição da **hipótese de pesquisa** do Projeto IA Livre (Etapa 9).  
Ponte: [`architecture.md`](architecture.md) (seção Hipótese) e [`product-context.md`](product-context.md).

> **Isto não prova a hipótese.** Só define carga comparável, roda a **Linha A** no host e reserva o slot da **Linha B** até existir runtime nativo no IA Livre.  
> **Não** confundir com as métricas dos protótipos: [`runtime-inferencia-cpu-metricas.md`](runtime-inferencia-cpu-metricas.md) (Etapa 5) e [`runtime-inferencia-gpu-metricas.md`](runtime-inferencia-gpu-metricas.md) (Etapa 8). Aqueles docs registram o caminho do runtime; **este** é o harness A vs B.

## Definição nesta etapa

| Linha | Significado nesta etapa | Estado |
|-------|-------------------------|--------|
| **A** | Host Linux + `ia-livre-runtime` (llama.cpp), CPU, mesma carga canônica | **Executável** (Task 2+) |
| **B** | IA Livre (kernel + mecanismos) + **runtime nativo** emitindo os mesmos marcadores | **Stub / skip** até o runtime nativo existir |

### Limitação da referência A

“Linux otimizado” na hipótese completa implica tuning de SO (sysctl, isolamento de CPU, etc.). Nesta etapa, A é a **referência pragmática do projeto**: Ubuntu no host de referência + o mesmo binário `ia-livre-runtime` das Etapas 5/8, **sem** campanha de tuning. Evolução de “otimizado” fica para etapas futuras, documentada.

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

Perfil GPU espelhado A/B fica fora do harness v1 (decisão aberta / etapa futura).

## Marcadores (`IA_LIVRE_HARNESS_*`)

Namespace distinto dos protótipos (`IA_LIVRE_INFER_OK`, `IA_LIVRE_LOAD_S`, etc.).

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_HARNESS_LINE=A` \| `B` | Qual linha acabou de rodar |
| `IA_LIVRE_HARNESS_OK` | Corrida da linha concluiu com sucesso (A obrigatório no gate) |
| `IA_LIVRE_HARNESS_LOAD_S=` | Tempo de load (s) |
| `IA_LIVRE_HARNESS_TOKENS_PER_S=` | Throughput de geração |
| `IA_LIVRE_HARNESS_MODEL=` | Identificador do modelo/quant |
| `IA_LIVRE_HARNESS_N_PREDICT=` | Tokens pedidos |
| `IA_LIVRE_HARNESS_ACCEL=cpu` | Modo de aceleração da corrida (v1 = cpu) |
| `IA_LIVRE_HARNESS_B_SKIP` | Linha B não executável ainda (stub); gate permanece 0 se política for skip |

Fora do mínimo v1: joules, p95 multi-request, VRAM multi-tenant (candidatos da architecture).

## Contrato do slot Linha B

1. **Pré-condição:** caminho bootável / runtime nativo no IA Livre que execute a **mesma** carga (GGUF, prompt, `n-predict`, CPU) e emita os mesmos `IA_LIVRE_HARNESS_*` com `LINE=B` + `HARNESS_OK`.
2. **Entrypoint futuro:** `scripts/run-harness-line-b.sh` — hoje só stub (`IA_LIVRE_HARNESS_B_SKIP` + motivo). Alternativa futura (ESP/QEMU) só precisa respeitar o mesmo contrato de marcadores.
3. **Quando B existir:** mesma tabela de carga; mesmo hardware; relatório lado a lado neste documento (baseline A + medição B). **Sem** declarar vitória automática da hipótese — só dados comparáveis.

## Como rodar (visão; scripts na Task 2)

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
./scripts/fetch-model.sh
# Linha A (após Task 2):
./scripts/run-harness-line-a.sh
# Linha B (stub):
./scripts/run-harness-line-b.sh
# Gate (após Task 3):
make verify-harness
```

Detalhes operacionais: `AGENTS.md` → Como rodar / Como verificar (Etapa 9).

## Baseline Linha A

Tabela de exemplo preenchida após a primeira corrida reproduzível (Task 2). Até lá: **pendente** — não inventar números.

| Campo | Valor |
|-------|--------|
| Host | _(preencher na Task 2)_ |
| `IA_LIVRE_HARNESS_LOAD_S` | _(pendente)_ |
| `IA_LIVRE_HARNESS_TOKENS_PER_S` | _(pendente)_ |
| Nota | Baseline da referência A; **não** prova A≻B nem B≻A |

## Relação com Etapas 5 e 8

| Doc | Papel |
|-----|--------|
| `runtime-inferencia-cpu-metricas.md` | Protótipo do caminho CPU no host |
| `runtime-inferencia-gpu-metricas.md` | Protótipo do caminho GPU no host |
| **Este arquivo** | Harness da hipótese A vs B |

O motor da Linha A no host **é** o mesmo `ia-livre-runtime`; o harness **reemite** métricas sob o namespace `HARNESS_` e fixa a metodologia comparável com o slot B.
