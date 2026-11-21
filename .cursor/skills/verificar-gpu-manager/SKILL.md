---
name: verificar-gpu-manager
description: Roda o gate do stub host GPU manager (make verify-gpu-manager / IA_LIVRE_GPU_MGR_OK ou skip). Use ao validar Etapa 25 / B19 ou scripts do stub.
disable-model-invocation: true
---

# Verificar GPU manager (stub host)

## Quando

Após alterar `scripts/gpu-manager-stub.sh`, `scripts/verify-gpu-manager.sh` ou `docs/gpu-manager-prototipo-host.md`; antes de declarar fatia da Etapa 25 pronta.

## Pré-requisitos

- `PATH` com `$HOME/.cargo/bin` e `$HOME/.local/bin`
- **Não** exige GGUF, QEMU nem offload llama.cpp
- Stub ≠ manager nativo; não prova A vs B

## Comandos

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
make verify-gpu-manager
```

Sucesso com GPU: `GATE_OK` + `IA_LIVRE_GPU_MGR=host_stub` + `IA_LIVRE_GPU_MGR_OK`.

**Skip (CI / sem GPU):**

```bash
VERIFY_GPU_MANAGER_SKIP=1 make verify-gpu-manager
# ou nvidia-smi indetectável → IA_LIVRE_GPU_MGR_SKIP exit 0
```

Force: `VERIFY_GPU_MANAGER_FORCE=1`.

## Não fazer

- Não confundir com `make verify-runtime-gpu` (Etapa 8 / offload)
- Não editar `kernel/` neste gate
- Não fingir multi-GPU ou `IA_LIVRE_ACCEL≠cpu`
