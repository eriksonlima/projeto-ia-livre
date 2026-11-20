# Progress

## O que funciona

- Kernel: `make verify` → EXIT_BOOT_OK + NATIVE_BENCH_OK
- Harness: `make verify-harness` → A (GGUF) + B (proxy QEMU); hipótese não comprovada
- Runtime CPU/GPU, nó, agent
- Etapas 1–12 feitas

## Bloqueios

- Inferência GGUF nativa no IA Livre (carga canônica em B) ainda aberta
- CUDA Toolkit ausente no host → Vulkan (ADR 0002)

## Por etapa

- Etapas 1–12: feitas
- Backlog Abertas (topo): B6 (#12), B8–B12 (#14–#18)
