# GPU manager nativo (Etapa 38)

Mecanismos **mínimos** no kernel IA Livre **pós-ExitBoot**: enum sintética, afinidade Weights/KvCache e placement Prefill/Decode, com prova na **UART COM1**.  
**Não** é o stub host da Etapa 25. **Não** é CUDA/Vulkan in-kernel. **Não** prova A vs B nem `TOKENS_PER_S`.

Spec: [`specs/gpu-manager-nativo/`](../specs/gpu-manager-nativo/).  
Desenho: [`desenho-gpu-manager-multi-gpu.md`](desenho-gpu-manager-multi-gpu.md) · ADR [`0006`](adr/0006-gpu-manager-multi-gpu.md).  
Complementa: [`memoria-scheduler-impl-minima.md`](memoria-scheduler-impl-minima.md) (E19).  
Fronteira host: [`gpu-manager-prototipo-host.md`](gpu-manager-prototipo-host.md) (E25).

## Fronteira host × nativo × Etapa 8

| Aspecto | E25 host stub | **E38 nativo** | E8 runtime GPU |
|---------|---------------|----------------|----------------|
| Onde | Linux `std` | Kernel pós-ExitBoot (COM1) | Host llama.cpp |
| Identidade | `GPU_MGR=host_stub` | **`GPU_MGR=native`** | `IA_LIVRE_ACCEL=` |
| Gate | `make verify-gpu-manager` | `make verify` (aditivo) | `make verify-runtime-gpu` |
| GPU real | nvidia-smi (ou skip) | **Sintética no QEMU** (N=1) | CUDA/Vulkan |

**Proibido** emitir `host_stub` no caminho do kernel.

## Decisão (QEMU de referência)

| Peça | Valor |
|------|--------|
| Devices | `IA_LIVRE_GPU_DEVICES=1` + `IA_LIVRE_GPU_DEV0_KIND=synthetic` |
| Afinidade | `weights` → device `0`; `kvcache` → device `0` |
| Placement | Prefill: `device0\|weights`; Decode: `device0\|kvcache` |
| Shard | `IA_LIVRE_GPU_SHARD_DOC=pipeline_layer` (**só documentado**) |
| Momento | Após `IA_LIVRE_MEM_SCHED_OK`; antes de `NATIVE_BENCH_*` |

## Marcadores (COM1)

```
IA_LIVRE_GPU_MGR=native
IA_LIVRE_GPU_DEVICES=1
IA_LIVRE_GPU_DEV0_KIND=synthetic
IA_LIVRE_GPU_AFFIN_CLASS=weights
IA_LIVRE_GPU_AFFIN_DEV=0
IA_LIVRE_GPU_AFFIN_CLASS=kvcache
IA_LIVRE_GPU_AFFIN_DEV=0
IA_LIVRE_GPU_PLACE_PHASE=prefill
IA_LIVRE_GPU_PLACE_HINT=device0|weights
IA_LIVRE_GPU_PLACE_PHASE=decode
IA_LIVRE_GPU_PLACE_HINT=device0|kvcache
IA_LIVRE_GPU_SHARD_DOC=pipeline_layer
IA_LIVRE_GPU_MGR_OK
```

Anti-fraude: gate exige `GPU_MGR=native` + `GPU_DEVICES=` + afinidade/placement + `GPU_MGR_OK`. **Não** exige `DEVICES≥2`.

## Limites

- Sem driver vendor, PCI pass-through, multi-GPU executado, offload GGUF real.
- GPU **real** (além de `synthetic`) = Etapa 55 — [`gpu-real-nativo.md`](gpu-real-nativo.md) (`GPU_REAL_*` / `NEED_GPU`); E38 synthetic permanece no `make verify`.
- Sem mudança de semântica do stub E25 / Etapa 8.
- Hipótese A vs B e harness comparable **intocados**.

## Como observar

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
make build && make run   # serial: … MEM_SCHED_OK → GPU_MGR=native … GPU_MGR_OK → NATIVE_BENCH_*
make verify
# Stub host permanece separado:
make verify-gpu-manager
```
