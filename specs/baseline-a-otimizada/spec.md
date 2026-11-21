# Spec — Baseline Linha A otimizada (CPU) no gate comparável (Etapa 34)

## Resultado visível

Script `scripts/run-harness-line-a-optimized.sh` **executável e verificável** que roda a carga
canônica A com perfil `A_otimizada` (governor performance, afinidade/taskset, `--threads` configurável,
anotação de turbo/termal) e emite `IA_LIVRE_HARNESS_PROFILE=A_otimizada` + métricas honestas.

Perfil integrado ao harness comparável via variável de ambiente
(`IA_LIVRE_HARNESS_A_PROFILE=A_otimizada`) — `A_default` preservado como default.
Gate `make verify-harness-comparable` aceita a corrida A otimizada com o mesmo veredito honesto
(`INCONCLUSIVO` enquanto B = proxy/`no_gguf_full_prefill`).

> **Pronto quando do ROADMAP:** perfil `A_otimizada` documentado + corrida verificável lado a lado;
> ideal após geração B, mas pode avançar baseline A independentemente.

## Contexto fixo (não reinventar)

- **E18 desfecho:** metodologia documentada em `docs/harness-perfis-a-otimizada-gpu.md` — checklist
  governador/afinidade/ruído/termal/runtime — mas **sem script executável** nem gate obrigatório.
- **E33 desfecho:** attn+FFN+prefill layer0; `B_BLOCK=no_gguf_full_prefill`; comparable
  `INCONCLUSIVO` / reason `E33_no_gguf_full_prefill_22L_kv_inviable`.
- **Script atual A:** `scripts/run-harness-line-a.sh` → perfil `A_pragmatica` (sem tuning); não
  deve ser alterado — é a referência de comparação basal.
- **Comparable atual:** `scripts/run-harness-a-b-comparable.sh` sempre chama `run-harness-line-a.sh`;
  nenhuma variante de perfil A está implementada.
- **Gate:** `make verify-harness-comparable` exige `VERDICT` ∈ {COMPROVA, REFUTA, INCONCLUSIVO} +
  `VERDICT_REASON`; `INCONCLUSIVO` é aceito com B proxy.
- **Nomenclatura:** Projeto IA Livre / IA Livre / Rede IA Livre.
- **Rule `readme-por-fatia`:** cada fatia avalia `README.md`.
- **Proibido em qualquer fatia:** inventar `TOKENS_PER_S` em B; forçar COMPROVA/REFUTA sem
  checklist comparável satisfeito; alterar A_default (`run-harness-line-a.sh`).

## Avaliação de alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A — só doc** | Atualizar E18 sem script executável | **Rejeitada** — não entrega gate verificável (Etapa 18 já fez isso) |
| **B — script dedicado verificável** | `run-harness-line-a-optimized.sh` independente + env-var no comparable + gate aceitando corrida otimizada | **Escolhida** — separa A_default de A_otimizada sem quebrá-los |
| **C — modificar run-harness-line-a.sh** | Adicionar modo otimizado ao script existente | **Rejeitada** — polui A_default; dificulta comparação antes/depois; viola princípio de preservar referência |
| **D — novo gate separado** | `make verify-harness-a-otimizada` completamente separado | **Parcialmente aceita** — gate dedicado é opt-in; o comparável existente deve também suportá-lo via variável |

## Decisão de desenho — Opção B

### Perfil A_otimizada (flags e tuning no host)

Checklist mínimo implementado no script (baseado em E18, sem campanha científica completa):

| Item | Implementação no script |
|------|------------------------|
| **CPU governor** | `cpufreq-set -g performance` (ou equivalente `/sys/`); skip com aviso se sem permissão |
| **Afinidade / n_threads** | `--threads N` (default: `nproc - 1` ou variável `IA_LIVRE_HARNESS_N_THREADS`); `taskset` ao PID se disponível |
| **Ruído de SO** | Aviso se `load_avg > 1.0`; sem fechar processos ativos (não invasivo) |
| **Termal / turbo** | Leitura de `/sys/.../temp` (se acessível) + anotar `HARNESS_THERMAL_OK/SKIP`; sem exigir laboratório |
| **Labels de perfil** | `IA_LIVRE_HARNESS_PROFILE=A_otimizada` + `IA_LIVRE_HARNESS_THREADS=N` nos marcadores |

**Degradações aceitáveis do skip:** se `cpufreq-set` não estiver disponível ou sem permissão →
emitir `IA_LIVRE_HARNESS_GOVERNOR_SKIP` e continuar; idem para `taskset` →
`IA_LIVRE_HARNESS_TASKSET_SKIP`. O script **não falha** por falta de privilégio — apenas anota.

### Integração no harness comparável

`run-harness-a-b-comparable.sh` aceita `IA_LIVRE_HARNESS_A_PROFILE`:

| Valor | Script A chamado |
|-------|-----------------|
| _(vazio / qualquer outro)_ | `run-harness-line-a.sh` (A_default — comportamento atual preservado) |
| `A_otimizada` | `run-harness-line-a-optimized.sh` |

