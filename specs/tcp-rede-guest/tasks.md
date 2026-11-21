# Tasks — Stack TCP Rede nativa no guest

Etapa 66 · Spec: `specs/tcp-rede-guest/`

Uma task = uma fatia.

- [x] Task 1 — Decisão B + contrato/ADR: inventário medido (UART-only; sem NIC/TCP); ADR `0024` (TCP guest inviável; reabertura); estender `rede-bridge-nativo.md` e/ou `docs/rede-tcp-guest.md`; fixar `IA_LIVRE_NET_GUEST_BLOCK=…`, nome do gate (`verify-rede-guest` ou estágio em `verify-rede-bridge`); ponte ADR 0019; pré-anunciar em `AGENTS.md`
- [x] Task 2 — Runner/estágio caminho B: emitir `NET_GUEST_BLOCK` + preservar `NET_BRIDGE_*` / âncora `TASK_OK`; **proibido** `NET_NATIVE_OK` sem stack; sem driver virtio/TCP no kernel
- [x] Task 3 — Gate Makefile + greps em `AGENTS.md`; anti-fraude; regressão `verify-rede-bridge` + `verify-node` (ADR 0001); avaliar README (`readme-por-fatia`)
