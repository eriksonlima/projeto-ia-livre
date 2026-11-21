# Harness — Perfis A otimizada e GPU (metodologia)

Evolução metodológica do harness v1 (Etapas 9/12). **Etapas 18 / 34 / 56.**  
**Não** prova a hipótese Linha A vs Linha B. **Não** substitui o gate `make verify-harness`.

Harness v1: [`harness-linha-a-b.md`](harness-linha-a-b.md).  
Linha B: [`runtime-nativo-linha-b.md`](runtime-nativo-linha-b.md).  
Comparable: [`harness-a-b-comparavel.md`](harness-a-b-comparavel.md).

## A pragmática vs A otimizada

| Perfil | O que é | Estado |
|--------|---------|--------|
| **A pragmática** (harness v1) | Ubuntu no host + `ia-livre-runtime` CPU | **Gate** (`run-harness-line-a.sh`) |
| **A otimizada** | Mesma carga + checklist isolamento/tuning | **Executável** — `make verify-harness-a-otimizada` (E34); **não** substitui `verify-harness` |
| **A_gpu** (Etapa 56) | Mesma carga + accel host (`cuda`/`vulkan`, `--n-gpu-layers` > 0) | **Executável** — `make verify-harness-gpu` (opt-in); skip sem GPU |

Otimizar A **melhora a referência**; **não** prova A≻B nem B≻A.

### Checklist mínimo — perfil «Linux otimizado» (Linha A / E34)

1. **Governor:** CPU em `performance` (ou equivalente) durante a corrida.
2. **Afinidade:** pin do runtime (`taskset` / `isolcpus`) quando possível.
3. **Ruído de SO:** sessão mínima; anotar thermal/turbo se afetar.
4. **Runtime:** mesma carga canônica; `--n-gpu-layers 0` neste perfil (CPU).
5. **Relatório:** `perfil=A_pragmatica` vs `A_otimizada`; `HARNESS_LOAD_S` / `TOKENS_PER_S`.

Variáveis: `IA_LIVRE_HARNESS_N_THREADS`, `IA_LIVRE_HARNESS_TASKSET_CPUS`, `IA_LIVRE_HARNESS_GOVERNOR_SKIP=1`.

### Carga canônica (inalterada)

| Item | Valor |
|------|--------|
| Modelo | TinyLlama 1.1B Chat v1.0 Q4_K_M |
| Prompt | `Complete em uma frase: O Projeto IA Livre é` |
| `--n-predict` | `32` |
| Marcadores | namespace `IA_LIVRE_HARNESS_*` |

## Perfil simétrico CPU — `sym_cpu` (Etapa 64)

| Peça | Valor |
|------|--------|
| Accel | A **e** B com `HARNESS_ACCEL=cpu` |
| Perfil | `IA_LIVRE_HARNESS_PROFILE=sym_cpu` |
| Par | `IA_LIVRE_HARNESS_ACCEL_PAIR=cpu+cpu` |
| Veredito | `INCONCLUSIVO` (espécie subset / ADR 0022) — **≠** assimetria accel |
| Gate | `make verify-harness-sym-cpu` |
| ADR | [`0023`](adr/0023-simetria-gpu-harness-inviavel.md) — simetria **GPU** inviável até B60 |

Scripts: `run-harness-a-b-sym-cpu.sh` / `verify-harness-sym-cpu.sh`.

## Perfil GPU espelhado A/B (Etapa 56) — **assimétrico**

> **Não** é simetria GPU. Ver ADR [`0023`](adr/0023-simetria-gpu-harness-inviavel.md).

### Linha A — `A_gpu` (host)

- Build com feature `cuda` (canônico se `nvcc`) ou `vulkan` (alternativa).
- `--n-gpu-layers` > 0 (default `99`).
- `IA_LIVRE_HARNESS_PROFILE=A_gpu`
- `IA_LIVRE_HARNESS_ACCEL=cuda|vulkan` (**≠** `cpu`)
- `IA_LIVRE_HARNESS_LOAD_S` / `TOKENS_PER_S` / `OK`

Script: `scripts/run-harness-line-a-gpu.sh`.

### Linha B — espelho honesto (assimétrico)

B **gera** tokens subset (E44) no QEMU **sem** acelerador guest.  
**Proibido:** inventar `HARNESS_ACCEL=cuda|vulkan` em B; inventar espécie canônica.

Agregação: `scripts/run-harness-a-b-gpu.sh` — A_gpu + B existente; veredito permanece **INCONCLUSIVO** (`E56_A_gpu_B_subset_accel_asymmetric`).

### Skip

| Variável | Efeito |
|----------|--------|
| `VERIFY_HARNESS_GPU_SKIP=1` | Skip exit 0 |
| Sem GPU / falha build feature | `IA_LIVRE_HARNESS_GPU_SKIP=…` exit 0 |

## Gate

**Default:** `make verify-harness` (A CPU + B).  
**A_otimizada:** `make verify-harness-a-otimizada`.  
**sym_cpu (Etapa 64):** `make verify-harness-sym-cpu` — mesmo accel CPU; opt-in.  
**A_gpu + B (Etapa 56):** `make verify-harness-gpu` — opt-in **assimétrico**; **não** substitui v1 nem `sym_cpu`.

Anti-fraude: sem `COMPROVA`/`REFUTA` por estes perfis GPU; sem ACCEL GPU fingido em B.
