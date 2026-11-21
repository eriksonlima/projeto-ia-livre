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

Na serial: Etapa 10 (`BOOT_OK` … `ALLOC_OK`) + loader Etapas 26/27 (`GGUF_LOADER_*` / `GGUF_MAGIC_OK` / `GGUF_NATIVE_LOADER=blockio_full` / `GGUF_TENSORS_STUB_OK`) + obs Etapa 37 (`GOP_OK`/`INPUT_OK`/`OBS_OK`, ver [`docs/observabilidade-minima-so.md`](docs/observabilidade-minima-so.md)) + `IA_LIVRE_EXIT_BOOT_BEGIN`; após ExitBootServices (UART COM1): `EXIT_*` + reemissão GGUF + demo Etapa 19 (`TYPED_*` / `PHASE=` / `MEM_SCHED_OK`) + GPU manager nativo Etapa 38 (`GPU_MGR=native` / `GPU_MGR_OK`) + proxy Linha B (`NATIVE_BENCH_*`).  
Contratos: kernel-alem-do-boot, kernel-pos-boot-services, memoria-scheduler-impl-minima, runtime-nativo-linha-b (BlockIO + Prefill/Decode subset). Geração guest: `TOKENS_PER_S` medidos (`LOAD_KIND=gguf`; espécie ainda subset).

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

### Nó Rede IA Livre (host — Etapas 6 / 23 / 39 / 50)

Nó da **camada 4** no host Linux (`std`) — protocolo **v1** (Etapa 23) + descoberta WAN (bootstrap Etapa 39 + mDNS Etapa 50). **Não** precisa do kernel UEFI, QEMU, GGUF nem do runtime de inferência. Participar da Rede **não exige** o SO IA Livre (ADR 0001).

Contrato v1: [`docs/rede-ia-livre-v1.md`](docs/rede-ia-livre-v1.md) · descoberta: [`docs/rede-descoberta-wan.md`](docs/rede-descoberta-wan.md) (histórico E6: [`docs/rede-ia-livre-prototipo.md`](docs/rede-ia-livre-prototipo.md)).

Pré-requisito: só Rust no host (target nativo). Chaves ed25519 em `build/node-keys/` (gitignored) ou `--key-file`.

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

cargo build -p ia-livre-node

# Terminal A:
cargo run -p ia-livre-node -- --tcp-port 7400 --node-id alice

# Terminal B — regressão (--peer) ou bootstrap (Etapa 39, sem --peer):
cargo run -p ia-livre-node -- --tcp-port 7401 --node-id bob --peer 127.0.0.1:7400
cargo run -p ia-livre-node -- --tcp-port 7401 --node-id bob --bootstrap 127.0.0.1:7400

# mDNS (Etapa 50) — dois terminais, sem --peer / sem --bootstrap:
cargo run -p ia-livre-node -- --tcp-port 7400 --node-id alice --disc-mdns
cargo run -p ia-livre-node -- --tcp-port 7401 --node-id bob --disc-mdns
```

Esperado: `IA_LIVRE_PROTO=v1`, `IA_LIVRE_PEER_ID=…`, `IA_LIVRE_IDENT_OK`, `IA_LIVRE_PEER_OK`, `IA_LIVRE_MSG_OK`, `IA_LIVRE_PING_OK`, `IA_LIVRE_TASK_OK`; com bootstrap: `IA_LIVRE_DISC_MODE=bootstrap` + `IA_LIVRE_DISC_OK`; com mDNS: `IA_LIVRE_DISC_MODE=mdns` + `IA_LIVRE_DISC_OK`.  
`--node-id` é apelido; a âncora de confiança é o PeerId ed25519. Precedência dial: `--peer` > bootstrap > mdns. `TASK`/`TASK_ACK` = Etapa 51 (além de PING).

Gate automatizado: `make verify-node` (peer + bootstrap + `TASK_OK`; mDNS skip default; não exige QEMU, GGUF nem runtime).

### Ambiente de autonomia (host — Etapas 7 / 24)

Camada 3 no host Linux (`std`). **Não** precisa do kernel UEFI / QEMU. Consome o runtime CPU existente (`ia-livre-runtime`) e o GGUF canônico. Autonomia **não exige** o SO IA Livre (ADR 0001).

- Protótipo E7: [`docs/ambiente-autonomia-prototipo.md`](docs/ambiente-autonomia-prototipo.md)
- Autonomia v1 (Etapa 24): [`docs/desenho-autonomia-v1.md`](docs/desenho-autonomia-v1.md) / ADR [`0005`](docs/adr/0005-autonomia-v1-utilizavel.md) — `--prompt`, allowlist `note`/`recall`/`help`, política N=8

Pré-requisitos: Rust no host + deps/modelo do runtime (ver seção Runtime acima). **Sem** QEMU/OVMF para o agente.

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

# Modelo (se ainda não baixado)
./scripts/fetch-model.sh

# Build do runtime (consumido via subprocesso) + agente
cargo build -p ia-livre-runtime -p ia-livre-agent

# Cenário de prova (sem --prompt): runtime → note+recall+help → marcadores E7/v1
cargo run -p ia-livre-agent -- \
  --model models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
  --memory build/agent-memory/memory.jsonl

# One-shot com prompt do usuário (v1)
cargo run -p ia-livre-agent -- \
  --model models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
  --memory build/agent-memory/memory.jsonl \
  --prompt "Resuma as notas recentes"
```

