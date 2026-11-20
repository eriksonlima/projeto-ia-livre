# Spec — Runtime mínimo de inferência (CPU)

## Resultado visível

Existe um **protótipo de runtime de inferência em CPU** no repositório que, no **host Linux de referência** (não dentro do kernel UEFI), **carrega um modelo pequeno (SLM/tiny)**, executa uma **inferência com prompt fixo** e **registra métricas básicas** (tempo de load e tokens/s ou latência). Como rodar e como verificar estão em `AGENTS.md`. A entrega prova o caminho mínimo da camada 2 (runtime), alinhada ao ADR 0001 — inteligência pesada **fora** do kernel.

## Contexto fixo (não reinventar)

- ADR 0001: kernel pequeno; inferência/treinamento/agentes **fora** do kernel; runtime evolui em ritmo próprio — [`docs/adr/0001-separacao-camadas-e-p2p.md`](../../docs/adr/0001-separacao-camadas-e-p2p.md).
- Arquitetura: camada 2 = runtime nativo de IA; **CPU antes de GPU**; bootstrap do kernel (Etapa 4) já entregue e **não** é o ambiente de execução desta etapa — [`docs/architecture.md`](../../docs/architecture.md).
- Product context: entrega progressiva boot QEMU → **inferência CPU** → nó P2P; hipótese de pesquisa ainda não exige benchmark Linha A vs B nesta etapa — [`docs/product-context.md`](../../docs/product-context.md).
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Host de referência do autor: Linux no Acer Nitro 5 (ou equivalente Ubuntu/Debian) — **ambiente de execução desta etapa = host**, não QEMU/UEFI.
- Etapa 6 (P2P) permanece fora desta spec.

## Decisão de ambiente e stack (obrigatória nesta etapa)

**Ambiente:** protótipo no **host Linux** (`std`), **não** embutido no kernel UEFI nem bootado em QEMU. Integração runtime↔kernel fica para etapas futuras.

**Stack única escolhida:** crate Rust `runtime/` no workspace Cargo (membro host, target nativo do host) + backend de inferência CPU via **llama.cpp** (binding Rust estável documentada, ex. `llama-cpp-2`, **ou** wrapper fino que invoca o binário `llama-cli`/`main` do llama.cpp se a binding bloquear o host — preferir binding; fallback CLI deve ser justificado em `AGENTS.md`).

Justificativa:

- Alinha ao restante do projeto (Rust) e à evolução futura do “runtime nativo”.
- llama.cpp é o caminho mais curto e reproduzível para SLM quantizado em CPU com métricas de tokens/s.
- Modelo em GGUF pequeno cabe em RAM típica de desenvolvimento.

Alternativas **não** adotadas nesta etapa: PyTorch/transformers puro; Candle como stack principal; ONNX Runtime; GPU/CUDA/ROCm; rodar inferência dentro do EFI/QEMU.

### Modelo

- Um único modelo **pequeno** documentado (ex.: família TinyLlama ~1.1B ou SmolLM ≤360M, quantização GGUF Q4 ou similar).
- Artefato **não** versionado no git (download scriptado ou instrução em `AGENTS.md`); path local sob diretório gitignored (ex.: `models/` ou `runtime/models/`).
- Critério: carrega e gera texto em CPU no host de referência sem GPU.

### Métricas mínimas (obrigatórias)

Documentar e emitir na execução (stdout e/ou arquivo curto em `docs/`):

1. **Tempo de load** do modelo (segundos).
2. **Throughput ou latência de geração:** tokens/s **ou** latência média por token / por requisição — pelo menos uma das duas formas, com prompt e parâmetros de geração fixos (ou documentados).

Não exige p95, joules, qualidade BLEU/etc., nem comparação Linha A vs B nesta etapa.

## Conteúdo obrigatório

### 1. Crate / protótipo `runtime/`

- Diretório canônico: `runtime/` (membro do workspace Cargo na raiz, target **host**, não `x86_64-unknown-uefi`).
- Entrypoint CLI (ex.: `cargo run -p … -- …`) que: resolve path do modelo → carrega → gera a partir de prompt fixo → imprime texto gerado + métricas.
- Sem `#![no_std]`; sem depender do kernel UEFI.

### 2. Modelo e dados

