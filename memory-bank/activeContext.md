# Active context

## Foco atual

- Etapa do roadmap: Etapa 4 — Bootstrap do kernel IA Livre
- Spec ativa: specs/bootstrap-kernel/
- Fatia / task: Task 2 — `IA_LIVRE_BOOT_OK` na serial + gate completo

## Mudanças recentes

- Task 1 feita: crate `kernel/`, workspace, Makefile (`build`/`esp`/`run`), AGENTS atualizado
- `make build` gera `ia-livre-kernel.efi`; ESP em `build/esp/`
- `make run` exige `qemu-system-x86` + `ovmf` no host (ainda não instalados neste ambiente sem sudo)

## Próximo passo

- Usuário: `sudo apt install qemu-system-x86 ovmf` (se ainda não tiver)
- Implementar Task 2 (hello serial + gate)

## Notas

- Mensagem canônica Task 2: `IA_LIVRE_BOOT_OK`
- `CARGO_TARGET_DIR` fixado no Makefile para `./target`