Flags: `--model` (default GGUF canônico), `--memory` (default `build/agent-memory/memory.jsonl`), `--n-predict` (default `16`), `--runtime-bin` (opcional), `--prompt` (one-shot v1; omitido = prova E7/v1).

Saída esperada: `IA_LIVRE_RUNTIME_USED=1`, `IA_LIVRE_MEMORY_POLICY_OK`, `IA_LIVRE_TOOLS_USED=` ≥2, `IA_LIVRE_TOOL_OK`, `IA_LIVRE_MEMORY_OK`, `IA_LIVRE_AGENT_OK`.

Gate automatizado: `make verify-agent` (não exige QEMU/UEFI nem o nó P2P; requer GGUF).

### Harness Linha A vs Linha B (Etapas 9 / 12 / 20 / 21)

Metodologia: [`docs/harness-linha-a-b.md`](docs/harness-linha-a-b.md); caminho B mínimo: [`docs/runtime-nativo-linha-b.md`](docs/runtime-nativo-linha-b.md); contrato: [`docs/runtime-contrato-nativo.md`](docs/runtime-contrato-nativo.md).  
**Não** confundir com métricas dos protótipos CPU/GPU. Linha A = host + GGUF; Linha B = proxy pós-ExitBoot no QEMU **+** evidência `MEM_SCHED` (E19) reemitida como `HARNESS_CONTRACT_*` (**não** TinyLlama).  
**Etapa 21:** deps 19/20 ok (`CONTRACT_READY=1`); bloqueio histórico `no_gguf_path`.  
**Etapa 26–44:** loader BlockIO + `runtime-native` (Prefill subset → Decode/`TOKENS_PER_S` medidos; espécie ≠ 22L×32). ADR [`0014`](docs/adr/0014-prefill-22l-kv-linha-b.md) / [`0015`](docs/adr/0015-decode-tokens-linha-b.md). Hipótese **não** comprovada (comparable INCONCLUSIVO).

Pré-requisitos: runtime CPU (GGUF) para A; QEMU/OVMF para B. Sem GPU no harness v1.

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

./scripts/fetch-model.sh
cargo build -p ia-livre-runtime

# Linha A — emite IA_LIVRE_HARNESS_LINE=A + IA_LIVRE_HARNESS_OK + load/tokens
./scripts/run-harness-line-a.sh

# Linha A otimizada (Etapa 34; opt-in) — PROFILE=A_otimizada + threads/governor/taskset
./scripts/run-harness-line-a-optimized.sh
# Gate: make verify-harness-a-otimizada

