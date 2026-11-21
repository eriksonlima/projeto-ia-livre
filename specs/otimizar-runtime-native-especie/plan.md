# Plan — Otimizar runtime-native (SIMD/teto) para espécie canônica

## Abordagem

1. **Baseline + alvo (Task 1):** documentar medição do teto atual (2L × `n_predict=1`, host e/ou QEMU release) e o alvo intermediário (N≥8 / `n_predict`≥8) vs canônico (22L×32). Contrato da etapa em `docs/` (ex. `docs/runtime-native-perf-especie.md`) + ponte ADR [`0016`](../../docs/adr/0016-veredito-limpo-harness-a-b.md); reservar número ADR **0020** para desfecho inviável (Task 3) ou anotar critérios de sucesso A. Atualizar `runtime-nativo-linha-b.md` / glossário se termos novos. **Sem** mudar código hot-path ainda (salvo stubs de marcadores/docs se necessário).

2. **Otimização concreta (Task 2):** em `runtime-native/` atacar o hot path (dequant Q4_K, matvec, attn/ffn, decode loop): SIMD onde o alvo permitir, unroll, reduzir cópias, flags/`target_feature` documentados, etc. Medir **antes/depois** (host `cargo test` / microbench documentado e, se possível, QEMU release). Evidência de ganho **ou** tentativa honesta sem ganho suficiente. **Ainda** pode manter espécie 2L×1 no guest se a expansão for Task 3 — mas a otimização deve ser real e mensurável.

3. **Gate / desfecho (Task 3):** expandir espécie no guest ao passo intermediário (ou canônico) **ou** emitir ADR **0020** inviável pós-otimização com tabela de evidência. Script/`Makefile`/`AGENTS.md`: prove N≥8 / `n_predict`≥8 (marcadores `PREFILL_LAYERS=`, `N_PREDICT=`, `LOAD_KIND=gguf`, `TOKENS_PER_S` medidos) **ou** exige presença da ADR de inviável. Comparable **não** passa a COMPROVA com subset; hipótese aberta até B54. README avaliar (`readme-por-fatia`).

Ordem: 1 → 2 → 3. Uma fatia por vez. Motor na crate; kernel só glue/serial.

## Arquivos prováveis

- `docs/runtime-native-perf-especie.md` (novo; nome final na Task 1) — medição baseline/alvo
- `docs/adr/0020-*.md` (novo **se** desfecho inviável; nome final na Task 3)
- `docs/adr/0016-veredito-limpo-harness-a-b.md` (ponte E59 / sem reescrever decisão canônica)
- `docs/runtime-nativo-linha-b.md`, `docs/harness-a-b-comparavel.md`, `docs/glossario.md` (se termos/teto mudarem)
- `AGENTS.md`, `Makefile`, `README.md` (avaliar)
- `runtime-native/src/` (`lib.rs`, `attn.rs`, `ffn.rs`, `kv.rs`, `decode.rs`, possível módulo SIMD/matvec)
- `kernel/src/main.rs` (reemissão marcadores — glue fino, se espécie expandir)
- `scripts/verify-boot.sh` e/ou novo `scripts/verify-runtime-native-perf.sh` / extensão harness B
- `scripts/run-harness-line-b.sh` (se espécie guest mudar)
- `specs/otimizar-runtime-native-especie/tasks.md`

## Dependências

- Etapas 44/45 (Decode subset + veredito limpo/teto ADR 0016) — **feitas**
- `runtime-native` + GGUF canônico + QEMU/OVMF para prova guest
- **Não** depende de B54, metal/USB, GPU guest, node, agent

## Verificação

Gate base em `AGENTS.md` + checks desta feature:

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

# Após Task 1
test -f docs/runtime-native-perf-especie.md   # ou nome escolhido na fatia
# baseline/alvo documentados; ponte ADR 0016

# Após Task 2
cargo test -p ia-livre-runtime-native
# evidência antes/depois registrada no doc/ADR

# Após Task 3 — sucesso A (passo intermediário ou canônico)
./scripts/fetch-model.sh
make verify                    # e/ou gate novo da etapa
# exige PREFILL_LAYERS>=8 e/ou N_PREDICT>=8 (ou 22L×32) + TOKENS_PER_S medidos

# Após Task 3 — sucesso B (inviável)
test -f docs/adr/0020-*.md     # inviável pós-otimização com evidência
# gates existentes continuam verdes; sem COMPROVA fingido
```

Proibido em qualquer caminho: inventar `TOKENS_PER_S`; emitir `COMPROVA` com espécie ≠ canônica; declarar hipótese fechada.
