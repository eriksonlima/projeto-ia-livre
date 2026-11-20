# Active context

## Foco atual

- Processo: backlog → roadmap (mínima interrupção)
- Etapa do roadmap: nenhuma `em_andamento` (Etapas 1–11 **feitas**)
- Spec ativa: nenhuma (última: `specs/kernel-pos-boot-services/`, Tasks 1–3 feitas)

## Mudanças recentes

- Etapa 11: ExitBootServices + UART COM1; `make verify` exige `EXIT_BOOT_OK` (+ mapa/mem pós-exit)
- Kernel: dual-phase (UEFI pré-exit → COM1 pós-exit)

## Próximo passo

- Propor topo do backlog (**B5 — Runtime nativo / Linha B real**) e esperar confirmação

## Notas

- Hipótese A vs B ainda não comprovada; Linha B = stub até B5
- README considerado nas fatias E11; sem mudança