# Linha B — QEMU proxy + HARNESS_CONTRACT_* + bloqueio GGUF honesto (não TinyLlama)
./scripts/run-harness-line-b.sh
```

Linha B: microbench E12 (`PROXY=*`) + geração nativa subset (`LOAD_KIND=gguf` + `TOKENS_PER_S` medidos).  
Ver [`docs/runtime-nativo-linha-b.md`](docs/runtime-nativo-linha-b.md). Hipótese **não** comprovada (espécie subset).

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

### Harness A vs B comparável (Etapas 22 / 28)

Metodologia + veredito: [`docs/harness-a-b-comparavel.md`](docs/harness-a-b-comparavel.md).  
Protocolo serial (sem contenção): [`docs/harness-corrida-quieta.md`](docs/harness-corrida-quieta.md) — um gate por vez; preflight aviso; `IA_LIVRE_HARNESS_QUIET_STRICT=1` / `QUIET_FORCE=1`.  
Corrida agregada A+B com `IA_LIVRE_HARNESS_VERDICT=` ∈ {`COMPROVA`,`REFUTA`,`INCONCLUSIVO`}. Com geração B subset → **`INCONCLUSIVO`** (`E44_subset_generate_not_canonical_species_*`). `COMPROVA`/`REFUTA` só com espécie canônica (22L + n_predict=32).

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

./scripts/fetch-model.sh
cargo build -p ia-livre-runtime

./scripts/run-harness-a-b-comparable.sh
# Gate:
make verify-harness-comparable
```

Override opcional quando B15 existir: `IA_LIVRE_HARNESS_B_SCRIPT=/caminho/para/entrypoint-b-gguf`.  
Timeout: `VERIFY_HARNESS_COMPARABLE_TIMEOUT` (default = `VERIFY_HARNESS_TIMEOUT`, 300s).

## Como verificar

### Gate do kernel (Etapas 4 / 10 / 11 / 12 / 19 / 37 / 38)

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
test -f README.md && test -f AGENTS.md && test -f ROADMAP.md
test -d kernel && test -f kernel/Cargo.toml && test -f kernel/src/main.rs
test -f Makefile && test -f Cargo.toml
test -f docs/kernel-alem-do-boot.md
test -f docs/kernel-pos-boot-services.md
test -f docs/memoria-scheduler-impl-minima.md
test -f docs/observabilidade-minima-so.md
test -f docs/gpu-manager-nativo.md
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
grep -q 'IA_LIVRE_OBS_OK' kernel/src/obs.rs
grep -q 'IA_LIVRE_GOP_OK' kernel/src/obs.rs
grep -q 'IA_LIVRE_OBS_OK' scripts/verify-boot.sh
grep -q 'IA_LIVRE_GPU_MGR=native' kernel/src/gpu_mgr.rs
grep -q 'IA_LIVRE_GPU_MGR_OK' kernel/src/gpu_mgr.rs
grep -q 'IA_LIVRE_GPU_MGR=native' scripts/verify-boot.sh
```

`make verify` falha se faltarem BOOT/MEM/ALLOC/`OBS_OK` (Etapa 37; `OBS_MODE=gop|input` alinhado a `GOP_OK`/`INPUT_OK`) / EXIT_* / `GGUF_MAGIC_OK` + `GGUF_NATIVE_LOADER=blockio_full` / `RUNTIME_NATIVE_LAYOUT_OK` (Etapa 29) / `MEM_SCHED_OK` (Etapa 19) / `GPU_MGR=native` + `GPU_MGR_OK` (Etapa 38) / `NATIVE_BENCH_OK` (proxy Linha B). Timeout padrão 300s com GGUF (`VERIFY_TIMEOUT`). Stub host E25 permanece em `make verify-gpu-manager` (`GPU_MGR=host_stub`).

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

### Gate do GPU manager stub host (Etapa 25 — adicional)

Stub **host** (ADR 0006 / B19) — enum + placement hint + shard documentado. **Não** é manager nativo nem prova A vs B. **Não** usa QEMU/UEFI nem GGUF. Contrato: [`docs/gpu-manager-prototipo-host.md`](docs/gpu-manager-prototipo-host.md). Etapa 8 (`verify-runtime-gpu`) permanece intacta.

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
test -f scripts/gpu-manager-stub.sh && test -f scripts/verify-gpu-manager.sh
test -f docs/gpu-manager-prototipo-host.md
./scripts/gpu-manager-stub.sh   # emite IA_LIVRE_GPU_MGR=host_stub + DEVICES/PLACE_HINT/SHARD_DOC
make verify-gpu-manager
grep -q 'IA_LIVRE_GPU_MGR=host_stub' scripts/gpu-manager-stub.sh
```

Com GPU detectável: exige `IA_LIVRE_GPU_MGR=host_stub`, `IA_LIVRE_GPU_DEVICES=` ≥ 1, placement/shard doc, `IA_LIVRE_GPU_MGR_OK`.

