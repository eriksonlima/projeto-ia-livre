# Spec — Canal padrão bare-metal: relatório na ESP

Etapa 73 · Issue [#74](https://github.com/eriksonlima/projeto-ia-livre/issues/74) (ex-B68)

## Resultado

Arquivo `\\IA_LIVRE\\baremetal-report.txt` é o **canal padrão** de evidências/métricas bare-metal (pré-ExitBoot via SFS). `METAL_OK` aceita esse report sem COM1. Serial permanece válido; vídeo fora do gate.

## Decisão

A — buffer + flush SFS antes de `EXIT_BOOT_BEGIN`; ADR 0025; gate `verify-baremetal` SKIP=0.

## Critérios

- Report V1 com `MEDIA=usb_esp_file`, `BOOT_OK`, `OBS_OK`, `BAREMETAL_REPORT_OK`
- Falha de write → `REPORT_FAIL` honesto; não inventa METAL_OK
- CI default SKIP=1; fixture de formato; QEMU não promove METAL_OK
