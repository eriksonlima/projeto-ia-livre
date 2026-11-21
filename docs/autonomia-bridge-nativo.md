# Bridge host↔nativo (Etapa 49)

ADR: [`0018-autonomia-bridge-host-nativo.md`](adr/0018-autonomia-bridge-host-nativo.md).  
ADR 0001 preservada: autonomia host **não exige** o SO IA Livre; `make verify-agent` permanece independente.

## O que é

Script host que **consome evidência** do runtime nativo (serial QEMU / log) e emite marcadores de bridge. **Não** é agente no guest. **Não** substitui `ia-livre-agent` + `ia-livre-runtime`.

## Fontes nativas

| `BRIDGE_NATIVE_SRC` | Evidência | Esperado |
|---------------------|-----------|----------|
| `blockio` | Serial Linha B / BlockIO (`DECODE_OK` / `RUNTIME_NATIVE_OK`) | Geração nativa subset (E44) |
| `metal_block` | ESP-only (`B_BLOCK_METAL=no_gguf_metal_io`) | Bloqueio path metal (E48) |

## Marcadores

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_BRIDGE_MODE=host_native` | Bridge no host |
| `IA_LIVRE_BRIDGE_NATIVE_SRC=` | `blockio` ou `metal_block` |
| `IA_LIVRE_BRIDGE_OK` | Validação ok |

## Como rodar

```bash
# Path metal (rápido):
./scripts/run-autonomia-bridge.sh --src metal_block

# Path BlockIO (usa log do harness B ou --log FILE):
./scripts/run-autonomia-bridge.sh --src blockio --log build/bridge-blockio.log

make verify-autonomia-bridge
```

## Limites

- Sem shell irrestrito / HTTP.
- Sem inventar `TOKENS_PER_S` / `METAL_OK`.
- Bridge ≠ prova comparable `COMPROVA`.
