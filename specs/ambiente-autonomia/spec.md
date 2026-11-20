# Spec — Ambiente de autonomia (camada 3)

## Resultado visível

Existe um **protótipo do ambiente de autonomia** no repositório que roda no **host Linux** (`std`), **sem** exigir o kernel UEFI / QEMU. Um binário CLI de **agente mínimo** executa um loop curto que **consome o runtime CPU existente** (`ia-livre-runtime` / llama-cpp-2), usa **memória persistente simples** (arquivo em path gitignored) e invoca **pelo menos uma ferramenta**. Como rodar e como verificar estão em `AGENTS.md` (gate **adicional** aos das Etapas 4–6). A entrega prova o caminho mínimo da **camada 3**, alinhada ao ADR 0001 — agentes e ferramentas **fora** do kernel; autonomia neste protótipo **não** depende do SO IA Livre.

## Contexto fixo (não reinventar)

- ADR 0001: kernel pequeno; inferência, agentes e ferramentas **fora** do kernel; runtime e autonomia evoluem em ritmo próprio — [`docs/adr/0001-separacao-camadas-e-p2p.md`](../../docs/adr/0001-separacao-camadas-e-p2p.md).
- Arquitetura: camada 3 = ambiente de autonomia (agentes, memória persistente, ferramentas); consome o runtime; não faz parte do núcleo — [`docs/architecture.md`](../../docs/architecture.md).
- Product context: agentes, memória e ferramentas para aprender e experimentar no próprio ambiente — [`docs/product-context.md`](../../docs/product-context.md).
- Runtime (Etapa 5): crate `runtime/`, CLI `ia-livre-runtime`, modelo TinyLlama GGUF, marcadores `IA_LIVRE_INFER_OK` / `IA_LIVRE_LOAD_S` / `IA_LIVRE_TOKENS_PER_S` — [`specs/runtime-inferencia-cpu/`](../runtime-inferencia-cpu/).
- Nó Rede (Etapa 6): camada 4 independente; **não** é dependência desta etapa — [`specs/no-rede-ia-livre/`](../no-rede-ia-livre/).
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Host de referência: Linux (Ubuntu/Debian) — **ambiente de execução = host**, não QEMU/UEFI.

## Decisão de ambiente e stack (obrigatória nesta etapa)

**Ambiente:** protótipo no **host Linux** (`std`). **Não** embutido no kernel UEFI, **não** bootado em QEMU. Participar/usar este protótipo de autonomia **não** exige o SO IA Livre.

**Stack única escolhida:** crate Rust **`agent/`** no workspace Cargo (membro host, target nativo), binário CLI `ia-livre-agent` (padrão `ia-livre-*`).

**Consumo do runtime (mínimo fixado):**

| Peça | Escolha |
|------|---------|
| Inferência | Invocar o binário/crate existente **`ia-livre-runtime`** (preferir **subprocesso** CLI com `--model` + `--prompt` + `--n-predict` baixo) |
| Modelo | O mesmo GGUF canônico da Etapa 5 (`models/tinyllama-…Q4_K_M.gguf`); obter via `./scripts/fetch-model.sh` |
| Acoplamento | `agent/` **não** reimplementa llama.cpp; **não** exige refactor do `runtime/` para lib nesta etapa (extração de lib = futuro) |
| Fallback | Se subprocesso for inviável no host, documentar chamada equivalente via `cargo run -p ia-livre-runtime -- …` no mesmo processo de verify |

Justificativa: reutiliza o caminho já gateado da Etapa 5; evita duplicar binding; mantém crates separados (camada 3 consome camada 2).

Alternativas **não** adotadas nesta etapa: agentes multi-hop elaborados; framework LangChain/equivalente; planejador ReAct completo com parsing frágil como único caminho do gate; integração com `node/` / P2P; embutir o agente no kernel UEFI; GPU.

### Agente mínimo

- Loop curto e documentado: (1) carregar memória → (2) montar prompt → (3) chamar runtime → (4) interpretar saída / decisão de ferramenta → (5) executar ferramenta se couber → (6) persistir memória → (7) emitir marcadores.
- **Cenário de prova canônico** (obrigatório para o gate): deve **garantir** uma chamada ao runtime, **uma** invocação bem-sucedida de ferramenta e **uma** leitura/escrita de memória verificável — mesmo que o texto gerado pelo SLM seja ruidoso. Ou seja: o gate **não** pode depender só do modelo emitir espontaneamente um formato de tool-call perfeito.
- Prompt/objetivo fixo documentado (curto, em PT ou EN).

### Memória persistente simples

- Persistência em **arquivo** sob path gitignored (ex.: `build/agent-memory/` ou `data/agent/`).
- Formato mínimo documentado: texto simples ou JSONL (turnos / notas) — **uma** forma fixada na doc.
- Prova: após uma execução, uma segunda execução (ou re-leitura na mesma) confirma que o conteúdo anterior está presente → marcador de memória.

### Ferramenta (pelo menos uma)

- Contrato mínimo documentado: nome, argumentos, efeito colateral observável (ex.: `note` / `salvar_nota` que appenda texto ao store de memória, ou ferramenta equivalente com I/O em arquivo no sandbox do agente).
- Registro/lista de ferramentas no código e na doc (mesmo que só exista uma).
- Sucesso da ferramenta emite marcador grepável.

### Marcadores de saída (obrigatórios para o gate)

Emitir na stdout de forma grepável:

1. `IA_LIVRE_AGENT_OK` — loop do cenário de prova concluiu com sucesso.
2. `IA_LIVRE_TOOL_OK` — a ferramenta de prova executou com sucesso.
3. `IA_LIVRE_MEMORY_OK` — memória persistente foi escrita e re-lida / confirmada.