**Skip (CI / sem GPU):** `VERIFY_GPU_MANAGER_SKIP=1` **ou** `nvidia-smi` indetectável → imprime `IA_LIVRE_GPU_MGR_SKIP` e exit **0** (não finge multi-GPU). Force: `VERIFY_GPU_MANAGER_FORCE=1`.

### Gate do shard multi-GPU host (Etapa 41 — adicional)

Executor **host** `host_shard_exec` (além do stub E25). **Não** é manager nativo (E38). **Não** inventa `TOKENS_PER_S`. Contrato: [`docs/shard-multi-gpu-host.md`](docs/shard-multi-gpu-host.md).

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
test -f scripts/run-gpu-shard-host.sh && test -f scripts/verify-gpu-shard-host.sh
test -f docs/shard-multi-gpu-host.md
./scripts/run-gpu-shard-host.sh
make verify-gpu-shard-host
grep -q 'host_shard_exec' scripts/run-gpu-shard-host.sh
```

Com ≥2 GPUs: `IA_LIVRE_GPU_SHARD_EXEC_OK` + plano `0:0-10,1:11-21`.  
Com &lt;2 GPUs / CI: `IA_LIVRE_GPU_SHARD_SKIP` (ex. `need_2_devices`) exit **0** — **sem** `EXEC_OK`. Force skip: `VERIFY_GPU_SHARD_SKIP=1`.

### Gate do nó Rede IA Livre (Etapas 6 / 23 / 39 / 50 — adicional)

Só Rust no host. **Não** usa QEMU, GGUF nem o runtime de inferência. Participar da Rede **não exige** o SO IA Livre. Gate: regressão `--peer` + estágio `--bootstrap` (`DISC_OK`) + mDNS opt-in (Etapa 50).

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
test -d node && test -f node/Cargo.toml && test -f node/src/main.rs
test -f scripts/verify-node.sh && test -f docs/rede-ia-livre-v1.md
test -f docs/rede-descoberta-wan.md
test -f node/src/mdns.rs
make verify-node
grep -q 'IA_LIVRE_PEER_OK' node/src/session.rs
grep -q 'IA_LIVRE_MSG_OK' node/src/session.rs
grep -q 'IA_LIVRE_IDENT_OK' node/src/session.rs
grep -q 'IA_LIVRE_PING_OK' node/src/session.rs
grep -q 'IA_LIVRE_TASK_OK' node/src/session.rs
grep -q 'IA_LIVRE_DISC_OK' node/src/main.rs
grep -q 'IA_LIVRE_DISC_MODE=bootstrap' scripts/verify-node.sh
grep -q '_ia-livre._tcp' node/src/mdns.rs
! grep -qi 'libp2p' node/Cargo.toml
```

`make verify-node` roda estágio peer **e** bootstrap (B sem `--peer`); exige v1 + `TASK_OK` + `IA_LIVRE_DISC_OK` no bootstrap. Timeout por estágio: `VERIFY_NODE_TIMEOUT` (default 45s).  
mDNS: `VERIFY_NODE_MDNS_SKIP=1` (default) → `IA_LIVRE_DISC_MDNS_SKIP=…`. Prova: `VERIFY_NODE_MDNS_SKIP=0 make verify-node` (exige `DISC_MODE=mdns` + `DISC_OK`); se multicast falhar sem `VERIFY_NODE_MDNS_FORCE=1`, skip honesto. Gates do kernel/runtime permanecem.

### Gate do ambiente de autonomia (Etapas 7 / 24 / 40 — adicional)

