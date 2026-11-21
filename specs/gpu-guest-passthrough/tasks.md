# Tasks — GPU real no guest (PCI/pass-through)

Etapa 65 · Spec: `specs/gpu-guest-passthrough/`

Uma task = uma fatia.

- [x] Task 1 — Contrato VFIO/QEMU: doc (`docs/gpu-guest-passthrough.md` e/ou seção em `gpu-real-nativo.md`) + pontes E38/E55/ADR 0023; fixar marcadores (`SRC=pci_passthrough`, skip `need_gpu`/`need_vfio`), âncora de evidência e nome do gate; pré-anunciar em `AGENTS.md`; ADR nova só se necessário
- [x] Task 2 — Runner/estágio: detectar VFIO/GPU; emitir `GPU_REAL_SRC=pci_passthrough` + `GPU_REAL_OK` só com evidência real; senão skip honesto exit 0; **proibido** inventar device ou contar só `SRC=host` como sucesso E65; probe guest PCI só se não quebrar CI/E38
- [x] Task 3 — Gate Makefile + greps em `AGENTS.md`; anti-fraude (`REAL_OK`+`pci_passthrough` sem evidência → falha); regressão E38/E55; avaliar README (`readme-por-fatia`)
