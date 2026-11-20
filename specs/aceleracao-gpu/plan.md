# Plan — Aceleração além de CPU (GPU)

## Abordagem

Três fatias verticais até o Pronto quando da Etapa 8. Ambiente fixo: **host Linux** + extensão do crate **`runtime/`** (`ia-livre-runtime`) + features **llama-cpp-2** (CUDA canônico / Vulkan alternativa) + flag **`--n-gpu-layers`** + métricas comparáveis + gate GPU com skip. **Não** tocar no kernel UEFI; **não** multi-GPU; preservar `make verify-runtime` (CPU).

### Task 1 — ADR + features Cargo + flag CLI (esqueleto GPU-capable)

1. Escrever ADR 0002: CUDA canônico no host, Vulkan alternativa, fallback CPU, fora de escopo (multi-GPU, GPU no kernel).
2. Em `runtime/Cargo.toml`: features opcionais `cuda` / `vulkan` (nomes alinhados à binding) que ativam `llama-cpp-2/...`; **default sem GPU**.
3. Em `runtime/src/main.rs`: parsear `--n-gpu-layers <N>` (default `0`); passar para `LlamaModelParams::with_n_gpu_layers`; emitir `IA_LIVRE_ACCEL=` / `IA_LIVRE_N_GPU_LAYERS=` de forma coerente (em Task 1 pode ser `cpu` se ainda sem link GPU).
4. Atualizar `docs/architecture.md` (apontar ADR / fechar a decisão aberta no nível “protótipo host”).
5. `AGENTS.md`: pré-requisitos parciais (features, flag); **Como rodar** CPU inalterado em comportamento default.
6. Avaliar `README.md` (`readme-por-fatia`); provavelmente ainda cedo — registrar se não atualizar.
7. Garantir `cargo build -p ia-livre-runtime` (default) e que o gate CPU continua verde após a fatia (rodar `make verify-runtime` se o modelo estiver presente).

Critério parcial: ADR existe; features e flag documentadas; default CPU não regride.

### Task 2 — Caminho GPU real + métricas comparáveis

1. No host com GPU: build com a feature do backend canônico (`--features cuda` ou a escolhida na prática se CUDA falhar e Vulkan for o caminho viável — registrar a escolha efetiva no ADR/doc se divergir).
2. Executar inferência com `--n-gpu-layers` > 0 (valor documentado, estável para o gate).
3. Confirmar marcadores: `IA_LIVRE_INFER_OK`, `IA_LIVRE_LOAD_S=`, `IA_LIVRE_TOKENS_PER_S=`, `IA_LIVRE_ACCEL=` ≠ `cpu`.
4. Documentar métricas em `docs/runtime-inferencia-gpu-metricas.md` (preferido) **ou** seção GPU na doc da Etapa 5 — tabela comparável (mesmo modelo/prompt/`n-predict` quando possível; hardware GPU/driver; N layers).
5. Documentar critérios de fallback: quando usar CPU; o que fazer se init GPU falhar.
6. Atualizar **Como rodar** GPU em `AGENTS.md` (comando completo).
7. `readme-por-fatia`: reavaliar README.

Critério parcial: no host com GPU, comando documentado acelera (ACCEL ≠ cpu) e métricas GPU estão documentadas; CPU default intacto.

### Task 3 — Gate `verify-runtime-gpu` + política de skip + AGENTS completo

1. Criar `scripts/verify-runtime-gpu.sh` + alvo Makefile `verify-runtime-gpu`.
2. Fixar política de skip **única** (recomendação):  
   - Sem GPU / `VERIFY_RUNTIME_GPU_SKIP=1`: imprime `IA_LIVRE_GPU_SKIP` e exit **0** (CI sem GPU não fica vermelha).  
   - Com GPU esperada (skip **não** setado e GPU detectável / feature build ok): exige marcadores de sucesso + `IA_LIVRE_ACCEL` coerente; falha no timeout ou se ACCEL=cpu.
3. Documentar detecção mínima (ex.: presença de `nvidia-smi` para CUDA, ou variável forçando skip) — pragmática, não perfeita.
4. Completar `AGENTS.md` → **Como verificar** (Etapa 8) além dos gates 4–7.
5. Confirmar que `make verify-runtime` (CPU) permanece verde.
6. `readme-por-fatia`: se a capa omitir GPU e isso enganar visitantes, menção curta + ponte para AGENTS; senão registrar “considerado, não necessário”.
7. Não marcar roadmap `feita` nesta task — fica para o agente principal após gate + revisor.

### Valores canônicos (orientação)

| Item | Valor |
|------|--------|
| Modelo | TinyLlama 1.1B Chat v1.0 Q4_K_M (mesmo da E5) |
| Prompt | `Complete em uma frase: O Projeto IA Livre é` |
| `--n-predict` (gate) | 32 (igual E5, salvo bloqueio documentado) |
| `--n-gpu-layers` (prova GPU) | valor fixo documentado (ex. `99` = offload máximo pragmático no llama.cpp, ou N medido no host) |
| Feature default | nenhuma (CPU) |
| Feature prova GPU | `cuda` (ou `vulkan` se CUDA inviável — documentar) |

### Notas de implementação (orientação, não código aqui)

- Manter `agent/` e `node/` intocados salvo necessidade mínima (preferir não tocar).
- Não commitar toolkits CUDA, `.so` grandes, nem `*.gguf`.
- Listar pacotes/`apt`/env (`CUDA_PATH`, etc.) em AGENTS no estilo dos pré-requisitos cmake/libclang.
- Timeout do gate GPU: similar ao runtime CPU (ex. 300s) com override `VERIFY_RUNTIME_GPU_TIMEOUT`.
- Se a binding exigir `cuda-no-vmm` em algum driver, documentar como nota de host — não expandir escopo.

## Arquivos prováveis

- `docs/adr/0002-aceleracao-gpu-host-llama-cpp.md` (Task 1)
- `runtime/Cargo.toml` — features `cuda` / `vulkan`
- `runtime/src/main.rs` — `--n-gpu-layers`, marcadores `IA_LIVRE_ACCEL` / `IA_LIVRE_N_GPU_LAYERS`
- `docs/runtime-inferencia-gpu-metricas.md` (Task 2) e/ou extensão da doc CPU
- `docs/architecture.md` — apontar ADR / decisão
- `scripts/verify-runtime-gpu.sh`, `Makefile` — alvo `verify-runtime-gpu` (Task 3)
- `AGENTS.md` — Como rodar / Como verificar / Estrutura
- `README.md` — só se `readme-por-fatia` exigir

Não editar como entrega: `kernel/**` (comportamento), `node/**`, manifesto; `agent/**` só se estritamente necessário.

## Dependências

- Etapas 1–7 feitas (runtime CPU gateado; agent/node existem mas não são dependência funcional da GPU)
- Host: Rust, deps nativas do llama.cpp; para prova GPU: driver + toolkit do backend escolhido
- Modelo GGUF via `./scripts/fetch-model.sh`
- Sem dependência de QEMU/UEFI, P2P ou agent para o gate GPU

## Verificação

1. Checklist de `spec.md` (critérios de aceite)
2. Gate CPU continua verde: `make verify-runtime`
3. Gate GPU: `make verify-runtime-gpu` no host com GPU; skip documentado sem GPU
4. Gates kernel / node / agent não são regressão obrigatória a cada fatia, mas não devem ser quebrados por mudanças no runtime
5. Após gate verde da etapa: agente principal chama `revisor-de-fatia`, atualiza ROADMAP/Memory Bank (fora do papel do especificador)
