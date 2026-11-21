# Spec — Smoke QEMU exige imagem Debian (Etapa 83 / B78)

## Resultado

`verify-distro-smoke` (ou fluxo equivalente) exige boot da imagem Debian E82 (`IA_LIVRE_DISTRO_QEMU_OK` + evidência guest), com skip `need_*` honesto. **≠** Alpine netboot como prova.

## Pronto quando

Gate smoke passa com `DISTRO_QEMU_OK` quando tools existem; Alpine não conta como sucesso QEMU.
