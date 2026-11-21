# ADR 0024 — TCP Rede no guest pós-Exit inviável no kernel atual

- Status: aceita
- Data: 2026-11-21
- Etapa: 66

## Contexto

Etapa 52 / ADR [`0019`](0019-rede-bridge-uefi-host.md) adotou bridge host↔UEFI e **adiou** TCP nativo no guest. Etapa 66 pede sessão Rede no caminho B com TCP guest **ou** inviabilidade honesta. Inventário (2026-11-21): `kernel/` pós-Exit = UART COM1; **sem** virtio-net, driver NIC, sockets ou smoltcp.

## Decisão

1. TCP Rede **no guest** pós-Exit permanece **inviável** no kernel atual (sem NIC/stack).
2. Sessão Rede no caminho B continua via **bridge** E52 (`NET_BRIDGE_*` + âncora `TASK_OK` no host).
3. Marcador honesto: `IA_LIVRE_NET_GUEST_BLOCK=no_tcp_post_exit`.
4. **Proibido** `NET_NATIVE_OK` sem stack TCP real.
5. ADR 0001 intacta: `make verify-node` **não** exige QEMU/SO.

## Reabertura

Virtio-net (ou NIC documentada) + TCP mínimo freestanding + sessão v1 verificável no guest (`IDENT`/`TASK` ou equivalente) + gate sem fraude.

## Rejeitado

- Stub teatral `NET_NATIVE_OK`.
- Portar `ia-livre-node` / libp2p ao kernel nesta etapa.
- Acoplar `verify-node` ao guest.

## Consequências

- Contrato: [`../rede-tcp-guest.md`](../rede-tcp-guest.md).
- Gate: `make verify-rede-guest`.
- ADR 0019: adiamento **confirmado** como inviabilidade documentada (E66); bridge permanece canônica até reabertura.