Requer o GGUF local (`./scripts/fetch-model.sh` na primeira vez). **Não** usa QEMU/UEFI nem o nó P2P. Autonomia **não exige** o SO IA Livre.

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
test -d agent && test -f agent/Cargo.toml && test -f agent/src/main.rs
test -f scripts/verify-agent.sh && test -f docs/ambiente-autonomia-prototipo.md
test -f docs/desenho-autonomia-v1.md
test -f docs/autonomia-alem-v1.md
./scripts/fetch-model.sh
make verify-agent
grep -q 'IA_LIVRE_TOOL_OK' agent/src/main.rs
grep -q 'IA_LIVRE_MEMORY_OK' agent/src/main.rs
grep -q 'IA_LIVRE_AGENT_OK' agent/src/main.rs
grep -q 'IA_LIVRE_MEMORY_POLICY_OK' agent/src/main.rs
grep -q 'IA_LIVRE_TOOLS_USED' agent/src/main.rs
grep -q 'IA_LIVRE_TOOL_SANDBOX_OK' agent/src/main.rs
grep -q 'IA_LIVRE_TOOL=calc' agent/src/main.rs
grep -q 'IA_LIVRE_REPL_OK' agent/src/repl.rs
test -f docs/autonomia-repl.md
test -f agent/fixtures/repl-smoke.txt
```

`make verify-agent` falha se o modelo estiver ausente ou se faltarem marcadores E7 (`TOOL_OK` / `MEMORY_OK` / `AGENT_OK`) **ou** v1 (`MEMORY_POLICY_OK` + `TOOLS_USED`≥2 + `TOOL=note` e `TOOL=recall|help`) **ou** E40 (`TOOL=calc` + `TOOL_SANDBOX_OK` + `CALC_RESULT=7`) **ou** E53 (`REPL_MODE=scripted` + `REPL_OK`) (timeout padrão 300s; `VERIFY_AGENT_TIMEOUT`). Gates do kernel, runtime e nó permanecem.

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

`make verify-harness` exige A (`LINE=A`, `OK`, load/tokens) **e** B (`LINE=B`, `OK`, `PROXY=*`, Decode/sampling, `LOAD_KIND=gguf`, `TOKENS_PER_S` medidos). Timeout padrão 600s; `VERIFY_HARNESS_TIMEOUT`. Default kernel `IA_LIVRE_KERNEL_PROFILE=release`.

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

### Gate do harness A vs B comparável (Etapa 22 — adicional)

Requer GGUF para A e QEMU para B (proxy até B15). Emite veredito; **aceita** `INCONCLUSIVO` com B proxy. **Não** prova a hipótese sem GGUF comparável em B.

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
test -f scripts/verify-harness-comparable.sh
test -f scripts/run-harness-a-b-comparable.sh
test -f docs/harness-a-b-comparavel.md
./scripts/fetch-model.sh
make verify-harness-comparable
grep -q 'IA_LIVRE_HARNESS_VERDICT' scripts/run-harness-a-b-comparable.sh
grep -q 'VERDICT_REASON' scripts/run-harness-a-b-comparable.sh
```

`make verify-harness-comparable` exige `VERDICT=` ∈ {COMPROVA, REFUTA, INCONCLUSIVO} + `VERDICT_REASON=`; falha se `COMPROVA`/`REFUTA` com B proxy ou se o runner exit ≠ 0 (fraude/timeout). Timeout: `VERIFY_HARNESS_COMPARABLE_TIMEOUT` (default 300s). `make verify-harness` (v1) permanece. Perfil A otimizada: `make verify-harness-a-otimizada` (opt-in; não substitui o gate v1).

### Gate da imagem ESP/USB (Etapa 30 — adicional)

Valida o **artefato** bare-metal (`build/baremetal-esp/` + tar). **Não** é boot em PC físico e **não** substitui `make verify` (QEMU). Contrato: [`docs/boot-hardware-real.md`](docs/boot-hardware-real.md) / ADR [`0011`](docs/adr/0011-boot-imagem-esp-baremetal.md).

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
make baremetal-esp
make verify-baremetal
grep -q 'IA_LIVRE_BAREMETAL_IMAGE_OK' scripts/verify-baremetal.sh
```

Esperado: `IA_LIVRE_BAREMETAL_IMAGE_OK` + `EFI_SHA256=` / `EFI_BYTES=`. Default `IA_LIVRE_BAREMETAL_SKIP=1` (hardware não exercitado). Imagem FAT `.img` só se `mtools` estiver instalado.

**GGUF completo na ESP (Etapa 36):** opt-in `IA_LIVRE_BAREMETAL_FULL_GGUF=1` (após `./scripts/fetch-model.sh`) → `IA_LIVRE/model.gguf` + `IA_LIVRE_BAREMETAL_GGUF_OK`. Contrato: [`docs/gguf-baremetal-midia.md`](docs/gguf-baremetal-midia.md). Default do gate **não** exige o ~638 MiB.

**Metal (Etapa 35):** com log real em PC, `IA_LIVRE_BAREMETAL_SKIP=0 IA_LIVRE_BAREMETAL_EVIDENCE=docs/evidence/boot-metal/….txt make verify-baremetal` → `IA_LIVRE_BAREMETAL_METAL_OK` (≥ `BOOT_OK`, sem QEMU/OVMF no log). Formato: [`docs/boot-hardware-real.md`](docs/boot-hardware-real.md) / [`docs/evidence/boot-metal/`](docs/evidence/boot-metal/).

### Gate gravar pendrive UEFI (Etapa 47 — adicional)

Writer seguro (`scripts/write-usb-esp.sh`): confirmação explícita do device; **não** exige USB no CI; **não** é `METAL_OK`.

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
test -f scripts/write-usb-esp.sh && test -f scripts/verify-write-usb.sh
make verify-write-usb
grep -q 'IA_LIVRE_WRITE_USB_OK' scripts/verify-write-usb.sh
```

