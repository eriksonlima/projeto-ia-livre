---
name: verificar-boot-kernel
description: >-
  Roda o gate do kernel UEFI (make verify): BOOT_OK + mem/alloc +
  OBS_OK (GOP/input E37) + EXIT_BOOT_OK via COM1 pós-ExitBootServices.
  Use ao validar mudanças em kernel/, scripts/verify-boot.sh ou contratos
  das Etapas 4/10/11/37.
disable-model-invocation: true
---

# Verificar boot / pós-Boot Services do kernel

## Quando

Após alterar `kernel/`, `scripts/verify-boot.sh`, `Makefile` (alvos de QEMU) ou docs `kernel-alem-do-boot.md` / `kernel-pos-boot-services.md`; antes de declarar fatia do kernel pronta.

## Pré-requisitos

- Rust + target `x86_64-unknown-uefi`
- Pacotes: `qemu-system-x86`, `ovmf`
- `PATH` com `$HOME/.cargo/bin` e `$HOME/.local/bin`

## Contratos

- Etapa 10 (Boot Services): [`docs/kernel-alem-do-boot.md`](../../../docs/kernel-alem-do-boot.md)
- Etapa 11 (ExitBoot + UART COM1 `0x3F8`): [`docs/kernel-pos-boot-services.md`](../../../docs/kernel-pos-boot-services.md)
- Etapa 37 (GOP/input mínimo): [`docs/observabilidade-minima-so.md`](../../../docs/observabilidade-minima-so.md)

## Comandos

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
make build
make verify
```

Sucesso: linha contendo `GATE_OK: kernel` e evidência de `BOOT_OK`, `MEM_MAP_OK`, `ALLOC_OK`, `EXIT_BOOT_OK` (o script também exige `EXIT_BOOT_BEGIN`, `EXIT_MAP_OK`, `EXIT_MEM_OK` e linhas `*=`).

Timeout: `VERIFY_TIMEOUT=60 make verify`.

## Marcadores mínimos

Pré-exit (Serial UEFI): `IA_LIVRE_BOOT_OK`, `MEM_*`, `ALLOC_*`, `OBS_OK` (+ `GOP_OK` ou `INPUT_OK`), `EXIT_BOOT_BEGIN`  
Pós-exit (COM1): `EXIT_MAP_*`, `EXIT_MEM_OK`, `EXIT_BOOT_OK`

## Não fazer

- Não exigir bare metal; QEMU basta
- Não usar Serial UEFI após `exit_boot_services`
- Não expandir o gate para MMU completa, GPU, LLM ou Linha B nesta skill
- Não substituir gates de runtime/node/agent/harness
