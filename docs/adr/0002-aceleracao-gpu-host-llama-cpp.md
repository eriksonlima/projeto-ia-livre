# ADR 0002 — Aceleração GPU no host via llama.cpp (CUDA canônico / Vulkan alternativa)

- Status: aceita
- Data: 2026-11-20

## Contexto

A Etapa 5 entregou inferência CPU no host (`ia-livre-runtime` / `llama-cpp-2`, `n_gpu_layers=0`). A arquitetura deixava aberta a “estratégia de aceleração além de CPU (CUDA/ROCm vs backends próprios; escopo do GPU manager)”. A Etapa 8 precisa de um **protótipo pragmático** de offload GPU **na camada 2 (runtime) no host**, sem GPU manager no kernel e sem multi-GPU — alinhado ao ADR 0001.

## Decisão

1. **Ambiente:** aceleração GPU desta etapa vive no **host Linux** (`std`), estendendo `runtime/` — **não** no kernel UEFI / QEMU.
2. **Stack:** continuar `llama-cpp-2` / llama.cpp; ativar backends via **features Cargo opcionais** no crate `ia-livre-runtime`.
3. **Backend canônico:** **CUDA** (feature `cuda`) quando o host tiver NVIDIA + toolkit compatível.
4. **Alternativa documentada:** **Vulkan** (feature `vulkan`) se CUDA for inviável no host mas houver GPU Vulkan utilizável.
5. **ROCm / Metal / backends próprios:** fora do caminho crítico desta etapa (não são critério de aceite).
6. **Offload:** flag CLI `--n-gpu-layers <N>`; default **`0`** = CPU (preserva Etapa 5). Build **default** sem feature GPU permanece CPU-only.
7. **Fallback CPU:** obrigatório — gate CPU (`make verify-runtime`) não regride; gate GPU tem política de skip quando não há GPU.
8. **Fora de escopo desta decisão:** multi-GPU, tensor/pipeline parallel, GPU manager no kernel, treino, troca de modelo canônico.  
   *(Desenho candidato desses itens: ADR [`0006`](0006-gpu-manager-multi-gpu.md) + [`desenho-gpu-manager-multi-gpu.md`](../desenho-gpu-manager-multi-gpu.md) — **não** altera este protótipo host.)*

## Consequências

### Positivas

- Reutiliza o stack já gateado (GGUF TinyLlama + métricas da Etapa 5)
- Features opcionais isolam o build CPU default de toolchains CUDA/Vulkan
- Critérios de aceite claros: prova de caminho com `IA_LIVRE_ACCEL≠cpu` + skip documentado sem GPU
- Fecha a decisão aberta de arquitetura no nível “protótipo host”, sem comprometer o desenho futuro do GPU manager no SO

### Negativas

- Dependência de toolchain NVIDIA/CUDA (ou Vulkan) no host de prova
- Binding/feature do llama.cpp pode exigir notas de host (`cuda-no-vmm`, paths, etc.)
- Não resolve ainda aceleração nativa no kernel IA Livre nem multi-GPU

## Nota do host de referência (2026-11-20)

No Acer Nitro 5 (GTX 1050, driver 535), a feature **`cuda`** falhou no build (`nvcc` / CUDA Toolkit ausentes). A prova da Etapa 8 usou a alternativa **`vulkan`** (LunarG SDK em user-space + `--n-gpu-layers 99`), com `IA_LIVRE_ACCEL=vulkan`. CUDA permanece o backend **canônico** quando o toolkit estiver instalado.
