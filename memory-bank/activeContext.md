# Active context

## Foco atual

- Etapa do roadmap: Etapa 5 — Runtime mínimo de inferência (CPU)
- Spec ativa: specs/runtime-inferencia-cpu/ _(ainda a criar)_
- Fatia / task: especificar runtime CPU

## Mudanças recentes

- Etapa 4 feita: boot UEFI + `IA_LIVRE_BOOT_OK` + `make verify`
- Kernel em `kernel/` com uefi-rs; gate em `scripts/verify-boot.sh`

## Próximo passo

- Especificar Etapa 5 (`/especificar` → runtime-inferencia-cpu)

## Notas

- Gate kernel: `make verify` (marcador `IA_LIVRE_BOOT_OK`)
- ADR 0001: inteligência pesada fora do kernel — runtime é camada 2
