# AGENTS.md

Brief do repositório para agentes. Em conflito com outros arquivos de ferramenta, este arquivo e `.cursor/rules/` vencem para o processo; `CLAUDE.md` apenas aponta para cá.

## Projeto

- Nome: `Projeto IA Livre`
- Resumo: Ecossistema open source brasileiro com SO próprio (IA Livre) especializado em IA nativa e rede P2P (Rede IA Livre) para colaboração computacional e de conhecimento. Participar da rede não exige o SO.
- Stack: Kernel mínimo em Rust (`uefi-rs`, target `x86_64-unknown-uefi`) + QEMU/OVMF; runtime de inferência no host (`runtime/` + llama.cpp; CPU default, GPU opcional via CUDA/Vulkan); protótipo do nó Rede IA Livre no host (`node/`, TCP/UDP — **sem** exigir o SO IA Livre); protótipo do ambiente de autonomia no host (`agent/`, consome o runtime — **sem** exigir o SO IA Livre).

## Como rodar

### Pré-requisitos (host)

```bash
# Rust (se ainda não tiver)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. "$HOME/.cargo/env"
rustup target add x86_64-unknown-uefi

# QEMU + firmware UEFI (Ubuntu/Debian)
sudo apt install qemu-system-x86 ovmf

# Runtime CPU (llama-cpp-2): compilador C/C++, cmake e libclang
sudo apt install build-essential cmake libclang-dev pkg-config
# Se cmake/libclang não puderem ir via apt: cmake oficial em ~/.local e
# export LIBCLANG_PATH=/usr/lib/llvm-XX/lib  (ajuste XX)
```

Opcional: `OVMF_BIOS=/caminho/OVMF.fd` ou `OVMF_CODE` + `OVMF_VARS_TEMPLATE` se a firmware não estiver nos paths padrão.

### Build e QEMU (kernel)

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
cd /caminho/para/projeto-ia-livre

make build    # gera target/x86_64-unknown-uefi/debug/ia-livre-kernel.efi
make run      # ESP em build/esp + QEMU UEFI, serial no stdio
make verify   # gate automatizado (IA_LIVRE_BOOT_OK)
```

Equivalente interativo: `./scripts/run-qemu.sh`.

Na serial deve aparecer a linha canônica: `IA_LIVRE_BOOT_OK`.

### Runtime de inferência (host — Etapas 5 / 8)

Protótipo na **camada 2**, no host Linux (`std`), **não** no kernel UEFI. Backend: **llama-cpp-2** / llama.cpp. Default = **CPU**; GPU opcional via features Cargo (ADR 0002: CUDA canônico / Vulkan alternativa).

Modelo canônico (não versionado no git):

| Campo | Valor |
|-------|--------|
| Nome | TinyLlama 1.1B Chat v1.0 |
| Quantização | Q4_K_M (GGUF) |
| Arquivo | `models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf` (~638 MiB) |
| Fonte | Hugging Face `TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF` |

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
# Se bindgen falhar com "stdbool.h not found" (clang incompleto):
export BINDGEN_EXTRA_CLANG_ARGS="${BINDGEN_EXTRA_CLANG_ARGS:--I/usr/lib/gcc/x86_64-linux-gnu/13/include -I/usr/include}"

# Baixar pesos (gitignored)
./scripts/fetch-model.sh

# Build do runtime (target host) — default CPU, sem feature GPU
cargo build -p ia-livre-runtime

# Inferência CPU (prompt padrão documentado; --n-gpu-layers default 0)
cargo run -p ia-livre-runtime -- --model models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
```

Prompt padrão (fixado): `Complete em uma frase: O Projeto IA Livre é`  
`--n-gpu-layers` default `0` (CPU). Saída: texto gerado + `IA_LIVRE_INFER_OK` + métricas `IA_LIVRE_LOAD_S=` / `IA_LIVRE_TOKENS_PER_S=` + `IA_LIVRE_ACCEL=` / `IA_LIVRE_N_GPU_LAYERS=`.  
Opcional: `--prompt "..."` / `--n-predict 32` / `--n-gpu-layers <N>`.  
Métricas CPU: `docs/runtime-inferencia-cpu-metricas.md`.  
Fallback CLI do llama.cpp: só se a binding falhar no host — documentar a escolha aqui se for adotada.

#### Aceleração GPU (host — Etapa 8)

