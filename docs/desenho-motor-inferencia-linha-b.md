# Desenho — Motor de inferência Linha B (Etapas 29–32)

ADR: [`0010`](adr/0010-runtime-nativo-freestanding-linha-b.md) · [`0012`](adr/0012-forward-gguf-fatiado-linha-b.md) · [`0013`](adr/0013-geracao-canonica-fatiada-linha-b.md).  
Contrato B: [`runtime-nativo-linha-b.md`](runtime-nativo-linha-b.md).  
Separação de camadas: ADR [`0001`](adr/0001-separacao-camadas-e-p2p.md).

## Fronteira

| Peça | Responsável |
|------|-------------|
| Boot, ExitBoot, UART, BlockIO loader, tipados E19 | `kernel/` |
| Parse GGUF avançado, layout de tensores, forward/sampling | `runtime-native/` (`ia-livre-runtime-native`) |
| Linha A (referência) | `runtime/` host — **não** é B |

## API mínima (crate)

```text
prepare(gguf: &[u8]) -> Result<LayoutReport, PrepareError>
  // magic/version, metadata walk, tensor infos (nome/dims/offset/type)
try_forward_canonical(layout, weights/kv hints) -> Result<InferMetrics, ForwardError>
  // Prefill+Decode+sampling; só Ok se geração real medida
```

Marcadores serial (COM1), emitidos via callback/`&mut dyn FnMut(&[u8])` ou retorno + glue no kernel:

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_NATIVE_INFER_BEGIN` | Kernel entrou no caminho do motor |
| `IA_LIVRE_RUNTIME_NATIVE_LAYOUT_OK` | Layout/tensores além do stub E27 |
| `IA_LIVRE_GGUF_STATUS=layout_ok` | Status pós-parse avançado |
| `IA_LIVRE_RUNTIME_NATIVE_TOKENIZE_OK` | Prompt canônico → ids (E32) |
| `IA_LIVRE_RUNTIME_NATIVE_EMBED_OK` | Lookup `token_embd` Q4_K (E32) |
| `IA_LIVRE_RUNTIME_NATIVE_LAYER_PARTIAL_OK` | ≥1 attn/FFN parcial (E32) |
| `IA_LIVRE_RUNTIME_NATIVE_FORWARD_FAIL=<motivo>` | Forward não concluído (fallback) |
| `IA_LIVRE_RUNTIME_NATIVE_OK` | Geração mínima ok (caminho sucesso) |
| `IA_LIVRE_NATIVE_INFER_LOAD_S=` / `TOKENS_PER_S=` | **Só** se medidos |

## Critério sucesso vs fallback

| Caminho | Condição | Harness B |
|---------|----------|-----------|
| Sucesso | `try_forward_canonical` Ok + métricas medidas | `LOAD_KIND=gguf`, `N_PREDICT=32`, sem `B_BLOCK` de motor |
| Fallback Etapa 29 | Layout ok; forward ausente/incompleto | `LOAD_KIND=proxy`, `B_BLOCK=no_gguf_forward`, `GGUF_STATUS=layout_ok` |
| Fallback Etapa 31 | Mapa+dequant+op; sem geração | `B_BLOCK=no_gguf_generate` |
| Fallback Etapa 32 | Tokenize+embed+camada ok; sem decode/sampling | `B_BLOCK` **novo** (ex. `no_gguf_decode`) — ADR 0013 |

Proxy E12 permanece como evidência lateral enquanto `LOAD_KIND=proxy`.

## Carga canônica

Igual à Linha A (TinyLlama Q4_K_M, prompt padrão, `n-predict=32`, CPU). Ver `AGENTS.md`.

## Fora de escopo desta etapa

Bare-metal (B24), GPU nativa, host-as-B, inventar tokens.
