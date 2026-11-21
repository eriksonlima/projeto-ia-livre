# Autonomia consumindo evidência nativa (Etapa 70)

Além da bridge E49 (**validar** log → `BRIDGE_*`): a autonomia no **host** **usa** essa evidência no caminho de tools/memória e emite `NATIVE_CONSUME_*`.

ADR 0001: **não** exige o SO IA Livre; `make verify-agent` permanece independente.  
Bridge: [`autonomia-bridge-nativo.md`](autonomia-bridge-nativo.md) / ADR [`0018`](adr/0018-autonomia-bridge-host-nativo.md).

## E49 vs E70

| | E49 (bridge) | E70 (consumo) |
|--|--------------|---------------|
| Ação | Validar serial/log nativo | Injetar SRC no loop de autonomia (`note`/`recall`) |
| Marcadores | `BRIDGE_MODE` / `BRIDGE_NATIVE_SRC` / `BRIDGE_OK` | `NATIVE_CONSUME_MODE` / `NATIVE_CONSUME_SRC` / `NATIVE_CONSUME_OK` |
| Pré-requisito | Log/fixture ou metal legado | Exige `BRIDGE_OK` (subprocesso bridge) |
| Onde | Host | Host (**não** guest / kernel) |

## Decisão (desfecho A)

One-shot host: bridge → `note` com `native_src=<SRC>` → `recall` → marcadores de consumo.  
Path default do gate: `blockio` + fixture (sem QEMU longo; sem PC).  
`metal_block` opcional (reusa bridge).

**Pivot B** («bridge = máximo até X») só se consumo exigir agente no guest / TCP guest / fraude host-as-native — critérios de reabertura: guest com FS/tools allowlist **ou** ABI nativa que permita injeção sem violar ADR 0001.

## Marcadores

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_NATIVE_CONSUME_MODE=host_bridge` | Consumo no host via bridge E49 |
| `IA_LIVRE_NATIVE_CONSUME_SRC=` | `blockio` ou `metal_block` (alinhado a `BRIDGE_NATIVE_SRC`) |
| `IA_LIVRE_NATIVE_CONSUME_OK` | Evidência usada (note+recall), não só eco de `BRIDGE_OK` |

## Como rodar

```bash
# Default gate — fixture blockio (sem QEMU):
./scripts/run-autonomia-nativa.sh --src blockio \
  --log docs/evidence/bridge/serial-blockio-fixture.txt

# Opcional — metal legado via bridge:
./scripts/run-autonomia-nativa.sh --src metal_block

make verify-autonomia-nativa
```

## Limites

- Sem agente no guest / kernel.
- Sem shell irrestrito / HTTP.
- Sem inventar `TOKENS_PER_S` / `METAL_OK` / `COMPROVA`.
- Sem fingir `ia-livre-runtime` host como fonte nativa (exige `BRIDGE_OK`).
- ≠ bridge Rede E52 (`NET_BRIDGE_*`).
- E63 `esp_sfs_full` ≠ fonte desta etapa (fonte = bridge `blockio`/`metal_block`).
