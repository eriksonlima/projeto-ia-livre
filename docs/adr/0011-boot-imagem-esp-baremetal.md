# ADR 0011 — Imagem ESP/USB como prova CI de bare-metal

- Status: aceita
- Data: 2026-11-21

## Contexto

O kernel sobe em QEMU+OVMF. Não há caminho documentado para PC UEFI real. Exigir boot físico no CI é inviável; declarar QEMU como bare-metal seria fraude.

## Decisão

1. **Artefato:** árvore ESP empacotável (`build/baremetal-esp/`) com `EFI/BOOT/BOOTX64.EFI` (+ tar); imagem FAT `.img` **opcional** se `mtools` estiver instalado.
2. **Gate CI:** `make verify-baremetal` valida o **artefato** (estrutura + EFI + checksum) — **não** boot em hardware.
3. **Hardware real:** checklist manual + `IA_LIVRE_BAREMETAL_SKIP=1` para o trecho metal; **não** dispensa `IMAGE_OK`.
4. **QEMU ≠ bare-metal.** Sem `TOKENS_PER_S` / harness COMPROVA nesta etapa.

## Rejeitado

- Exigir PC físico no CI
- Tratar `make verify` (QEMU) como prova de metal
- Instalador/desktop/Secure Boot assinado
- Embutir motor de inferência nesta etapa

## Consequências

- Doc `docs/boot-hardware-real.md`; scripts `make-baremetal-esp.sh` / `verify-baremetal.sh`
- Limites GGUF/serial/Secure Boot documentados honestamente
