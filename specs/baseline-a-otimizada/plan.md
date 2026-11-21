# Plan — Baseline Linha A otimizada (CPU) no gate comparável (Etapa 34)

## Estratégia

Três fatias verticais sequenciais, da menor para a maior superfície:

1. **Script A_otimizada** — entrega o executável stand-alone com tuning + marcadores; A_default intocado.
2. **Integração no comparable** — `run-harness-a-b-comparable.sh` aceita `IA_LIVRE_HARNESS_A_PROFILE=A_otimizada`; veredito lógico preservado.
3. **Gate + docs finais** — `make verify-harness-a-otimizada`; atualização de `harness-perfis-a-otimizada-gpu.md`, `harness-a-b-comparavel.md`, `AGENTS.md`; README avaliado.

Cada fatia é uma task de `tasks.md`. Não implementar mais de uma task por vez.

## Dependências externas

| Dependência | Estado |
|-------------|--------|
| `run-harness-line-a.sh` (A_default) | Estável — não alterar |
| `run-harness-a-b-comparable.sh` | Estável — extensão mínima na Task 2 |
| `docs/harness-perfis-a-otimizada-gpu.md` (E18) | Existe — atualizar na Task 3 |
| `runtime-native/`, `kernel/` | Fora de escopo — não tocar |

## Mapa de arquivos por task

| Task | Arquivos novos/modificados |
|------|---------------------------|
| Task 1 | `scripts/run-harness-line-a-optimized.sh` (novo) |
| Task 2 | `scripts/run-harness-a-b-comparable.sh` (extensão mínima), `Makefile` (target `verify-harness-a-otimizada`) |
| Task 3 | `docs/harness-perfis-a-otimizada-gpu.md`, `docs/harness-a-b-comparavel.md`, `AGENTS.md`, README (avaliado) |

## Decisões de implementação (Task 1)

### Governor (sem root forçado)

```bash
# Tentar; se falhar → GOVERNOR_SKIP
if command -v cpufreq-set &>/dev/null; then
  cpufreq-set -g performance 2>/dev/null \
    && echo "IA_LIVRE_HARNESS_GOVERNOR_OK" \
    || echo "IA_LIVRE_HARNESS_GOVERNOR_SKIP"
else
  echo "IA_LIVRE_HARNESS_GOVERNOR_SKIP"
fi
```

Alternativa via `/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor` (loop; mesmo padrão skip).

### Threads

```bash
N_THREADS="${IA_LIVRE_HARNESS_N_THREADS:-$(( $(nproc) > 1 ? $(nproc) - 1 : 1 ))}"
echo "IA_LIVRE_HARNESS_THREADS=${N_THREADS}"
# Passar ao runtime: --threads "${N_THREADS}"
```

`ia-livre-runtime` já aceita `--threads` (via llama-cpp-2).

### Taskset

```bash
# Identificar núcleos de desempenho (heurística: últimos N-1 núcleos ou cpu0 excluído)
CPUS_PERF="$(seq -s, 1 "$(( $(nproc) - 1 ))")"   # ex. "1,2,3"
if command -v taskset &>/dev/null && [[ $(nproc) -gt 1 ]]; then
  RUNTIME_CMD="taskset -c ${CPUS_PERF} $RUNTIME_BIN ..."
  echo "IA_LIVRE_HARNESS_TASKSET_OK"
else
  RUNTIME_CMD="$RUNTIME_BIN ..."
  echo "IA_LIVRE_HARNESS_TASKSET_SKIP"
fi
```

### Termal

```bash
THERMAL_PATH="$(find /sys/class/thermal -name 'temp' 2>/dev/null | head -n1)"
if [[ -n "$THERMAL_PATH" ]]; then
  TEMP_MC="$(cat "$THERMAL_PATH" 2>/dev/null || echo '')"
  if [[ -n "$TEMP_MC" ]]; then
    echo "IA_LIVRE_HARNESS_THERMAL_OK=$(( TEMP_MC / 1000 ))"
  else
    echo "IA_LIVRE_HARNESS_THERMAL_SKIP"
  fi
else
  echo "IA_LIVRE_HARNESS_THERMAL_SKIP"
fi
```

## Decisões de implementação (Task 2)

Bloco mínimo a adicionar em `run-harness-a-b-comparable.sh` antes da chamada à Linha A:

```bash
A_PROFILE="${IA_LIVRE_HARNESS_A_PROFILE:-}"
if [[ "$A_PROFILE" == "A_otimizada" ]]; then
  A_SCRIPT="./scripts/run-harness-line-a-optimized.sh"
else
  A_SCRIPT="./scripts/run-harness-line-a.sh"
fi
# (usar $A_SCRIPT no lugar da chamada hardcoded atual)
```

Nenhuma outra alteração no veredito lógico.

## Decisões de implementação (Task 2 — Makefile)

```makefile
verify-harness-a-otimizada:
	@echo "=== Gate Linha A otimizada ==="
	./scripts/run-harness-line-a-optimized.sh
```

Target `verify-harness-comparable` não muda (continua chamando `run-harness-a-b-comparable.sh`).

## Riscos gerenciados

| Risco | Mitigação |
|-------|-----------|
| Governor sem permissão | `GOVERNOR_SKIP` + continua |
| `nproc` = 1 | `N_THREADS=1`; `TASKSET_SKIP` |
| Comparable quebrado pela mudança | Bloco de seleção de script não altera fluxo de veredito |
| `--threads` não aceito pelo runtime | Testar antes do merge; fallback: omitir flag |
