# Spec — Aceleração além de CPU (GPU)

## Resultado visível

Existe um **protótipo de aceleração GPU** no **host Linux** sobre o runtime existente (`ia-livre-runtime` / llama.cpp via `llama-cpp-2`), com **backend de aceleração escolhido e documentado** (CUDA ou Vulkan — ver decisão abaixo), **fallback CPU preservado** (`n_gpu_layers=0` / build default sem feature GPU), **métricas comparáveis às da Etapa 5** e **gate verificável quando houver GPU** (`make verify-runtime-gpu` ou equivalente). Como rodar e como verificar GPU estão em `AGENTS.md`. A entrega **não** exige kernel UEFI / QEMU; multi-GPU e GPU manager completo ficam fora. Alinha ao ADR 0001 — aceleração nesta etapa é **camada 2 (runtime) no host**, não no kernel.

## Contexto fixo (não reinventar)

- ADR 0001: kernel pequeno; inferência **fora** do kernel; runtime evolui em ritmo próprio — [`docs/adr/0001-separacao-camadas-e-p2p.md`](../../docs/adr/0001-separacao-camadas-e-p2p.md).
- Arquitetura: camada 2 = runtime nativo de IA; decisão aberta “estratégia de aceleração além de CPU” — esta etapa **fecha o protótipo pragmático no host**, sem GPU manager no kernel — [`docs/architecture.md`](../../docs/architecture.md).
- Runtime CPU (Etapa 5): crate `runtime/`, modelo TinyLlama GGUF canônico, `n_gpu_layers=0`, marcadores `IA_LIVRE_INFER_OK` / `IA_LIVRE_LOAD_S=` / `IA_LIVRE_TOKENS_PER_S=` — [`specs/runtime-inferencia-cpu/`](../runtime-inferencia-cpu/), [`docs/runtime-inferencia-cpu-metricas.md`](../../docs/runtime-inferencia-cpu-metricas.md).
- Agent (Etapa 7): consome o runtime via subprocesso; **não** precisa mudar nesta etapa salvo ajuste mínimo de flags se couber e for necessário — [`specs/ambiente-autonomia/`](../ambiente-autonomia/).
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Host de referência: Linux (Ubuntu/Debian; Acer Nitro 5 ou equivalente com GPU NVIDIA quando disponível) — **ambiente de execução = host**, não QEMU/UEFI.
- Rule `readme-por-fatia`: cada fatia **avalia** se `README.md` precisa refletir a superfície pública; se não for necessário, registrar na fatia.

## Decisão de ambiente e stack (obrigatória nesta etapa)

**Ambiente:** protótipo no **host Linux** (`std`), estendendo o crate **`runtime/`** existente. **Não** embutido no kernel UEFI, **não** bootado em QEMU. Aceleração GPU nesta etapa **não** exige o SO IA Livre.

**Abordagem:** feature/flag no runtime existente — **não** reinventar GPU manager nem multi-GPU.

| Peça | Escolha |
|------|---------|
| Crate | Continuar `ia-livre-runtime` (`runtime/`) |
| Backend de aceleração | Feature Cargo do `llama-cpp-2` apontando para o backend do llama.cpp |
| Offload | Flag CLI `--n-gpu-layers <N>` (N > 0 na prova GPU; default **0** = CPU, preserva Etapa 5) |
| Modelo | O mesmo GGUF canônico da Etapa 5 (`models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf`) |
| Métricas | Mesmos marcadores da Etapa 5 + marcador de backend/aceleração (ver abaixo) |

### Backend canônico (escolha estrutural — ADR)

**Preferência documentada nesta etapa:**

1. **CUDA** — backend canônico do protótipo quando o host tiver NVIDIA + toolkit CUDA compatível com a feature `cuda` do `llama-cpp-2` / llama.cpp.
2. **Vulkan** — alternativa documentada se CUDA for inviável no host (drivers/toolchain) mas houver GPU Vulkan utilizável via feature `vulkan` do `llama-cpp-2`.
3. **ROCm** — fora do caminho crítico desta etapa (pode ser nota futura); não é critério de aceite.

Justificativa:

