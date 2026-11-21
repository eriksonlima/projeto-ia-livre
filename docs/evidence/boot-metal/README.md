# Evidências — boot UEFI em hardware real

Pasta para logs seriados capturados em **PC físico** (Etapas 35 / 46).

## Como adicionar (caminho A)

1. Gerar ESP: `make baremetal-esp`
2. Anotar `sha256sum build/baremetal-esp/EFI/BOOT/BOOTX64.EFI`
3. Gravar mídia e capturar serial (115200 8N1) — ver `docs/boot-hardware-real.md`
4. Salvar aqui como `YYYY-MM-DD-<host>.txt` no formato `IA_LIVRE_BAREMETAL_EVIDENCE_V1`
5. Validar: `IA_LIVRE_BAREMETAL_SKIP=0 IA_LIVRE_BAREMETAL_EVIDENCE=docs/evidence/boot-metal/….txt make verify-baremetal`

## Template

Ver `TEMPLATE.txt` nesta pasta. **Não** copie saída de QEMU como evidência de metal.

## Estado (Etapa 46 — caminho B)

- **2026-11-21:** sem log de PC anexado neste host de desenvolvimento → `IA_LIVRE_BAREMETAL_SKIP=1` (honesto).
- Issue [#46](https://github.com/eriksonlima/projeto-ia-livre/issues/46): bloqueio por ausência de hardware/serial; reabrir caminho A quando houver log real.
- Arquivo sentinela: `STATUS-SKIP.txt`
