---
name: verificar-boot-kernel
description: Roda o gate de boot UEFI do kernel IA Livre (make verify / IA_LIVRE_BOOT_OK). Use ao validar mudanças no kernel ou na Etapa 4+.
disable-model-invocation: true
---

# Verificar boot do kernel

## Quando

Após alterar `kernel/`, `Makefile` ou scripts de QEMU; antes de declarar fatia do bootstrap pronta.

## Pré-requisitos

- Rust + target `x86_64-unknown-uefi`
- Pacotes: `qemu-system-x86`, `ovmf`
- `PATH` com `$HOME/.cargo/bin` e `$HOME/.local/bin`

## Comandos

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
make build
make verify
```

Sucesso: saída contendo `GATE_OK: encontrada IA_LIVRE_BOOT_OK`.

Timeout: `VERIFY_TIMEOUT=60 make verify`.

## Não fazer

- Não exigir bare metal; QEMU basta
- Não expandir o gate para MMU/GPU/LLM nesta skill