- Reutiliza o stack já gateado (llama.cpp + TinyLlama GGUF).
- Feature flags da binding já existem (`cuda`, `vulkan`, `rocm`, `metal`) — caminho mais curto.
- Host de referência do autor tipicamente tem NVIDIA → CUDA primeiro.
- Vulkan cobre portabilidade sem reinventar binding.

A escolha **CUDA (canônico) + Vulkan (alternativa documentada)** e o critério de fallback CPU devem ser registrados em **ADR nova** (ex.: `docs/adr/0002-aceleracao-gpu-host-llama-cpp.md`) e refletidos em doc curta de métricas/aceleração.

Alternativas **não** adotadas nesta etapa: backends próprios; Candle/PyTorch como stack GPU; GPU manager no kernel; multi-GPU / tensor parallel; Metal (macOS fora do host de referência); treino; NPU.

### Fallback CPU (obrigatório)

| Situação | Comportamento |
|----------|----------------|
| Build default (sem feature GPU) | Continua CPU; `make verify-runtime` verde |
| Feature GPU habilitada, mas `--n-gpu-layers 0` | Inferência CPU (mesmo binário GPU-capable) |
| Feature GPU habilitada, GPU ausente / falha de init | Falha clara **ou** fallback CPU documentado — o **gate GPU** deve falhar se GPU era esperada; o **gate CPU** e o uso diário sem GPU não devem regredir |
| CI / host sem GPU | Gate GPU **skip** documentado (exit distinto ou variável `SKIP` / mensagem canônica), sem quebrar CI genérica |

O caminho CPU da Etapa 5 (`n_gpu_layers=0`, `make verify-runtime`) **permanece** o default e **não** pode regredir.

### Marcadores de saída

Preservar:

1. `IA_LIVRE_INFER_OK`
2. `IA_LIVRE_LOAD_S=`
3. `IA_LIVRE_TOKENS_PER_S=`

Adicionar (grepáveis, estáveis):

4. `IA_LIVRE_ACCEL=` — valor documentado: `cpu` \| `cuda` \| `vulkan` (ou equivalente fixado na implementação)
5. Opcional útil: `IA_LIVRE_N_GPU_LAYERS=<N>`

### Métricas comparáveis (Etapa 5)

- Mesmo modelo, prompt canônico e `--n-predict` do gate CPU (ou documentar desvio mínimo).
- Documentar load time e tokens/s em **CPU** (baseline existente ou re-medido) **e** em **GPU** no host de referência quando GPU disponível.
- Arquivo: estender `docs/runtime-inferencia-cpu-metricas.md` **ou** criar `docs/runtime-inferencia-gpu-metricas.md` com tabela comparável — deixar explícito que **não** é o benchmark Linha A vs B.

## Conteúdo obrigatório

### 1. Extensão do runtime (`runtime/`)

- Feature(s) Cargo para o backend escolhido (ex.: `cuda` e/ou `vulkan` no `runtime/Cargo.toml`, repassando a `llama-cpp-2`).
- Build **default** sem feature GPU permanece CPU-only (ou CPU-safe).
- CLI: `--n-gpu-layers <N>` (default `0`); demais flags da Etapa 5 preservadas (`--model`, `--prompt`, `--n-predict`).
- Emitir marcadores de aceleração + métricas nas corridas GPU e CPU.

### 2. Documentação da escolha e do ADR

- ADR 0002 (ou próximo número livre) com: contexto, decisão CUDA canônico / Vulkan alternativa, consequências, o que fica fora (multi-GPU, GPU no kernel).
- Atualizar menção em `docs/architecture.md` (decisão aberta → apontar ADR / protótipo host) — mínimo necessário.
- Doc de métricas GPU (ou seção GPU na doc existente) com hardware (GPU/driver), backend, `n_gpu_layers`, números.

### 3. Gate GPU + skip sem GPU

- Alvo `make verify-runtime-gpu` e/ou `scripts/verify-runtime-gpu.sh`.
- Quando GPU esperada e disponível: build com feature do backend, run com `--n-gpu-layers` > 0, exige `IA_LIVRE_INFER_OK` + métricas + `IA_LIVRE_ACCEL=` coerente com o backend (não `cpu`).
- Quando host **não** tem GPU (ou `VERIFY_RUNTIME_GPU_SKIP=1` / equivalente documentado): script **não** finge sucesso de aceleração — documenta skip explícito (mensagem canônica, ex. `IA_LIVRE_GPU_SKIP`) e exit code acordado (preferir **0 com skip marcado** para CI sem GPU, **ou** exit ≠ 0 só quando GPU foi exigida via flag — fixar **uma** política na Task 3 e refletir em `AGENTS.md`).
- Gates existentes permanecem: `make verify`, `make verify-runtime`, `make verify-node`, `make verify-agent`.

