# Runtime-native — perf / espécie (Etapa 59)

Contrato de **medição** para desbloquear (ou declarar inviável) o caminho até a espécie canônica na Linha B.

- Spec: [`specs/otimizar-runtime-native-especie/`](../specs/otimizar-runtime-native-especie/)
- Ponte teto histórico: ADR [`0016`](adr/0016-veredito-limpo-harness-a-b.md)
- ADR **0020** reservada para desfecho **inviável pós-otimização** (só Task 3, se necessário)
- Linha B: [`runtime-nativo-linha-b.md`](runtime-nativo-linha-b.md) · comparable: [`harness-a-b-comparavel.md`](harness-a-b-comparavel.md)

> **Hipótese A vs B permanece aberta.** Esta etapa **não** emite `COMPROVA` e **não** substitui B54 (espécie canônica no comparable).

## Espécies

| Nome | Prefill layers (`N`) | `n_predict` | Papel |
|------|----------------------|-------------|--------|
| **Teto atual (E44/E45)** | `PREFILL_LAYERS_GUEST=2` | `N_PREDICT_GUEST=1` | Gate verde; comparable `INCONCLUSIVO` / teto |
| **Passo intermediário (E59)** | **N ≥ 8** **e/ou** | **`n_predict` ≥ 8** | Progresso mínimo verificável |
| **Canônica (B54)** | 22 | 32 | Igual Linha A; só então `COMPROVA`/`REFUTA` por margem |

Constantes: `runtime-native/src/kv.rs` (`PREFILL_LAYERS_*`) · `runtime-native/src/decode.rs` (`N_PREDICT_*`).

Timeout de referência do gate: **600 s** (`VERIFY_TIMEOUT` / harness B).

## Baseline (Task 1 — antes da otimização)

### Host (`cargo test -p ia-livre-runtime-native --release`)

Medido em 2026-11-21 (GGUF canônico local; wall do filtro de teste — inclui I/O do mmap/load do arquivo):

| Caso | Filtro | Wall (s) |
|------|--------|----------|
| Prefill guest 2L×2 pos | `prefill_multi_guest_subset` | ~3,9 |
| Prefill+Decode 2L × `n_predict=1` | `decode_guest_one_token` | ~1,9 |

> Host ≠ guest QEMU. Serve para **antes/depois** da otimização (Task 2) e extrapolação; a prova A do Pronto quando prefere **guest** no gate.

### Guest QEMU (histórico ADR 0016 / E44–E45)

| Tentativa | Resultado |
|-----------|-----------|
| 22L×16 prefill QEMU debug | timeout 600 s (E43) |
| 2L×16 host release | ~7 s (ADR 0016) |
| Extrapolação 22L×16 host | ~250 s |
| Guest release E44 (2L + decode 1) | `make verify` ~267 s |
| Conclusão E45 | 22L×32 no gate 600 s **inviável** sem ordem de magnitude |

Reason limpo atual do comparable: `E45_perf_ceiling_below_canonical_layers=2_npredict=1`.

### Extrapolação grosseira (ordem de grandeza)

Hipótese linear (só orientação — **não** prova):

| Alvo | Escala vs 2L×1 | Guest estimado (se ~linear a partir de ~267 s verify) |
|------|----------------|------------------------------------------------------|
| N=8, n_predict=1 | ×4 layers | ~ordem 10³ s (risco timeout) |
| N=2, n_predict=8 | ×8 decode | ~ordem 10³ s |
| N=8, n_predict=8 | ×4×8 | bem acima de 600 s sem ganho |
| 22L×32 | ×11×32 | inviável sem ganho ≫10× |

Conclusão Task 1: **precisa** otimização real (Task 2) **ou** (após tentativa) ADR 0020 inviável — só reafirmar 0016 **não** fecha E59.

## Alvos E59 (sucesso)

Cumpre a etapa se **após** otimização tentada/medida:

1. **A — Progresso:** guest (preferido) emite `PREFILL_LAYERS`≥8 **ou** `N_PREDICT`≥8 (ou ambos), com `LOAD_KIND=gguf` + `TOKENS_PER_S` **medidos**, dentro do timeout; **ou** 22L×32 no timeout; **ou**
2. **B — Inviável:** ADR [`0020`](adr/) *(a criar na Task 3 se necessário)* com baseline + tentativa + teto residual.

**Proibido:** inventar `TOKENS_PER_S`; `COMPROVA` com espécie ≠ canônica; contar host como B.

## Hot path candidato (Task 2)

Ordem sugerida de ataque em `runtime-native/`:

1. Dequant Q4_K / matvec (attn, FFN, embed)
2. Loop Prefill multi-layer / Decode
3. Cópias e buffers temporários
4. SIMD/`target_feature` onde o alvo permitir (documentar assimetria host vs UEFI freestanding)

## Verificação desta fatia (Task 1)

```bash
test -f docs/runtime-native-perf-especie.md
grep -q 'Passo intermediário' docs/runtime-native-perf-especie.md
grep -q 'ADR \*\*0020\*\*\|ADR 0020' docs/runtime-native-perf-especie.md
grep -q 'Etapa 59' docs/adr/0016-veredito-limpo-harness-a-b.md
```
