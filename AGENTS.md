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
make verify   # gate automatizado do kernel (marcadores: ver docs/kernel-alem-do-boot.md)
```

Equivalente interativo: `./scripts/run-qemu.sh`.

Na serial: Etapa 10 (`BOOT_OK` … `ALLOC_OK`) + `IA_LIVRE_EXIT_BOOT_BEGIN`; após ExitBootServices (UART COM1): `EXIT_MAP_PAGES=` / `EXIT_MAP_OK` / `EXIT_MEM_OK` / `EXIT_BOOT_OK`; em seguida demo Etapa 19 (`TYPED_*` / `PHASE=` / `QUANTUM=` / `MEM_SCHED_OK` — ver [`docs/memoria-scheduler-impl-minima.md`](docs/memoria-scheduler-impl-minima.md)); depois proxy Linha B (`NATIVE_BENCH_*`).  
Contratos: [`docs/kernel-alem-do-boot.md`](docs/kernel-alem-do-boot.md), [`docs/kernel-pos-boot-services.md`](docs/kernel-pos-boot-services.md), [`docs/memoria-scheduler-impl-minima.md`](docs/memoria-scheduler-impl-minima.md). Ainda **sem** inferência / GGUF no kernel.

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

### Harness Linha A vs Linha B (Etapas 9 / 12 / 20 / 21)

Metodologia: [`docs/harness-linha-a-b.md`](docs/harness-linha-a-b.md); caminho B mínimo: [`docs/runtime-nativo-linha-b.md`](docs/runtime-nativo-linha-b.md); contrato: [`docs/runtime-contrato-nativo.md`](docs/runtime-contrato-nativo.md).  
**Não** confundir com métricas dos protótipos CPU/GPU. Linha A = host + GGUF; Linha B = proxy pós-ExitBoot no QEMU **+** evidência `MEM_SCHED` (E19) reemitida como `HARNESS_CONTRACT_*` (**não** TinyLlama).  
**Etapa 21:** deps 19/20 ok (`CONTRACT_READY=1`); carga GGUF real em B **bloqueada** (`B_BLOCK=no_gguf_path`, `GGUF_STATUS=blocked`, `GGUF_NATIVE_LOADER=absent`) — **sem** inventar `TOKENS_PER_S`. Spec: `specs/carga-gguf-linha-b/`. Hipótese **não** comprovada.

Pré-requisitos: runtime CPU (GGUF) para A; QEMU/OVMF para B. Sem GPU no harness v1.

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

./scripts/fetch-model.sh
cargo build -p ia-livre-runtime

# Linha A — emite IA_LIVRE_HARNESS_LINE=A + IA_LIVRE_HARNESS_OK + load/tokens
./scripts/run-harness-line-a.sh

# Linha B — QEMU proxy + HARNESS_CONTRACT_* + bloqueio GGUF honesto (não TinyLlama)
./scripts/run-harness-line-b.sh
```

Linha B: proxy E12 **preservado** (`LOAD_KIND=proxy`) + contrato E19 (`HARNESS_CONTRACT_*`, `CONTRACT_READY=1`) + alvos `GGUF_TARGET_*` + `B_BLOCK=no_gguf_path` / `GGUF_STATUS=blocked`.  
**Proibido** `TOKENS_PER_S` / `LOAD_KIND=gguf` / `MODEL=` TinyLlama sem carga real. Opcional: `IA_LIVRE_HARNESS_B_MODE=block-status` → `LOAD_KIND_GGUF=blocked`. Ver [`docs/runtime-nativo-linha-b.md`](docs/runtime-nativo-linha-b.md). Hipótese **não** comprovada.

Gate automatizado: `make verify-harness` (A = GGUF; B = proxy + contrato + bloqueio GGUF; requer GGUF para A).

### Contrato nativo — consumidor / shim host (Etapa 20)