Opcional útil: `IA_LIVRE_RUNTIME_USED=1`, path da memória, nome da ferramenta.

## Conteúdo obrigatório

### 1. Crate `agent/`

- Diretório canônico: `agent/` (membro do workspace Cargo na raiz, target **host**, não `x86_64-unknown-uefi`).
- CLI documentada (flags mínimas: path do modelo e/ou path da memória; defaults documentados).
- Sem `#![no_std]`; sem dependência de `kernel/` no `Cargo.toml`.
- Dependência de `runtime/` como **crate lib** **não** é obrigatória; consumo via subprocesso/`cargo run -p ia-livre-runtime` é o caminho preferido nesta etapa.

### 2. Protocolo / framing do protótipo documentado

- Documento curto em `docs/` (ex.: `docs/ambiente-autonomia-prototipo.md`) descrevendo:
  - loop do agente;
  - formato da memória;
  - contrato da(s) ferramenta(s);
  - como o runtime é invocado;
  - cenário de prova do gate;
  - que o protótipo **não exige** o SO IA Livre / QEMU / UEFI;
  - que P2P (`node/`) está fora desta entrega.
- Texto **público e aberto** no repo.

### 3. Build / run

- Comandos em `AGENTS.md` → **Como rodar** (pré-requisitos: Rust host + deps já listadas do runtime/modelo; **sem** QEMU/OVMF para o agente).
- Exemplo canônico de uma execução do cenário de prova.

### 4. Gate em `AGENTS.md`

- **Como verificar** da Etapa 7: comando(s) que garantem modelo disponível (ou falham claro), constroem o agente, executam o cenário de prova e confirmam `IA_LIVRE_AGENT_OK`, `IA_LIVRE_TOOL_OK` e `IA_LIVRE_MEMORY_OK`, exit 0.
- Gates das Etapas 4–6 **permanecem**; o gate do agente é **adicional**.
- Não exigir QEMU/UEFI para o gate do agente.
- Preferir `scripts/verify-agent.sh` e alvo `make verify-agent` (timeout generoso, da ordem do runtime — ex. 300s; override `VERIFY_AGENT_TIMEOUT`).

### 5. Prova de independência do SO

- Documentar explicitamente em `AGENTS.md` e na doc do protótipo: o ambiente de autonomia neste protótipo roda só no host com Rust + runtime/modelo; **não** precisa do EFI / `IA_LIVRE_BOOT_OK` nem do nó P2P.

## Fora de escopo

- Multi-agente, orquestração distribuída, marketplace de ferramentas
- Planejador ReAct/Chain-of-Thought robusto ou avaliação de qualidade do raciocínio
- Integração com `node/` / Rede IA Livre (tarefas P2P, descoberta)
- Integração com o kernel UEFI / boot em QEMU
- UI gráfica, IDE, notebook
- Memória vetorial / embeddings / RAG completo
- Sandbox OS-level (seccomp, containers) — basta path dedicado documentado
- Treinamento, fine-tuning, troca do modelo canônico (salvo bloqueio de RAM já tratado na Etapa 5)
- Refatorar `runtime/` em biblioteca compartilhada (opcional futuro; não bloqueia)
- GPU / CUDA / RoCm
- Alterar comportamento do kernel ou do nó além de menções documentais / workspace members

## Critérios de aceite

- [ ] Existe crate `agent/` (Rust host) no workspace, independente do `kernel/`
- [ ] O agente consome o runtime CPU existente (subprocesso CLI ou equivalente documentado) no cenário de prova
- [ ] Há memória persistente simples em arquivo gitignored, com formato documentado e prova de re-leitura
- [ ] Há pelo menos uma ferramenta com contrato documentado e efeito observável
- [ ] Stdout contém `IA_LIVRE_AGENT_OK`, `IA_LIVRE_TOOL_OK` e `IA_LIVRE_MEMORY_OK` de forma verificável
- [ ] `AGENTS.md` → **Como rodar** e **Como verificar** cobrem o agente (gate adicional); documentado que não exige o SO IA Livre / QEMU
- [ ] Doc curta do protótipo em `docs/`
- [ ] Nenhum P2P, UEFI-agente, multi-agente ou RAG vetorial como entrega desta etapa
- [ ] Etapa 7 marcada `feita` no roadmap somente após gate + revisor-de-fatia (fora desta spec)

## Riscos e rollback

- **Risco:** SLM não emite tool-call confiável → cenário de prova **garante** ferramenta + memória no caminho do gate; parsing opcional do texto do modelo não é o único critério de sucesso.
- **Risco:** gate lento / modelo ausente → reutilizar `fetch-model.sh`; timeout alto; falha clara se GGUF ausente (mesmo espírito de `verify-runtime`).
- **Risco:** acoplar agente ao kernel ou ao nó “porque já existem” → rejeitar; crates e gates separados; autonomia host-only.
- **Risco:** escopo inchado (ReAct, RAG, multi-agente) → rejeitar; Pronto quando = agente mínimo + memória + uma ferramenta + consumo do runtime + gate.
- **Rollback:** remover `agent/`, script/alvo `verify-agent`, doc do protótipo e trechos de `AGENTS.md`/`Cargo.toml` workspace; etapa continua `em_andamento`.

## Etapa do roadmap

- Etapa 7 — Ambiente de autonomia (camada 3) (`em_andamento`, Issue [#7](https://github.com/eriksonlima/projeto-ia-livre/issues/7))
- Spec: `specs/ambiente-autonomia/`
- Pronto quando (roadmap): protótipo da camada 3 no host Linux (`std`) com agente mínimo, memória persistente simples e pelo menos uma ferramenta; consome o runtime CPU existente; documentado; gate verificável — sem exigir o kernel UEFI / QEMU.