ADR: [`docs/adr/0002-aceleracao-gpu-host-llama-cpp.md`](docs/adr/0002-aceleracao-gpu-host-llama-cpp.md). **CUDA** = canônico; **Vulkan** = alternativa se CUDA Toolkit (`nvcc`) estiver ausente.

Pré-requisitos (além de cmake/libclang):

| Backend | Precisa |
|---------|---------|
| `cuda` | NVIDIA driver + **CUDA Toolkit** (`nvcc` no PATH / `CUDAToolkit_ROOT`) |
| `vulkan` | Driver com ICD Vulkan + headers/`glslc` (ex.: LunarG Vulkan SDK em `~/.local/opt/<ver>/x86_64`) |

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

# Exemplo Vulkan (host de referência — SDK user-space):
export VULKAN_SDK="${VULKAN_SDK:-$HOME/.local/opt/1.3.296.0/x86_64}"
export PATH="$VULKAN_SDK/bin:$PATH"
export LD_LIBRARY_PATH="$VULKAN_SDK/lib:${LD_LIBRARY_PATH:-}"

cargo build -p ia-livre-runtime --features vulkan
# ou: cargo build -p ia-livre-runtime --features cuda

cargo run -p ia-livre-runtime --features vulkan -- \
  --model models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
  --n-predict 32 \
  --n-gpu-layers 99
```

Esperado: `IA_LIVRE_INFER_OK`, `IA_LIVRE_ACCEL=vulkan` (ou `cuda`), `IA_LIVRE_N_GPU_LAYERS=99`.  
Com `--n-gpu-layers 0` (ou build sem feature) permanece CPU (`IA_LIVRE_ACCEL=cpu`).  
Métricas GPU: `docs/runtime-inferencia-gpu-metricas.md`. Gate automatizado: `make verify-runtime-gpu`.

### Nó Rede IA Livre (host — Etapa 6)

Protótipo da **camada 4** no host Linux (`std`). **Não** precisa do kernel UEFI, QEMU, GGUF nem do runtime de inferência. Participar da Rede **não exige** o SO IA Livre (ADR 0001).

Protocolo mínimo: [`docs/rede-ia-livre-prototipo.md`](docs/rede-ia-livre-prototipo.md).

Pré-requisito: só Rust no host (target nativo).

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

cargo build -p ia-livre-node

# Dois processos no mesmo host (simulação de dois nós) — fallback --peer (recomendado no gate)
# Terminal A:
cargo run -p ia-livre-node -- --tcp-port 7400 --node-id alice

# Terminal B (dial explícito):
cargo run -p ia-livre-node -- --tcp-port 7401 --node-id bob --peer 127.0.0.1:7400
```

Em ambos deve aparecer `IA_LIVRE_PEER_OK` (e opcionalmente `IA_LIVRE_PEER_ADDR=…`).
Após a sessão, troca `MSG ola-rede-ia-livre` / `ACK ola-rede-ia-livre` e aparece `IA_LIVRE_MSG_OK`.

Descoberta UDP: ambos anunciam `HELLO` na porta `--udp-port` (default `7410`); ao ver o outro `node_id`, dialam o TCP anunciado. Se UDP falhar no ambiente, use `--peer` como acima.

Gate automatizado: `make verify-node` (não exige QEMU, GGUF nem runtime).

### Ambiente de autonomia (host — Etapa 7)

Protótipo da **camada 3** no host Linux (`std`). **Não** precisa do kernel UEFI / QEMU. Consome o runtime CPU existente (`ia-livre-runtime`) e o GGUF canônico. Este protótipo de autonomia **não exige** o SO IA Livre (ADR 0001).

Contrato mínimo: [`docs/ambiente-autonomia-prototipo.md`](docs/ambiente-autonomia-prototipo.md).

Pré-requisitos: Rust no host + deps/modelo do runtime (ver seção Runtime acima). **Sem** QEMU/OVMF para o agente.

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

# Modelo (se ainda não baixado)
./scripts/fetch-model.sh

# Build do runtime (consumido via subprocesso) + agente
cargo build -p ia-livre-runtime -p ia-livre-agent

# Cenário de prova: chama runtime → ferramenta note → IA_LIVRE_TOOL_OK
cargo run -p ia-livre-agent -- \
  --model models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
  --memory build/agent-memory/memory.jsonl
