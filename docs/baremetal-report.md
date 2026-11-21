# Relatório bare-metal na ESP (Etapa 73)

Canal **padrão** de evidências e métricas bare-metal **sem COM1**.  
ADR: [`0025-baremetal-report-esp.md`](adr/0025-baremetal-report-esp.md).

## Arquivo

| Campo | Valor |
|-------|--------|
| Path na ESP | `\IA_LIVRE\baremetal-report.txt` |
| Quando | **Antes** de `IA_LIVRE_EXIT_BOOT_BEGIN` (Boot Services) |
| Mecanismo | SimpleFileSystem write + flush |
| Sucesso | `IA_LIVRE_BAREMETAL_REPORT_OK` |
| Falha | `IA_LIVRE_BAREMETAL_REPORT_FAIL=…` (boot continua) |

## Formato V1

```text
# IA_LIVRE_BAREMETAL_REPORT_V1
# MEDIA=usb_esp_file
# WRITTEN_PRE_EXIT=1
IA_LIVRE_BOOT_OK
…
IA_LIVRE_OBS_OK
IA_LIVRE_BAREMETAL_REPORT_OK
```

Alias legado no gate: cabeçalho `# IA_LIVRE_BAREMETAL_EVIDENCE_V1` ainda aceito se o corpo tiver `BOOT_OK`.

## Canais

| Canal | Papel |
|-------|--------|
| ESP report | **Padrão** operador / `METAL_OK` |
| UART COM1 | QEMU / lab com cabo |
| GOP / ConOut | Humano; ≠ gate |
| Vídeo | Anexo opcional; ≠ gate |

## Fluxo operador

1. `make baremetal-esp` + `./scripts/write-usb-esp.sh …`
2. Boot no PC até a tela azul / `EXIT_BOOT_BEGIN`
3. Desligar; no Linux, montar o pendrive
4. Copiar `IA_LIVRE/baremetal-report.txt` → `docs/evidence/boot-metal/YYYY-MM-DD-<host>.txt`
5. Validar:

```bash
IA_LIVRE_BAREMETAL_SKIP=0 \
IA_LIVRE_BAREMETAL_EVIDENCE=docs/evidence/boot-metal/YYYY-MM-DD-<host>.txt \
make verify-baremetal
```

Esperado: `IA_LIVRE_BAREMETAL_METAL_OK`.

## Limites

- Pós-ExitBoot **não** entra neste arquivo (SFS invalidado).
- CI default `IA_LIVRE_BAREMETAL_SKIP=1` — não promove metal a partir de QEMU.
- Proibido colar log QEMU/OVMF como evidência metal.
- Em QEMU, preferir imagem FAT32 (`.img` / `run-qemu-esp-fat32.sh`): o `fat:rw:` de diretório pode **não** espelhar o arquivo de volta ao host; no pendrive real o arquivo persiste.