Consumidor do contrato ADR 0003: (1) **shim host** — sem QEMU; (2) **harness B** observa serial E19. Doc: [`docs/runtime-contrato-nativo.md`](docs/runtime-contrato-nativo.md). Hipótese **não** comprovada; **proibido** `TOKENS_PER_S`. Shim host **≠** Linha B.

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
cargo build -p ia-livre-runtime-contract
cargo run -p ia-livre-runtime-contract
# Esperado: IA_LIVRE_CONTRACT_* + IA_LIVRE_RUNTIME_CONTRACT_OK
make verify-runtime-contract
# Evidência nativa: ./scripts/run-harness-line-b.sh (HARNESS_CONTRACT_*)
```

## Como verificar

### Gate do kernel (Etapas 4 / 10 / 11 / 12 / 19)

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
test -f README.md && test -f AGENTS.md && test -f ROADMAP.md
test -d kernel && test -f kernel/Cargo.toml && test -f kernel/src/main.rs
test -f Makefile && test -f Cargo.toml
test -f docs/kernel-alem-do-boot.md
test -f docs/kernel-pos-boot-services.md
test -f docs/memoria-scheduler-impl-minima.md
make build
test -f target/x86_64-unknown-uefi/debug/ia-livre-kernel.efi
make verify
grep -q 'IA_LIVRE_BOOT_OK' kernel/src/main.rs
grep -q 'IA_LIVRE_MEM_MAP_OK' kernel/src/main.rs
grep -q 'IA_LIVRE_ALLOC_OK' kernel/src/main.rs
grep -q 'IA_LIVRE_EXIT_BOOT_OK' kernel/src/main.rs
grep -q 'IA_LIVRE_MEM_SCHED_OK' kernel/src/main.rs
grep -q 'IA_LIVRE_TYPED_WEIGHTS_OK' kernel/src/main.rs
grep -q 'IA_LIVRE_NATIVE_BENCH_OK' kernel/src/main.rs
```

`make verify` falha se faltarem BOOT/MEM/ALLOC/EXIT_* / `MEM_SCHED_OK` (Etapa 19) / `NATIVE_BENCH_OK` (proxy Linha B). Timeout padrão 45s; `VERIFY_TIMEOUT`. Contratos: kernel-alem-do-boot, kernel-pos-boot-services, memoria-scheduler-impl-minima, runtime-nativo-linha-b.

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

### Gate do harness Linha A vs Linha B (Etapas 9 / 12 / 20 — adicional)

Requer GGUF local para A e QEMU/UEFI para B. **Não** prova a hipótese — A = carga canônica; B = proxy + evidência `MEM_SCHED` (sem `TOKENS_PER_S`).

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
test -f scripts/verify-harness.sh
test -f scripts/run-harness-line-a.sh
test -f scripts/run-harness-line-b.sh
test -f docs/harness-linha-a-b.md
test -f docs/runtime-nativo-linha-b.md
./scripts/fetch-model.sh
make verify-harness
grep -q 'IA_LIVRE_HARNESS_OK' scripts/run-harness-line-a.sh
grep -q 'post_exit_microbench' scripts/run-harness-line-b.sh
grep -q 'HARNESS_CONTRACT_BACKEND=native_qemu' scripts/run-harness-line-b.sh
```

`make verify-harness` exige A (`LINE=A`, `OK`, load/tokens) **e** B (`LINE=B`, `OK`, `PROXY=*`, `HARNESS_CONTRACT_MEM_SCHED=OK`, `CONTRACT_READY=1`, `GGUF_TARGET_*`, `GGUF_NATIVE_LOADER=absent`, `B_BLOCK=no_gguf_path` (ou legado), `GGUF_STATUS=blocked`, sem `TOKENS_PER_S` / sem `LOAD_S` / sem `B_SKIP` / sem `LOAD_KIND=gguf` fingido). Timeout padrão 300s; `VERIFY_HARNESS_TIMEOUT`. Gates existentes permanecem.

### Gate do contrato nativo host (Etapa 20 — adicional)

Só Rust no host. **Não** usa QEMU nem GGUF. Shim ≠ Linha B. Hipótese **não** comprovada. Evidência QEMU do contrato fica em `verify-harness` (B).

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
test -d runtime-contract && test -f runtime-contract/Cargo.toml && test -f runtime-contract/src/main.rs
test -f scripts/verify-runtime-contract.sh && test -f docs/runtime-contrato-nativo.md
make verify-runtime-contract
grep -q 'IA_LIVRE_RUNTIME_CONTRACT_OK' runtime-contract/src/main.rs
grep -q 'IA_LIVRE_CONTRACT_BACKEND' runtime-contract/src/main.rs
```