### 4. `AGENTS.md` (+ README se couber)

- **Como rodar:** pré-requisitos GPU (CUDA toolkit / Vulkan SDK conforme backend), feature Cargo, exemplo com `--n-gpu-layers`, fallback CPU.
- **Como verificar:** gate `verify-runtime-gpu` + política de skip.
- **Estrutura:** mencionar feature/docs GPU se necessário.
- `README.md`: avaliar (`readme-por-fatia`); atualizar só se a capa do GitHub ficar enganosa sem menção a GPU; senão registrar que foi considerado.

## Fora de escopo

- Multi-GPU, tensor parallel, pipeline parallel, GPU manager completo
- Aceleração / drivers / scheduler GPU **dentro do kernel UEFI** ou em QEMU
- Treinamento, fine-tuning, quantização custom
- Troca do modelo canônico (salvo bloqueio documentado)
- Mudança no nó P2P (`node/`)
- Mudança no agente (`agent/`) salvo ajuste mínimo de flags se estritamente necessário
- Metal / ROCm como critério de aceite
- Servidor HTTP/gRPC, batch multi-tenant
- Benchmark formal Linha A vs Linha B
- Embarcar pesos ou toolkits CUDA no git

## Critérios de aceite

- [ ] Runtime existente aceita offload GPU via flag (`--n-gpu-layers`) e feature Cargo do backend llama.cpp documentada
- [ ] Escolha CUDA (canônico) / Vulkan (alternativa) e fallback CPU estão em ADR + docs
- [ ] Build/run default (CPU) e `make verify-runtime` **não** regridem
- [ ] Métricas GPU documentadas de forma comparável às da Etapa 5 (mesmo modelo/prompt quando possível)
- [ ] `make verify-runtime-gpu` (ou script equivalente) verifica aceleração quando há GPU; política de skip documentada sem GPU / CI
- [ ] `AGENTS.md` cobre como rodar e verificar GPU; README avaliado (`readme-por-fatia`)
- [ ] Nenhum código de multi-GPU, GPU no kernel, treino, ou mudança P2P como entrega desta etapa
- [ ] Etapa 8 não é marcada `feita` nesta spec (só após gate + revisão pelo agente principal)

## Riscos e rollback

- **Risco:** toolchain CUDA/Vulkan difícil de instalar no host → documentar pré-requisitos mínimos; Vulkan como alternativa; gate com skip claro se GPU indisponível.
- **Risco:** feature GPU quebra o build CPU default → features Cargo opcionais; CI/default sem feature GPU; gate CPU separado.
- **Risco:** `n_gpu_layers` alto em SLM pequeno sem ganho / OOM → usar N documentado e baixo o bastante para o TinyLlama no host de referência; métricas ainda válidas como prova de caminho.
- **Risco:** escopo inchado (multi-GPU, manager no kernel) → rejeitar; Pronto quando = protótipo host + doc + gate.
- **Rollback:** remover features GPU / flag / scripts `verify-runtime-gpu` / ADR 0002 / docs de métricas GPU; restaurar `n_gpu_layers=0` fixo se necessário; etapa continua `em_andamento`.

## Etapa do roadmap

- Etapa 8 — Aceleração além de CPU (GPU) (`em_andamento`, Issue [#8](https://github.com/eriksonlima/projeto-ia-livre/issues/8))
- Spec: `specs/aceleracao-gpu/`
- Pronto quando (roadmap): protótipo de aceleração GPU no host sobre o runtime existente (backend do llama.cpp), com escolha CUDA/Vulkan (ou equivalente suportado) documentada, fallback CPU preservado, métricas comparáveis às da Etapa 5 e gate verificável quando houver GPU — sem exigir o kernel UEFI / QEMU; multi-GPU e GPU manager completo fora de escopo.