Nenhuma lógica de veredito muda — `COMPROVA`/`REFUTA` continuam dependendo do checklist comparável
(B não proxy + métricas GGUF reais). Com B = `no_gguf_full_prefill` → `INCONCLUSIVO` **obrigatório**.

### Marcadores novos

| Marcador | Quando emitido |
|----------|---------------|
| `IA_LIVRE_HARNESS_PROFILE=A_otimizada` | Script A otimizado executado com sucesso |
| `IA_LIVRE_HARNESS_THREADS=N` | Número de threads passado ao runtime |
| `IA_LIVRE_HARNESS_GOVERNOR_OK` | Governor `performance` ativado |
| `IA_LIVRE_HARNESS_GOVERNOR_SKIP` | Governor não aplicado (sem permissão / `cpufreq-set` ausente) |
| `IA_LIVRE_HARNESS_TASKSET_OK` | `taskset` aplicado ao processo runtime |
| `IA_LIVRE_HARNESS_TASKSET_SKIP` | `taskset` indisponível ou sem núcleo dedicado identificável |
| `IA_LIVRE_HARNESS_THERMAL_OK=<temp>` | Temperatura lida (°C) antes da corrida |
| `IA_LIVRE_HARNESS_THERMAL_SKIP` | Leitura de temperatura indisponível |

Marcadores herdados de A: `IA_LIVRE_HARNESS_LINE=A`, `IA_LIVRE_HARNESS_OK`, load/tokens.

### Gate dedicado (opt-in)

`make verify-harness-a-otimizada` → chama `run-harness-line-a-optimized.sh` diretamente;
exige `HARNESS_OK` + `HARNESS_PROFILE=A_otimizada` + métricas; skip não aplicável aqui (é opt-in).
Makefile: target novo sem quebrar os existentes.

## Fora de escopo

- Alterar `run-harness-line-a.sh` (A_default intocado)
- GPU nativa no guest (B side)
- Campanha científica completa (joules, p95, isolcpus de kernel, `perf` profiling)
- Comparação A_pragmatica vs A_otimizada com análise estatística (apenas corridas lado a lado honestas)
- Mudar o critério de veredito do comparável (R ≥ 1.05 / R ≤ 0.95 / else)
- `runtime-native/`, kernel, node, agent
- Multi-GPU / GPU manager
- Inventar TOKENS_PER_S em B

## Critérios de aceite

- [ ] `scripts/run-harness-line-a-optimized.sh` existe, é executável, emite
  `IA_LIVRE_HARNESS_PROFILE=A_otimizada` + `IA_LIVRE_HARNESS_LINE=A` + `IA_LIVRE_HARNESS_OK`
  + métricas honestas; skip anota e não falha
- [ ] `scripts/run-harness-line-a.sh` **inalterado** (A_default preservado)
- [ ] `run-harness-a-b-comparable.sh` aceita `IA_LIVRE_HARNESS_A_PROFILE=A_otimizada` e chama
  o novo script; sem alteração no veredito lógico
- [ ] `make verify-harness-a-otimizada` gate dedicado OK (ou `AGENTS.md` documenta como rodar)
- [ ] `make verify-harness-comparable` preservado — continua verde com A_default; com
  `IA_LIVRE_HARNESS_A_PROFILE=A_otimizada` também verde (INCONCLUSIVO honesto com B proxy)
- [ ] `docs/harness-perfis-a-otimizada-gpu.md` atualizado: de "metodologia" para "executável
  verificável"; script e variável de env documentados
- [ ] `docs/harness-a-b-comparavel.md` menciona A_otimizada como opt-in do comparável
- [ ] `AGENTS.md` cobre o novo script/gate; README avaliado

## Riscos e rollback

- **Risco:** `cpufreq-set` indisponível em CI / sandbox → mitigação: skip anota `GOVERNOR_SKIP`
  e continua; gate não falha por isso.
- **Risco:** `taskset` sem núcleo dedicado identificável → mitigação: skip com `TASKSET_SKIP`;
  `--threads` passa o valor via CLI ao runtime.
- **Risco:** corrida A_otimizada mais lenta que A_default (carga de tuning sobrepõe ganho) →
  aceitável — não inventar vitória; anotar diferença nos docs.
- **Rollback:** se integração no comparable quebrar `verify-harness-comparable` → reverter
  `run-harness-a-b-comparable.sh`; `run-harness-line-a-optimized.sh` permanece stand-alone.

## Etapa do roadmap

- Etapa **34** — Baseline Linha A otimizada (CPU) no gate comparável (`em_andamento`)
- Issue: [#33](https://github.com/eriksonlima/projeto-ia-livre/issues/33)
- Spec: `specs/baseline-a-otimizada/`
- Pronto quando: perfil `A_otimizada` documentado + corrida verificável lado a lado; ideal após
  geração B, mas pode avançar baseline A independentemente.