```

Flags: `--model` (default GGUF canônico), `--memory` (default `build/agent-memory/memory.jsonl`), `--n-predict` (default `16`), `--runtime-bin` (opcional; senão usa `target/debug/ia-livre-runtime`).

Saída esperada: `IA_LIVRE_RUNTIME_USED=1`, `IA_LIVRE_TOOL_OK`, `IA_LIVRE_MEMORY_OK`, `IA_LIVRE_AGENT_OK`.

Gate automatizado: `make verify-agent` (não exige QEMU/UEFI nem o nó P2P; requer GGUF).

## Como verificar

### Gate do kernel (Etapa 4)

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
test -f README.md && test -f AGENTS.md && test -f ROADMAP.md
test -d kernel && test -f kernel/Cargo.toml && test -f kernel/src/main.rs
test -f Makefile && test -f Cargo.toml
make build
test -f target/x86_64-unknown-uefi/debug/ia-livre-kernel.efi
make verify
grep -q 'IA_LIVRE_BOOT_OK' kernel/src/main.rs
```

`make verify` falha se `IA_LIVRE_BOOT_OK` não aparecer na serial do QEMU (timeout padrão 45s; override com `VERIFY_TIMEOUT`).

### Gate do runtime (Etapa 5 — adicional)

Requer o GGUF local (`./scripts/fetch-model.sh` na primeira vez). Não usa QEMU.

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
test -d runtime && test -f runtime/Cargo.toml && test -f runtime/src/main.rs
test -f scripts/verify-runtime.sh && test -f scripts/fetch-model.sh
test -f docs/runtime-inferencia-cpu-metricas.md
./scripts/fetch-model.sh
make verify-runtime
grep -q 'IA_LIVRE_LOAD_S' runtime/src/main.rs
grep -q 'IA_LIVRE_TOKENS_PER_S' runtime/src/main.rs
```

`make verify-runtime` falha se o modelo estiver ausente ou se faltarem `IA_LIVRE_INFER_OK` / `IA_LIVRE_LOAD_S=` / `IA_LIVRE_TOKENS_PER_S=` (timeout padrão 300s; `VERIFY_RUNTIME_TIMEOUT`).

### Gate do runtime GPU (Etapa 8 — adicional)

Requer GGUF + GPU utilizável (ou skip explícito). **Não** usa QEMU/UEFI. Aceleração no **host** (ADR 0002).

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
# Se Vulkan: export VULKAN_SDK=… (glslc); SDK user-space ok
test -f scripts/verify-runtime-gpu.sh
test -f docs/runtime-inferencia-gpu-metricas.md
test -f docs/adr/0002-aceleracao-gpu-host-llama-cpp.md
./scripts/fetch-model.sh
make verify-runtime-gpu
grep -q 'IA_LIVRE_ACCEL' runtime/src/main.rs
grep -q 'n-gpu-layers' runtime/src/main.rs
```

Com GPU: build com feature (`cuda` se `nvcc` existir, senão `vulkan`; override `IA_LIVRE_GPU_FEATURE`), `--n-gpu-layers` > 0, exige `IA_LIVRE_INFER_OK` + métricas + `IA_LIVRE_ACCEL=` ≠ `cpu` (timeout `VERIFY_RUNTIME_GPU_TIMEOUT`, default 300s).

**Skip (CI / sem GPU):** `VERIFY_RUNTIME_GPU_SKIP=1` **ou** `nvidia-smi` indetectável → imprime `IA_LIVRE_GPU_SKIP` e exit **0** (não finge aceleração). Force Vulkan-only sem nvidia-smi: `VERIFY_RUNTIME_GPU_FORCE=1`. Gates CPU/kernel/node/agent permanecem.

### Gate do nó Rede IA Livre (Etapa 6 — adicional)

Só Rust no host. **Não** usa QEMU, GGUF nem o runtime de inferência. Participar da Rede **não exige** o SO IA Livre.

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
test -d node && test -f node/Cargo.toml && test -f node/src/main.rs
test -f scripts/verify-node.sh && test -f docs/rede-ia-livre-prototipo.md
make verify-node
grep -q 'IA_LIVRE_PEER_OK' node/src/main.rs
grep -q 'IA_LIVRE_MSG_OK' node/src/main.rs
```

`make verify-node` sobe dois processos (`--peer` no segundo), espera `IA_LIVRE_PEER_OK` e `IA_LIVRE_MSG_OK`, e falha no timeout (padrão 45s; `VERIFY_NODE_TIMEOUT`). Gates do kernel (`make verify`) e do runtime (`make verify-runtime`) permanecem.

### Gate do ambiente de autonomia (Etapa 7 — adicional)

Requer o GGUF local (`./scripts/fetch-model.sh` na primeira vez). **Não** usa QEMU/UEFI nem o nó P2P. O protótipo de autonomia **não exige** o SO IA Livre.

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
test -d agent && test -f agent/Cargo.toml && test -f agent/src/main.rs
test -f scripts/verify-agent.sh && test -f docs/ambiente-autonomia-prototipo.md
./scripts/fetch-model.sh
make verify-agent
grep -q 'IA_LIVRE_TOOL_OK' agent/src/main.rs
grep -q 'IA_LIVRE_MEMORY_OK' agent/src/main.rs
grep -q 'IA_LIVRE_AGENT_OK' agent/src/main.rs
```