- Instrução ou script para obter o GGUF (URL/HF revision pinada quando possível).
- `.gitignore` cobre pesos/binários grandes (`models/`, `*.gguf`, etc.).
- README curto do runtime **ou** seção em `AGENTS.md` com nome do modelo, quantização e tamanho aproximado.

### 3. Build / run / métricas

- Comandos em `AGENTS.md` → **Como rodar** (pré-requisitos host: Rust, deps nativas do llama.cpp se houver — cmake/libclang conforme a binding).
- Saída inclui métricas mínimas de forma grepável ou tabela curta documentada (ex.: `LOAD_S=…`, `TOKENS_PER_S=…` **ou** parágrafo em `docs/runtime-inferencia-cpu-metricas.md`).

### 4. Gate em `AGENTS.md`

- **Como verificar** da Etapa 5: comando(s) que constroem o runtime, garantem modelo disponível (ou falham com mensagem clara), executam inferência curta e confirmam sucesso (exit 0 + presença de marcadores de métrica ou de texto gerado).
- O gate do kernel (`make verify` / `IA_LIVRE_BOOT_OK`) **permanece**; o gate do runtime é **adicional**, não o substitui.
- Não exigir QEMU para o gate do runtime.

### 5. Documentação de métricas

- Valores obtidos no host de referência (ou placeholder preenchido após a primeira execução bem-sucedida) documentados: hardware resumido (CPU/RAM), modelo, prompt, load time, tokens/s ou latência.
- Deixar explícito que **não** é ainda o benchmark da hipótese de pesquisa (Linha A vs B).

## Fora de escopo

- Integração com o kernel UEFI / boot em QEMU / `ExitBootServices`
- GPU, CUDA, ROCm, Vulkan, NPU
- Servidor HTTP/gRPC de inferência, batch multi-tenant, KV cache avançado
- Treinamento, fine-tuning, quantização custom
- Ambiente de autonomia / agentes (camada 3)
- Rede IA Livre / P2P (Etapa 6)
- Benchmark comparativo formal Linha A vs Linha B
- Otimização agressiva (SIMD manual, threading fine-tune além do default do backend)
- Embarcar pesos no repositório git
- Alterar o comportamento do kernel da Etapa 4 (exceto menção documental se necessário)

## Critérios de aceite

- [x] Existe crate/protótipo `runtime/` (Rust host + llama.cpp binding ou fallback CLI documentado) no workspace
- [x] Um modelo pequeno GGUF é obtido por instrução/script documentado e **não** commitado
- [x] Comando documentado carrega o modelo em CPU e produz texto a partir de prompt fixo no host de referência
- [x] Métricas básicas (tempo de load + tokens/s ou latência) são emitidas e documentadas
- [x] `AGENTS.md` → **Como rodar** e **Como verificar** cobrem o runtime (gate adicional ao do kernel)
- [x] Nenhum código de GPU, P2P, agentes ou integração UEFI como entrega desta etapa
- [x] Etapa 5 permanece alinhada ao roadmap; não marcar como `feita` nesta spec (só após gate + revisão)

## Riscos e rollback

- **Risco:** binding Rust do llama.cpp falha a compilar no host → fallback documentado: CLI oficial do llama.cpp + script wrapper no repo que ainda mede load/geração; registrar a escolha em `AGENTS.md`.
- **Risco:** download do modelo / rede / disco → script com URL pinada, checksum opcional, path gitignored; gate falha com mensagem clara se o arquivo ausente.
- **Risco:** modelo “pequeno” ainda pesado demais → trocar para variante ≤360M (ex. SmolLM) sem mudar o restante da spec.
- **Risco:** escopo inchado (servidor, GPU, integrar ao EFI) → rejeitar; Pronto quando = load + inferência CPU + métricas no host.
- **Rollback:** remover `runtime/`, scripts de modelo/métricas e reverter trechos de `AGENTS.md`/`.gitignore`/`Cargo.toml` workspace; etapa continua `em_andamento`.

## Etapa do roadmap

- Etapa 5 — Runtime mínimo de inferência (CPU) (`em_andamento`, Issue [#5](https://github.com/eriksonlima/projeto-ia-livre/issues/5))
- Spec: `specs/runtime-inferencia-cpu/`
- Pronto quando (roadmap): carregar e executar um modelo pequeno em CPU no ambiente do projeto (ou protótipo no host de referência), com métricas básicas documentadas.
