# Harness — Perfis A otimizada e GPU (metodologia)

Evolução metodológica do harness v1 (Etapas 9/12). **Etapa 18.**  
**Não** prova a hipótese Linha A vs Linha B. **Não** substitui o gate `make verify-harness`.

Harness v1: [`harness-linha-a-b.md`](harness-linha-a-b.md).  
Linha B proxy: [`runtime-nativo-linha-b.md`](runtime-nativo-linha-b.md).

## A pragmática vs A otimizada

| Perfil | O que é | Estado |
|--------|---------|--------|
| **A pragmática** (harness v1) | Ubuntu no host de referência + `ia-livre-runtime` CPU, **sem** campanha de tuning | **Gate** (`run-harness-line-a.sh`) |
| **A otimizada** | Mesma carga canônica + checklist de isolamento/tuning do SO | **Metodologia** (esta doc) — não é gate obrigatório |

Otimizar A **melhora a referência**; **não** prova A≻B nem B≻A.

### Carga canônica (inalterada)

| Item | Valor |
|------|--------|
| Modelo | TinyLlama 1.1B Chat v1.0 Q4_K_M |
| Prompt | `Complete em uma frase: O Projeto IA Livre é` |
| `--n-predict` | `32` |
| Marcadores | namespace `IA_LIVRE_HARNESS_*` (não `IA_LIVRE_INFER_*`) |

### Checklist mínimo — perfil «Linux otimizado» (Linha A)

Repetível no host de medição (ajuste paths/núcleos ao hardware):

1. **Governor:** CPU em `performance` (ou equivalente) durante a corrida.
2. **Afinidade / isolamento:** pin do processo do runtime a núcleos dedicados (`taskset` / `isolcpus` / cgroup) quando possível; evitar núcleos ruidosos de IRQs se documentado no host.
3. **Ruído de SO:** fechar cargas pesadas de desktop/background; preferir sessão mínima ou server.
4. **Termal / turbo:** anotar se thermal throttling ou turboboost afetou a corrida (sem exigir laboratório).
5. **Runtime:** mesmo binário/carga canônica; `--n-gpu-layers 0` neste perfil (CPU).
6. **Relatório:** rotular claramente `perfil=A_pragmatica` vs `perfil=A_otimizada`; publicar `HARNESS_LOAD_S` / `HARNESS_TOKENS_PER_S` com a mesma carga.

Itens **fora** deste checklist mínimo: joules, p95 multi-request, campanha científica completa de kernel config.

## Perfil GPU espelhado A/B

### Linha A — host com offload (possível hoje)

Mesma carga canônica + aceleração host (ADR 0002):

- Build com feature `cuda` (canônico) ou `vulkan` (alternativa).
- `--n-gpu-layers` > 0 (ex. `99` pragmático).
- Marcadores sugeridos: `IA_LIVRE_HARNESS_ACCEL=cuda|vulkan` (além de `LINE=A`, `OK`, load/tokens).
- **Não** confundir com [`runtime-inferencia-gpu-metricas.md`](runtime-inferencia-gpu-metricas.md) (Etapa 8 / `IA_LIVRE_INFER_*`) — namespace do harness é distinto, mesmo motor.

### Linha B — espelho GPU (futuro)

Espelho GPU em B **só** quando existir caminho de inferência GGUF (e acelerador) **real** no IA Livre.  
Hoje B = proxy pós-ExitBoot → **proibido** inventar `TOKENS_PER_S` / load GGUF / ACCEL GPU no proxy.

Até lá: GPU-B = **roadmap de medição**, não execução no gate.

### Fronteiras

| Doc / ADR | Papel |
|------------|--------|
| Etapa 8 / ADR 0002 | Prova de caminho GPU **host** (protótipo) |
| ADR 0006 | GPU manager / multi-GPU nativo — **desenho**; não implementar aqui |
| Este perfil | Metodologia de medição do **harness** |

## Gate (decisão Etapa 18)

**Default:** gate permanece `make verify-harness` (A CPU pragmática + B proxy).  
Perfis A otimizada e GPU A/B são **metodologia / roadmap de medição** — **sem** gate novo nesta etapa (não há scripts de execução obrigatória dos perfis novos).

Se no futuro houver corrida verificável dos perfis, aí sim acrescentar script + critério em `AGENTS.md` — sem skip disfarçado de sucesso.