`make verify-agent` falha se o modelo estiver ausente ou se faltarem `IA_LIVRE_TOOL_OK` / `IA_LIVRE_MEMORY_OK` / `IA_LIVRE_AGENT_OK` (timeout padrão 300s; `VERIFY_AGENT_TIMEOUT`). Gates do kernel, runtime e nó permanecem.

## PATH

Sempre inclua o GitHub CLI e o Cargo locais:

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
```

## Estrutura

- `ROADMAP.md` — etapas e status (fonte do próximo passo comprometido)
- `BACKLOG.md` — demandas ainda não promovidas (canônico; espelho GitHub best-effort, label `backlog`)
- `specs/` — Spec-Driven Development (spec → plan → tasks)
- `docs/` — produto, arquitetura e ADRs
- `memory-bank/` — contexto volátil entre chats (`activeContext.md`, `progress.md`)
- `.cursor/` — rules, agents, skills, commands, hooks
- `kernel/` — crate do kernel IA Livre (`Cargo.toml`, `src/main.rs`), target UEFI
- `runtime/` — protótipo de runtime de inferência (host, llama-cpp-2; CPU default + features `cuda`/`vulkan`)
- `node/` — protótipo do nó Rede IA Livre (host; independente do SO)
- `agent/` — protótipo do ambiente de autonomia (host; consome runtime; independente do SO)
- `models/` — pesos GGUF locais (gitignored); obter com `./scripts/fetch-model.sh`
- `Cargo.toml` — workspace Cargo (membros `kernel`, `runtime`, `node`, `agent`)
- `docs/rede-ia-livre-prototipo.md` — framing/descoberta/mensagem do protótipo P2P
- `docs/ambiente-autonomia-prototipo.md` — loop/memória/ferramenta do protótipo de autonomia
- `Makefile` — `build` / `esp` / `run` / `verify` / `verify-runtime` / `verify-runtime-gpu` / `verify-node` / `verify-agent` / `clean`
- `scripts/run-qemu.sh` — atalho para `make run`
- `scripts/verify-boot.sh` — gate serial `IA_LIVRE_BOOT_OK`
- `scripts/verify-runtime.sh` — gate do runtime CPU (`IA_LIVRE_INFER_OK` + métricas)
- `scripts/verify-runtime-gpu.sh` — gate GPU (`IA_LIVRE_ACCEL` ≠ `cpu`; skip `IA_LIVRE_GPU_SKIP`)
- `docs/runtime-inferencia-gpu-metricas.md` — métricas do protótipo GPU no host
- `docs/adr/0002-aceleracao-gpu-host-llama-cpp.md` — CUDA canônico / Vulkan alternativa
- `scripts/verify-node.sh` — gate do nó Rede IA Livre (`IA_LIVRE_PEER_OK` + `IA_LIVRE_MSG_OK`)
- `scripts/verify-agent.sh` — gate do ambiente de autonomia (`IA_LIVRE_TOOL_OK` + `IA_LIVRE_MEMORY_OK` + `IA_LIVRE_AGENT_OK`)
- `scripts/fetch-model.sh` — download do GGUF canônico da Etapa 5
- `docs/runtime-inferencia-cpu-metricas.md` — métricas do protótipo no host
- `build/esp/` — ESP gerada (gitignored via `build/`)

## Fora de escopo do agente

- Commitar segredos, `.env` ou chaves
- Force push, `--no-verify`, alterar config do git
- Abrir PR sem evidência do gate
- Implementar fora da etapa `em_andamento` do roadmap

## Ponte

- Rules: `.cursor/rules/` (README por fatia: `readme-por-fatia`)
- Roadmap: `ROADMAP.md`
- Backlog: `BACKLOG.md` (comando `/atualizar-backlog`; skill `atualizar-backlog`)
- Specs: `specs/`
- Product context: `docs/product-context.md`
- Memory Bank: `memory-bank/activeContext.md`
