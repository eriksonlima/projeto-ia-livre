# Progress

## O que funciona

- 1–66 feitas; E63 SFS full; E64 sym_cpu; E65 need_vfio; E66 NET_GUEST_BLOCK
- Rede/autonomia host verdes; pilar 1 BLOQUEIO_FINAL

## Bloqueios

- COMPROVA / espécie; METAL_OK (PC); simetria GPU (VFIO); TCP guest (virtio+stack)

## Roadmap

- Sem em_andamento; topo Abertas B62

## Etapa 70 — Autonomia consumindo nativo (feita)

- Contrato `docs/autonomia-nativa.md`; runner bridge→note/recall→`NATIVE_CONSUME_*`
- Gate `make verify-autonomia-nativa` (blockio fixture); ADR 0001 intacta
- Próximo: B66 ABI

## Etapa 71 — ABI runtime-native (feita)

- Contrato `docs/abi-runtime-native.md`; `abi.rs` + glue guest; gate freestanding
- `make verify` exige `ABI_OK`; ADR 0001 intacta
- Próximo: B67 docs sync

## Etapa 72 — Sync architecture/product (feita)

- architecture/product/glossário pós-E71; verify-docs-consistency
- Abertas: B55 adiada

