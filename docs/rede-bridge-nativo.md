# Bridge Rede UEFI↔host (Etapa 52)

ADR: [`0019-rede-bridge-uefi-host.md`](adr/0019-rede-bridge-uefi-host.md).  
ADR 0001: o nó host (`make verify-node`) **não** exige o SO.  
≠ autonomia E49 (`BRIDGE_*`): aqui o namespace é `NET_BRIDGE_*`.

## O que é

Script host que:

1. Valida evidência nativa pós-Exit (serial/log: `EXIT_BOOT_OK` mínimo).
2. Ancora participação Rede via `ia-livre-node` (prova com `TASK_OK`).
3. Emite `IA_LIVRE_NET_BRIDGE_*`.

**Não** é TCP no guest. **Não** substitui `verify-node`.

## Marcadores

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_NET_BRIDGE_MODE=host_uefi` | Bridge no host amarrada a evidência UEFI |
| `IA_LIVRE_NET_BRIDGE_NATIVE_SRC=` | `serial_exit` (fixture ou captura) |
| `IA_LIVRE_NET_BRIDGE_OK` | Validação + âncora Rede ok |

## Como rodar

```bash
./scripts/run-rede-bridge.sh --log docs/evidence/bridge/serial-exit-boot-fixture.txt
make verify-rede-bridge
```

## Limites

- Sem inventar `NET_NATIVE_OK` / TCP guest.
- Sem exigir QEMU em `verify-node`.
- KNOW/marketplace fora.
