# TCP Rede no guest (Etapa 66)

ADR: [`0024-tcp-rede-guest-inviavel.md`](adr/0024-tcp-rede-guest-inviavel.md) · Bridge E52: [`rede-bridge-nativo.md`](rede-bridge-nativo.md) · ADR [`0019`](adr/0019-rede-bridge-uefi-host.md).

> **Não** é TCP no guest. **Não** emite `NET_NATIVE_OK`. **Não** substitui `verify-node` (ADR 0001).

## Inventário medido

| Peça | Estado (kernel pós-Exit) |
|------|---------------------------|
| UART COM1 | Sim (`EXIT_*`) |
| virtio-net / NIC | **Ausente** |
| TCP/IP freestanding | **Ausente** |
| Sessão Rede v1 no guest | **Inviável** nesta base |

## Desfecho E66 (caminho B)

1. Evidência nativa pós-Exit (`EXIT_BOOT_OK` — fixture ou QEMU).
2. Bloqueio guest: `IA_LIVRE_NET_GUEST_BLOCK=no_tcp_post_exit`.
3. Sessão Rede: bridge host (`NET_BRIDGE_*` + `TASK_OK`).

## Marcadores

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_NET_GUEST_BLOCK=no_tcp_post_exit` | TCP guest inviável (ADR 0024) |
| `IA_LIVRE_NET_BRIDGE_*` / `NET_BRIDGE_OK` | Sessão caminho B via bridge (E52) |
| `IA_LIVRE_NET_GUEST_OK` | Gate E66 ok (bloqueio + bridge) |

**Proibido:** `IA_LIVRE_NET_NATIVE_OK` sem stack.

## Gate

```bash
make verify-rede-guest
```

Regressão: `make verify-rede-bridge` · `make verify-node`.
