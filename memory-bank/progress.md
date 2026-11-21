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

