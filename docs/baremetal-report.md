# Relatório bare-metal na ESP (Etapas 73–74)

Canal **padrão** de evidências e métricas bare-metal **sem COM1**.  
ADR: [`0025-baremetal-report-esp.md`](adr/0025-baremetal-report-esp.md) · pós-exit: Etapa 74.

## Arquivo

| Campo | Valor |
|-------|--------|
| Path na ESP | `\IA_LIVRE\baremetal-report.txt` |
| Pré-exit | SimpleFileSystem write + flush (Boot Services) |
| Pós-exit | Slot `IALVPST1` no mesmo arquivo; rewrite via **BlockIO** |
| Sucesso pré | `IA_LIVRE_BAREMETAL_REPORT_OK` |
| Sucesso pós | `IA_LIVRE_BAREMETAL_REPORT_POST_OK` |
| Falha | `IA_LIVRE_BAREMETAL_REPORT_FAIL=…` / `REPORT_POST_FAIL=…` (boot continua) |

## Formato V1 (+ slot pós-exit)

```text
# IA_LIVRE_BAREMETAL_REPORT_V1
# MEDIA=usb_esp_file
# WRITTEN_PRE_EXIT=1
IA_LIVRE_BOOT_OK
…
IA_LIVRE_OBS_OK
IA_LIVRE_BAREMETAL_REPORT_OK

# POST_EXIT_SLOT
IALVPST1
IA_LIVRE_EXIT_BOOT_OK
…
IA_LIVRE_MEM_SCHED_OK
…
IA_LIVRE_BAREMETAL_REPORT_POST_OK
```

Alias legado no gate: cabeçalho `# IA_LIVRE_BAREMETAL_EVIDENCE_V1` ainda aceito se o corpo tiver `BOOT_OK`.

## Canais

| Canal | Papel |
|-------|--------|
| ESP report (pré + pós) | **Padrão** operador / `METAL_OK` + métricas pós-exit |
| UART COM1 | QEMU / lab com cabo; também emite `REPORT_POST_OK` |
| GOP / ConOut | Humano; ≠ gate |
| Vídeo | Anexo opcional; ≠ gate |

## Fluxo operador

1. `make baremetal-esp` + `./scripts/write-usb-esp.sh …`
2. Boot no PC até o fim do caminho nativo (tela / halt)
3. Desligar; no Linux, montar o pendrive
4. Copiar `IA_LIVRE/baremetal-report.txt` → `docs/evidence/boot-metal/YYYY-MM-DD-<host>.txt`
5. Validar:

```bash
IA_LIVRE_BAREMETAL_SKIP=0 \
IA_LIVRE_BAREMETAL_EVIDENCE=docs/evidence/boot-metal/YYYY-MM-DD-<host>.txt \
make verify-baremetal
```

Esperado: `IA_LIVRE_BAREMETAL_METAL_OK`. Com Etapa 74 ok no metal, o arquivo também contém `EXIT_*` / `REPORT_POST_OK`.

## Limites

- BlockIO pós-ExitBoot é **best-effort** (firmware); falha → `REPORT_POST_FAIL` honesto + UART.
- CI default `IA_LIVRE_BAREMETAL_SKIP=1` — não promove metal a partir de QEMU.
- Proibido colar log QEMU/OVMF como evidência metal.
- Em QEMU, preferir imagem FAT32 (`.img` / `run-qemu-esp-fat32.sh`) para persistir o arquivo no host.
- **Não** alimenta harness comparable / `COMPROVA` (ADR 0026).
