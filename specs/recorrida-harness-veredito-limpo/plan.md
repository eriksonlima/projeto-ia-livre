# Plan — Re-corrida harness A vs B com geração real (veredito limpo)

## Abordagem

1. **Contrato primeiro (Task 1):** ADR **0016** fixa “veredito limpo”: preferência espécie canônica 22L + `n_predict=32` → veredito por margem R; fallback honesto com reason **novo** `E45_perf_ceiling_below_canonical` (só se ADR declarar teto); lista explícita de reasons **proibidos** (proxy, `no_gguf_full_prefill` / legado, `E44_subset_*`). Atualizar `harness-a-b-comparavel.md`, pontes quieta/runtime-nativo, glossário se couber, `AGENTS.md`. Baseline: números E44 (2L×1) + estimativa 22L×32 inviável.

2. **Expandir espécie / otimizar (Task 2):** em `runtime-native/` (+ glue fino no kernel se necessário): subir `PREFILL_LAYERS` / pos / `n_predict` o máximo que o gate QEMU (release) aguentar; medições host/guest; timeout documentado uma vez se necessário. Meta = 22L×32. Se teto &lt; canônico: registrar N alcançado + evidência de inviabilidade — **sem** inventar tokens; **sem** alterar comparable reason ainda (exceto se Task 3 for a mesma fatia — aqui só motor/métricas).

3. **Comparable limpo (Task 3):** `run-harness-a-b-comparable.sh` / `verify-harness-comparable.sh`: se espécie canônica → margem R (COMPROVA/REFUTA/INCONCLUSIVO); se teto ADR → `INCONCLUSIVO` + `E45_perf_ceiling_*` e **rejeitar** `E44_subset_*` / proxy / `no_gguf_*` legado no caminho de sucesso. Preservar preflight quieto. Docs + desfecho ROADMAP. README avaliar.

Ordem: 1 → 2 → 3. Uma fatia por vez. Motor na crate; scripts de veredito na Task 3.

## Arquivos prováveis

- `docs/adr/0016-veredito-limpo-harness-a-b.md` (novo; nome final na Task 1)
- `docs/harness-a-b-comparavel.md`, `docs/harness-corrida-quieta.md`, `docs/harness-linha-a-b.md`
- `docs/runtime-nativo-linha-b.md`, `docs/glossario.md`
- `AGENTS.md`, `README.md` (avaliar), `ROADMAP.md` (desfecho ao fechar)
- `runtime-native/src/` (prefill/decode/kv — expansão N)
- `kernel/src/main.rs` (marcadores layers / n_predict — glue fino)
- `scripts/run-harness-a-b-comparable.sh`, `scripts/verify-harness-comparable.sh`
- `scripts/run-harness-line-b.sh`, `scripts/verify-harness.sh`, `Makefile` (timeouts se preciso)
- `specs/recorrida-harness-veredito-limpo/tasks.md`

## Dependências

- Etapa 44 (Decode + `TOKENS_PER_S` subset) — **feita**
- ADR 0014 / 0015 — baseline de perf e geração
- GGUF local + QEMU/OVMF; `PROFILE=release`
- **Não** depende de bare-metal, GPU guest, node, agent

## Verificação

Gate base em `AGENTS.md` + checks desta feature:

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

# Após Task 1
test -f docs/adr/0016-veredito-limpo-harness-a-b.md   # ou nome escolhido na fatia

# Após Task 2
make verify   # ou evidência de N layers/n_predict ampliado + medição

# Após Task 3
./scripts/fetch-model.sh
make verify-harness-comparable
# Exige: VERDICT ∈ {COMPROVA,REFUTA,INCONCLUSIVO}
# Exige: B LOAD_KIND=gguf + TOKENS_PER_S
# Proíbe no sucesso: proxy / no_gguf_full_prefill / E44_subset_*
# Aceita: margem R OU E45_perf_ceiling_below_canonical (se ADR)
```

Proibido: inventar `TOKENS_PER_S`; forçar `COMPROVA`; quebrar quiet.
