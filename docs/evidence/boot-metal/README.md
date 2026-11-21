# Evidências — boot UEFI em hardware real

Pasta para logs seriados capturados em **PC físico** (Etapa 35).

## Como adicionar

1. Gerar ESP: `make baremetal-esp`
2. Anotar `sha256sum build/baremetal-esp/EFI/BOOT/BOOTX64.EFI`
3. Gravar mídia e capturar serial (115200 8N1) — ver `docs/boot-hardware-real.md`
4. Salvar aqui como `YYYY-MM-DD-<host>.txt` no formato `IA_LIVRE_BAREMETAL_EVIDENCE_V1`
5. Validar: `IA_LIVRE_BAREMETAL_SKIP=0 IA_LIVRE_BAREMETAL_EVIDENCE=docs/evidence/boot-metal/….txt make verify-baremetal`

## Template

Ver `TEMPLATE.txt` nesta pasta. **Não** copie saída de QEMU como evidência de metal.

## Estado

Sem log de PC anexado ainda → gate usa `IA_LIVRE_BAREMETAL_SKIP=1` (honesto).