Gravação real (operador): `make baremetal-esp` → `./scripts/write-usb-esp.sh --list` → `--device /dev/sdX --confirm /dev/sdX --yes`. Contrato: [`docs/boot-hardware-real.md`](docs/boot-hardware-real.md).

### Gate inferência path metal / ESP-only (Etapa 48 — adicional)

QEMU **sem** BlockIO: prova `GGUF_PATH=esp_sfs` + `B_BLOCK_METAL=no_gguf_metal_io` (ADR [`0017`](docs/adr/0017-path-metal-sfs-vs-blockio.md)). **≠** `METAL_OK`; **≠** geração BlockIO.

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
make verify-metal-infer
grep -q 'IA_LIVRE_B_BLOCK_METAL=no_gguf_metal_io' scripts/verify-metal-infer.sh
```

### Gate bridge host↔nativo (Etapa 49 — adicional)

Bridge no **host** valida evidência serial/log nativo (`blockio` / `metal_block`). **Não** é agente no guest. **Não** substitui `make verify-agent` (ADR 0001). Contrato: [`docs/autonomia-bridge-nativo.md`](docs/autonomia-bridge-nativo.md) / ADR [`0018`](docs/adr/0018-autonomia-bridge-host-nativo.md).

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
test -f scripts/verify-autonomia-bridge.sh
test -f docs/autonomia-bridge-nativo.md
make verify-autonomia-bridge
grep -q 'IA_LIVRE_BRIDGE_OK' scripts/run-autonomia-bridge.sh
grep -q 'IA_LIVRE_BRIDGE_NATIVE_SRC' scripts/run-autonomia-bridge.sh
```

Esperado: `IA_LIVRE_BRIDGE_MODE=host_native` + `BRIDGE_NATIVE_SRC=metal_block|blockio` + `BRIDGE_OK` (metal via `verify-metal-infer`; blockio via fixture/log). Sem `METAL_OK` / `TOKENS_PER_S` inventados. `verify-agent` permanece independente.

### Gate bridge Rede UEFI↔host (Etapa 52 — adicional)

