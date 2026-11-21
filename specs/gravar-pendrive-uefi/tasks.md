# Tasks — One-shot gravar pendrive UEFI (script + doc)

Uma task = uma fatia. Etapa 47 · Issue [#47](https://github.com/eriksonlima/projeto-ia-livre/issues/47).

- [x] Task 1 — Script `scripts/write-usb-esp.sh`
- [x] Task 2 — Docs `boot-hardware-real.md` + AGENTS + README
- [x] Task 3 — Gate `verify-write-usb` / `make verify-write-usb`

## Desfecho

Writer com confirmação explícita; gate CI sem USB → `IA_LIVRE_WRITE_USB_OK`; gravação ≠ `METAL_OK`.
