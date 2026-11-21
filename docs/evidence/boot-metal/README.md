# Evidências — boot UEFI em hardware real

Pasta para **reports ESP** (padrão Etapa 73 / ADR 0025) ou logs seriados legados.

Contrato: [`docs/baremetal-report.md`](../../baremetal-report.md).

## Como adicionar (caminho A — padrão ESP, sem COM1)

1. Gerar e gravar: `make baremetal-esp` + `./scripts/write-usb-esp.sh …`
2. Boot no PC até tela azul / `EXIT_BOOT_BEGIN`
3. No Linux, montar o pendrive e copiar `IA_LIVRE/baremetal-report.txt`
4. Salvar aqui como `YYYY-MM-DD-<host>.txt`
5. Validar:
   ```bash
   IA_LIVRE_BAREMETAL_SKIP=0 \
   IA_LIVRE_BAREMETAL_EVIDENCE=docs/evidence/boot-metal/YYYY-MM-DD-<host>.txt \
   make verify-baremetal
   ```

## Serial (legado / lab com cabo)

Ainda válido: capturar COM1 115200 8N1 — ver `docs/boot-hardware-real.md` / `TEMPLATE.txt`.

## Fixture CI

`fixture-esp-report.txt` — formato do report (≠ prova de PC deste host).

## Estado

- **2026-11-21:** canal ESP adotado (E73); sem report de PC versionado ainda neste repo → CI default `SKIP=1`.
- Vídeo local do operador ≠ input do gate.
- **Não** copie saída de QEMU como evidência de metal.
