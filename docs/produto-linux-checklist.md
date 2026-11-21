# Checklist produto Linux IA Livre

Critérios (ADR 0027 / product-context):

| # | Métrica | Evidência |
|---|---------|-----------|
| 1 | Imagem bootável QEMU + USB | `verify-distro-debian-qemu` / `verify-distro-iso` / writer ISO |
| 2 | runtime/agent/node + qualquer GGUF | overlay + `model set` + smokes |
| 3 | Tuning/kernel mais nativo | tune avançado + ADR 0028 (stock deferred custom) |
| 4 | Rede no SO e nós host | `verify-distro-net` + `verify-node` independente |

Gate agregado: `make verify-produto-linux` → `IA_LIVRE_PRODUTO_LINUX_OK`.
