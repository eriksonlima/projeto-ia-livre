# Runtime-native — perf / espécie (Etapa 59)

Contrato de **medição** para desbloquear (ou declarar inviável) o caminho até a espécie canônica na Linha B.

- Spec: [`specs/otimizar-runtime-native-especie/`](../specs/otimizar-runtime-native-especie/)
- Ponte teto histórico: ADR [`0016`](adr/0016-veredito-limpo-harness-a-b.md)
- ADR [`0020`](adr/0020-runtime-native-passo-intermediario-inviavel.md) — desfecho **B** (inviável no guest pós-otimização; E59)
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

## Otimização aplicada (Task 2) — evidência

| Mudança | Onde |
|---------|------|
| `dot_block_q4_k` — dequant+dot fundidos | `runtime-native/src/lib.rs` |
| `matvec_q4k` / `matvec_q4k_to_ff` sem `wrow` completo | `attn.rs`, `ffn.rs` |
| Dispatch Q4/Q6 por tensor (Q4_K_M mistura tipos entre camadas) | `attn.rs`, `ffn.rs` |
| Microbench host | `tests::e59_host_perf_step_layers` |

### Antes / depois (host release, wall do teste `decode_guest_one_token`)

| Momento | Wall aproximado |
|---------|-----------------|
| Baseline Task 1 | ~1,91 s |
| Pós fused matvec | ~1,78 s (~**7%** ganho) |
| Prefill multi 2L | ~3,88 s → ~3,48 s (~**10%**) |

### Passo N=8 no host (pós-otimização)

```
IA_LIVRE_NATIVE_PERF_HOST_MS_2L1=646
IA_LIVRE_NATIVE_PERF_HOST_MS_8L1=2031
IA_LIVRE_NATIVE_PERF_HOST_OK=1
```

Host faz 8L×1 em ~2 s (~3,1× vs 2L). **Host ≠ guest.** Extrapolando o `make verify` ~267 s (2L guest) → 8L guest ~ordem **800 s** ≫ timeout 600 s. Ganho ~10% **não** é ordem de magnitude.

## Desfecho E59

**B — inviável no guest:** ADR [`0020`](adr/0020-runtime-native-passo-intermediario-inviavel.md).  
Gate: `make verify-runtime-native-perf` → `IA_LIVRE_NATIVE_PERF_OK`.

## Desfecho E60 (espécie canônica)

**Inviável:** ADR [`0021`](adr/0021-especie-canonica-linha-b-inviavel.md) — 22L×32 no gate atual; comparable permanece teto/`INCONCLUSIVO`. Ponte B58 (bloqueio final da hipótese).

## Verificação

```bash
test -f docs/runtime-native-perf-especie.md
test -f docs/adr/0020-runtime-native-passo-intermediario-inviavel.md
make verify-runtime-native-perf
```
