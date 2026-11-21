# ADR 0019 — Bridge Rede UEFI↔host (caminho B)

- Status: aceito
- Data: 2026-11-21
- Etapa: 52

## Contexto

B46 pediu nó Rede no SO nativo (TCP pós-Exit) **ou** bridge documentada. O kernel freestanding pós-ExitBoot tem UART, sem NIC/TCP. ADR 0001: participar da Rede **não exige** o SO.

## Decisão

**Bridge host** (`IA_LIVRE_NET_BRIDGE_*`): valida evidência serial do caminho B (pós-Exit) e ancora sessão `ia-livre-node` no host (preferir `TASK_OK`). TCP nativo no guest fica **adiado**.

## Consequências

- `make verify-node` permanece independente de QEMU/SO.
- Namespace distinto de E49 (`BRIDGE_*` autonomia ≠ `NET_BRIDGE_*`).
- Sem stub teatral `NET_NATIVE_OK` sem stack.
