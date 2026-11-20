---
name: build-runtime-cpu
description: Compila o protótipo ia-livre-runtime (llama-cpp-2) no host e obtém o GGUF canônico. Use ao validar ou alterar runtime/ na Etapa 5.
disable-model-invocation: true
---

# Build do runtime CPU

## Quando

Após alterar `runtime/`, dependências llama.cpp, ou antes de rodar inferência/gate da Etapa 5.

## Pré-requisitos

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
# Se bindgen falhar com stdbool.h:
export BINDGEN_EXTRA_CLANG_ARGS="${BINDGEN_EXTRA_CLANG_ARGS:--I/usr/lib/gcc/x86_64-linux-gnu/13/include -I/usr/include}"
```

Host: `build-essential`, `cmake` (apt ou binário em `~/.local`), libclang (`LIBCLANG_PATH`). Ver `AGENTS.md`.

## Comandos

```bash
./scripts/fetch-model.sh
cargo build -p ia-livre-runtime
cargo run -p ia-livre-runtime -- --model models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
```

Sucesso: texto gerado na stdout + linha `IA_LIVRE_INFER_OK`.  
Prompt padrão: `Complete em uma frase: O Projeto IA Livre é`.

## Não fazer

- Não buildar com `--target x86_64-unknown-uefi` (runtime é host/`std`)
- Não commitar `models/` nem `*.gguf`
- Não ativar features CUDA/Metal/Vulkan/ROCm nesta etapa