`make verify-runtime-contract` exige `CONTRACT_BACKEND=host_shim`, alloc Weights/KvCache, fases Prefill+Decode e `RUNTIME_CONTRACT_OK` (timeout padrão 30s; `VERIFY_RUNTIME_CONTRACT_TIMEOUT`). Gates existentes permanecem.

## PATH

Sempre inclua o GitHub CLI e o Cargo locais:

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
```

## Estrutura

- `ROADMAP.md` — etapas e status (fonte do próximo passo comprometido)
- `BACKLOG.md` — demandas ainda não promovidas (canônico; espelho GitHub best-effort, label `backlog`; promoção do topo **autônoma** quando o roadmap esvazia)
- `specs/` — Spec-Driven Development (spec → plan → tasks)
- `docs/` — produto, arquitetura e ADRs
- `memory-bank/` — contexto volátil entre chats (`activeContext.md`, `progress.md`)
- `.cursor/` — rules, agents, skills, commands, hooks
- `kernel/` — crate do kernel IA Livre (`Cargo.toml`, `src/main.rs`), target UEFI
- `docs/kernel-alem-do-boot.md` — contrato Etapa 10 (mapa UEFI + alloc/bump; marcadores serial)
- `docs/kernel-pos-boot-services.md` — contrato Etapa 11 (ExitBoot + UART COM1; marcadores `EXIT_*`)
- `docs/memoria-scheduler-impl-minima.md` — contrato Etapa 19 (allocator tipado Weights/KvCache + Prefill/Decode; `MEM_SCHED_OK`)
- `runtime/` — protótipo de runtime de inferência (host, llama-cpp-2; CPU default + features `cuda`/`vulkan`)
- `runtime-contract/` — shim host do contrato nativo Weights/KvCache + fases (Etapa 20; ≠ Linha B)
- `docs/runtime-contrato-nativo.md` — contrato consumidor + marcadores `CONTRACT_*` / `RUNTIME_CONTRACT_OK`
- `node/` — protótipo do nó Rede IA Livre (host; independente do SO)
- `agent/` — protótipo do ambiente de autonomia (host; consome runtime; independente do SO)
- `models/` — pesos GGUF locais (gitignored); obter com `./scripts/fetch-model.sh`
- `Cargo.toml` — workspace Cargo (membros `kernel`, `runtime`, `runtime-contract`, `node`, `agent`)
- `docs/rede-ia-livre-prototipo.md` — framing/descoberta/mensagem do protótipo P2P (Etapa 6)
- `docs/desenho-protocolo-rede-ia-livre.md` — desenho Rede IA Livre v1 (ADR 0004; não implementado)
- `docs/adr/0004-stack-protocolo-rede-ia-livre.md` — ADR da stack candidata P2P
- `docs/ambiente-autonomia-prototipo.md` — loop/memória/ferramenta do protótipo de autonomia (Etapa 7)
- `docs/desenho-autonomia-v1.md` — escopo autonomia v1 (ADR 0005; não implementado)
- `docs/adr/0005-autonomia-v1-utilizavel.md` — ADR do escopo v1
- `Makefile` — `build` / `esp` / `run` / `verify` / `verify-runtime` / `verify-runtime-gpu` / `verify-runtime-contract` / `verify-node` / `verify-agent` / `verify-harness` / `clean`
- `scripts/run-qemu.sh` — atalho para `make run`
- `scripts/verify-boot.sh` — gate serial do kernel (`BOOT_OK` + mem/alloc + `EXIT_BOOT_OK` + `MEM_SCHED_OK` + `NATIVE_BENCH_OK`)
- `scripts/verify-runtime.sh` — gate do runtime CPU (`IA_LIVRE_INFER_OK` + métricas)
- `scripts/verify-runtime-gpu.sh` — gate GPU (`IA_LIVRE_ACCEL` ≠ `cpu`; skip `IA_LIVRE_GPU_SKIP`)
- `scripts/verify-runtime-contract.sh` — gate shim host do contrato nativo (`RUNTIME_CONTRACT_OK`)
- `docs/runtime-inferencia-gpu-metricas.md` — métricas do protótipo GPU no host
- `docs/adr/0002-aceleracao-gpu-host-llama-cpp.md` — CUDA canônico / Vulkan alternativa
- `scripts/verify-node.sh` — gate do nó Rede IA Livre (`IA_LIVRE_PEER_OK` + `IA_LIVRE_MSG_OK`)
- `scripts/verify-agent.sh` — gate do ambiente de autonomia (`IA_LIVRE_TOOL_OK` + `IA_LIVRE_MEMORY_OK` + `IA_LIVRE_AGENT_OK`)
- `scripts/fetch-model.sh` — download do GGUF canônico da Etapa 5
- `docs/runtime-inferencia-cpu-metricas.md` — métricas do protótipo no host
- `docs/harness-linha-a-b.md` — metodologia do harness Linha A vs Linha B
- `docs/harness-perfis-a-otimizada-gpu.md` — perfis A otimizada / GPU (Etapa 18; gate permanece `verify-harness`)
- `docs/runtime-nativo-linha-b.md` — contrato Linha B mínima (proxy pós-ExitBoot)
- `docs/desenho-memoria-scheduler-nativo.md` — desenho candidato Weights/KvCache + Prefill/Decode (ADR 0003)
- `docs/adr/0003-memoria-model-aware-e-scheduler-fases.md` — ADR do desenho; impl. mínima = Etapa 19
- `docs/desenho-gpu-manager-multi-gpu.md` — desenho GPU manager / multi-GPU (ADR 0006; não implementado)
- `docs/adr/0006-gpu-manager-multi-gpu.md` — ADR do escopo candidato (host ≠ nativo)
- `LICENSE` / `NOTICE` — Apache-2.0 (1ª parte); ADR [`0007`](docs/adr/0007-licencas-por-componente.md)
- `docs/licencas-terceiros.md` — aviso de deps (llama.cpp, uefi, …)
- `scripts/run-harness-line-a.sh` — corrida Linha A (wrapper do runtime, marcadores `HARNESS_`)
- `scripts/run-harness-line-b.sh` — Linha B via QEMU (proxy + `HARNESS_CONTRACT_*`; `HARNESS_OK`)
- `scripts/verify-harness.sh` — gate A (GGUF) + B (proxy QEMU + evidência MEM_SCHED)

- `build/esp/` — ESP gerada (gitignored via `build/`)

## Fora de escopo do agente

- Commitar segredos, `.env` ou chaves
- Force push, `--no-verify`, alterar config do git
- Abrir PR sem evidência do gate
- Implementar fora da etapa `em_andamento` do roadmap

## Ponte

- Rules: `.cursor/rules/` (README por fatia: `readme-por-fatia`; paralelo: `agentes-em-paralelo`)
- Lease multi-agente: `memory-bank/AGENT_CLAIM.md` (obrigatório antes de editar `em_andamento`)
- Roadmap: `ROADMAP.md`
- Backlog: `BACKLOG.md` (comando `/atualizar-backlog`; skill `atualizar-backlog`)
- Specs: `specs/`
- Product context: `docs/product-context.md`
- Memory Bank: `memory-bank/activeContext.md`