Bridge **Rede** (≠ autonomia E49): evidência pós-Exit + âncora `ia-livre-node` (`TASK_OK`). **Não** é TCP no guest. **Não** substitui `make verify-node` (ADR 0001). Contrato: [`docs/rede-bridge-nativo.md`](docs/rede-bridge-nativo.md) / ADR [`0019`](docs/adr/0019-rede-bridge-uefi-host.md).

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
test -f scripts/verify-rede-bridge.sh
test -f docs/rede-bridge-nativo.md
make verify-rede-bridge
grep -q 'IA_LIVRE_NET_BRIDGE_OK' scripts/run-rede-bridge.sh
```

Esperado: `NET_BRIDGE_MODE=host_uefi` + `NATIVE_SRC=serial_exit` + `NET_BRIDGE_OK`. Sem `NET_NATIVE_OK` fingido. `verify-node` permanece independente do SO.

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
- `docs/glossario.md` — termos estáveis (Linha A/B, B_BLOCK, bare-metal, GPU_MGR, veredito)
- `scripts/verify-docs-consistency.sh` — gate documental (`make verify-docs-consistency` → `IA_LIVRE_CONSISTENCY_OK`)
- `memory-bank/` — contexto volátil entre chats (`activeContext.md`, `progress.md`)
- `.cursor/` — rules, agents, skills, commands, hooks
- `kernel/` — crate do kernel IA Livre (`Cargo.toml`, `src/main.rs`), target UEFI
- `docs/kernel-alem-do-boot.md` — contrato Etapa 10 (mapa UEFI + alloc/bump; marcadores serial)
- `docs/kernel-pos-boot-services.md` — contrato Etapa 11 (ExitBoot + UART COM1; marcadores `EXIT_*`)
- `docs/observabilidade-minima-so.md` — contrato Etapa 37 (GOP/input mínimo; `GOP_OK`/`OBS_OK`; sem desktop)
- `docs/gpu-manager-nativo.md` — contrato Etapa 38 (`GPU_MGR=native`; enum/afinidade/placement; ≠ stub host)
- `docs/memoria-scheduler-impl-minima.md` — contrato Etapa 19 (allocator tipado Weights/KvCache + Prefill/Decode; `MEM_SCHED_OK`)
- `runtime/` — protótipo de runtime de inferência (host, llama-cpp-2; CPU default + features `cuda`/`vulkan`)
- `runtime-contract/` — shim host do contrato nativo Weights/KvCache + fases (Etapa 20; ≠ Linha B)
- `docs/runtime-contrato-nativo.md` — contrato consumidor + marcadores `CONTRACT_*` / `RUNTIME_CONTRACT_OK`
- `node/` — nó Rede IA Livre v1 (host; ed25519/PeerId; independente do SO)
- `agent/` — autonomia v1+E40 (host; `--prompt`, allowlist note/recall/help/`calc`, política N=8; consome runtime; independente do SO)
- `docs/autonomia-alem-v1.md` — contrato tool sandboxed `calc` (Etapa 40)
- `docs/autonomia-bridge-nativo.md` — bridge host↔nativo (Etapa 49; `BRIDGE_*`; ≠ verify-agent SO)
- `scripts/run-autonomia-bridge.sh` / `scripts/verify-autonomia-bridge.sh` — bridge + gate Etapa 49
- `models/` — pesos GGUF locais (gitignored); obter com `./scripts/fetch-model.sh`
- `runtime-native/` — runtime freestanding Linha B (Etapa 29; layout GGUF; forward futuro; ≠ host `runtime/`)
- `Cargo.toml` — workspace Cargo (membros `kernel`, `runtime`, `runtime-contract`, `runtime-native`, `node`, `agent`)
- `docs/rede-ia-livre-v1.md` — contrato protocolo Rede IA Livre v1 (Etapa 23)
- `docs/rede-ia-livre-prototipo.md` — histórico do protótipo P2P (Etapa 6)
- `docs/desenho-protocolo-rede-ia-livre.md` — desenho Rede IA Livre v1 (ADR 0004; checklist mínimo implementado na E23)
- `docs/adr/0004-stack-protocolo-rede-ia-livre.md` — ADR da stack candidata P2P
- `docs/ambiente-autonomia-prototipo.md` — loop/memória/ferramenta do protótipo de autonomia (Etapa 7); ponte para v1
- `docs/desenho-autonomia-v1.md` — escopo autonomia v1 (ADR 0005; **implementado** na Etapa 24 em `agent/`)
- `docs/adr/0005-autonomia-v1-utilizavel.md` — ADR do escopo v1
- `docs/boot-hardware-real.md` — ESP/USB + gate de artefato (Etapa 30; QEMU ≠ metal) + writer Etapa 47
- `Makefile` — `build` / `esp` / `baremetal-esp` / `run` / `verify` / `verify-baremetal` / `verify-write-usb` / …
- `scripts/make-baremetal-esp.sh` / `scripts/verify-baremetal.sh` — artefato + gate Etapa 30
- `scripts/write-usb-esp.sh` / `scripts/verify-write-usb.sh` — gravar pendrive com confirmação (Etapa 47)
- `scripts/run-qemu.sh` — atalho para `make run`
- `scripts/verify-boot.sh` — gate serial do kernel (`BOOT_OK` + mem/alloc + `EXIT_BOOT_OK` + `MEM_SCHED_OK` + `NATIVE_BENCH_OK`)
- `scripts/verify-runtime.sh` — gate do runtime CPU (`IA_LIVRE_INFER_OK` + métricas)
- `scripts/verify-runtime-gpu.sh` — gate GPU (`IA_LIVRE_ACCEL` ≠ `cpu`; skip `IA_LIVRE_GPU_SKIP`)
- `scripts/verify-runtime-contract.sh` — gate shim host do contrato nativo (`RUNTIME_CONTRACT_OK`)
- `scripts/gpu-manager-stub.sh` — stub host GPU manager (Etapa 25; `IA_LIVRE_GPU_MGR=host_stub`)
- `scripts/verify-gpu-manager.sh` — gate do stub (`IA_LIVRE_GPU_MGR_OK`; skip `IA_LIVRE_GPU_MGR_SKIP`)
- `scripts/run-gpu-shard-host.sh` / `scripts/verify-gpu-shard-host.sh` — shard host E41 (`host_shard_exec`; `EXEC_OK` ou `SHARD_SKIP`)
- `docs/shard-multi-gpu-host.md` — contrato shard multi-GPU host executado
- `docs/gpu-manager-prototipo-host.md` — contrato do stub host (≠ nativo; ≠ prova A vs B)
- `docs/runtime-inferencia-gpu-metricas.md` — métricas do protótipo GPU no host
- `docs/adr/0002-aceleracao-gpu-host-llama-cpp.md` — CUDA canônico / Vulkan alternativa
- `scripts/verify-node.sh` — gate do nó (v1 + bootstrap E39 + mDNS E50 opt-in: `PEER_OK`/`MSG_OK`/`IDENT_OK`/`PING_OK` + `DISC_OK`)
- `node/src/mdns.rs` — anúncio/resolução `_ia-livre._tcp` (Etapa 50; `mdns-sd`)
- `docs/rede-descoberta-wan.md` — contrato descoberta WAN (bootstrap E39 / mDNS E50)
- `scripts/verify-agent.sh` — gate autonomia E7+v1+E40 (`TOOL_OK` / `MEMORY_OK` / `AGENT_OK` + `MEMORY_POLICY_OK` + ≥2 tools + `calc`/`TOOL_SANDBOX_OK`)
- `scripts/fetch-model.sh` — download do GGUF canônico da Etapa 5
- `docs/runtime-inferencia-cpu-metricas.md` — métricas do protótipo no host
- `docs/harness-linha-a-b.md` — metodologia do harness Linha A vs Linha B
- `docs/harness-a-b-comparavel.md` — veredito COMPROVA/REFUTA/INCONCLUSIVO (Etapa 22)
- `docs/harness-perfis-a-otimizada-gpu.md` — perfis A otimizada / GPU (Etapa 18; gate permanece `verify-harness`)
- `docs/runtime-nativo-linha-b.md` — contrato Linha B mínima (proxy pós-ExitBoot)
- `docs/desenho-memoria-scheduler-nativo.md` — desenho candidato Weights/KvCache + Prefill/Decode (ADR 0003)
- `docs/adr/0003-memoria-model-aware-e-scheduler-fases.md` — ADR do desenho; impl. mínima = Etapa 19
- `docs/desenho-gpu-manager-multi-gpu.md` — desenho GPU manager / multi-GPU (ADR 0006; stub host = Etapa 25)
- `docs/adr/0006-gpu-manager-multi-gpu.md` — ADR do escopo candidato (host ≠ nativo)
- `LICENSE` / `NOTICE` — Apache-2.0 (1ª parte); ADR [`0007`](docs/adr/0007-licencas-por-componente.md)
- `docs/licencas-terceiros.md` — aviso de deps (llama.cpp, uefi, …)
- `scripts/run-harness-line-a.sh` — corrida Linha A (wrapper do runtime, marcadores `HARNESS_`)
- `scripts/run-harness-line-a-optimized.sh` — perfil `A_otimizada` (Etapa 34; threads/governor/taskset)
- `scripts/run-harness-line-b.sh` — Linha B via QEMU (proxy + `HARNESS_CONTRACT_*` + bloqueio GGUF; `HARNESS_OK`)
- `scripts/verify-harness.sh` — gate A (GGUF) + B (proxy QEMU + contrato + bloqueio GGUF)
- `scripts/verify-harness-a-otimizada.sh` — gate do perfil A_otimizada (`make verify-harness-a-otimizada`)
- `scripts/run-harness-a-b-comparable.sh` — corrida A+B + `VERDICT`/`VERDICT_REASON` (Etapa 22); opt-in `IA_LIVRE_HARNESS_A_PROFILE=A_otimizada`
- `scripts/verify-harness-comparable.sh` — gate do instrumento comparável
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
