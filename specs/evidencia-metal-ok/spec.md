# Spec — Evidência METAL_OK em PC real

## Resultado

`METAL_OK` com log serial de PC **ou** bloqueio honesto sem fabricar evidência.

## Contexto

- `docs/evidence/boot-metal/STATUS-SKIP.txt` — `REASON=no_pc_serial_log_on_this_host` (E46)
- Artefato/guia/writer já verdes; falta PC com captura serial

## Decisão

| Opção | Quando |
|-------|--------|
| **A — METAL_OK** | Operador fornece log real (≥ `BOOT_OK`, sem QEMU/OVMF) |
| **B — Bloqueio honesto** | Este host sem PC/serial; documentar e **não** fabricar log |

Escolha nesta máquina de CI/dev: **B**.

## Fora de escopo

Fabricar log; fingir `METAL_OK`; I/O GGUF metal (B57).

## Aceite

- [ ] STATUS-SKIP ou log real atualizado para E62
- [ ] `verify-baremetal` honesto (SKIP ou METAL_OK)
- [ ] Checklist/docs ponte; sem COMPROVA/metal falso
