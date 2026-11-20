# Plan — Ambiente de autonomia (camada 3)

## Abordagem

Três fatias verticais até o Pronto quando da Etapa 7. Ambiente fixo: **host Linux** + crate **`agent/`** + consumo do **`ia-livre-runtime`** existente + **memória em arquivo** + **≥1 ferramenta** + doc + gate adicional. **Não** alterar comportamento do kernel UEFI nem do nó P2P; **não** exigir QEMU. Evitar refactor obrigatório do `runtime/` em lib — preferir subprocesso CLI.

### Task 1 — Scaffold do agente + contrato documentado

1. Adicionar membro `agent/` ao workspace Cargo (target host/`std`; **não** `x86_64-unknown-uefi`).
2. Pacote/binário `ia-livre-agent` com CLI mínima: pelo menos path do modelo (`--model`), path da memória (`--memory` com default documentado), e esqueleto que ainda pode imprimir “scaffold ok” + parse de flags.
3. Criar `docs/ambiente-autonomia-prototipo.md` com: loop do agente, formato da memória, contrato da ferramenta mínima (nome + args + efeito), como o runtime será invocado, cenário de prova do gate, e independência do SO / QEMU / `node/`.
4. Atualizar `AGENTS.md`: layout `agent/`, pré-requisitos (Rust host + deps/modelo do runtime), **Como rodar** parcial (`cargo build -p ia-livre-agent`), nota de que autonomia neste protótipo **não** exige o IA Livre.
5. Garantir que o workspace/Makefile das etapas anteriores **não** regredem estruturalmente (não é obrigatório re-rodar `verify-runtime` se o modelo estiver ausente nesta fatia).

Critério parcial: `cargo build -p ia-livre-agent` sucede; doc do protótipo existe; AGENTS menciona o agente e a independência do SO.

### Task 2 — Loop mínimo: runtime + uma ferramenta

1. Implementar o loop curto do cenário de prova: montar prompt fixo → invocar `ia-livre-runtime` (subprocesso preferido: binário em `target/…` ou `cargo run -p ia-livre-runtime -- …`) com `--n-predict` baixo → obter texto gerado.
2. Implementar **pelo menos uma ferramenta** com contrato alinhado à doc (ex.: `note` / `salvar_nota` que appenda ao store de memória, ou equivalente com efeito em arquivo).
3. No cenário de prova, **garantir** a invocação da ferramenta (não depender só do SLM emitir tool-call). Parsing opcional da saída do modelo pode existir, mas o gate path deve ser determinístico.
4. Emitir `IA_LIVRE_TOOL_OK` após sucesso da ferramenta; caminho feliz também deve deixar claro o uso do runtime (log ou marcador opcional `IA_LIVRE_RUNTIME_USED=1`).
5. Atualizar **Como rodar** com o comando de ponta a ponta até tool OK (memória pode ainda ser só write nesta fatia se a Task 3 fechar a prova de re-leitura — preferir já escrever no arquivo da memória).

Critério parcial: um comando documentado chama o runtime, executa a ferramenta e imprime `IA_LIVRE_TOOL_OK` (e preferencialmente já escreve no arquivo de memória).

### Task 3 — Memória persistente + marcadores + gate

1. Fechar persistência: formato fixado; escrita + **re-leitura** (mesma execução e/ou segunda invocação no script de verify) → `IA_LIVRE_MEMORY_OK`.
2. Emitir `IA_LIVRE_AGENT_OK` ao concluir o cenário de prova com runtime + ferramenta + memória OK.
3. Script `scripts/verify-agent.sh` (+ alvo `make verify-agent`): garante modelo (reusa `fetch-model.sh` ou falha clara), build do agente, roda cenário de prova, `grep -q` nos três marcadores, cleanup; timeout `VERIFY_AGENT_TIMEOUT` (default sugerido 300s).
4. Completar `AGENTS.md` → **Como verificar** (Etapa 7) e reforçar independência do SO / QEMU; listar gate adicional sem remover os anteriores.
5. Fechar exemplos em `docs/ambiente-autonomia-prototipo.md` (defaults finais, captura de marcadores).
6. Não avançar roadmap para `feita` nesta task — marcação fica para o agente principal após gate + revisor.

### Defaults canônicos (orientação)

| Item | Valor sugerido |
|------|----------------|
| Crate / binário | `agent/` / `ia-livre-agent` |
| Memória | `build/agent-memory/memory.jsonl` (ou `.txt`); gitignored via `build/` |
| Ferramenta de prova | `note` — append de uma linha/nota ao store |
| Prompt de prova | curto e fixo (ex.: pedir uma frase sobre o Projeto IA Livre) |
| `--n-predict` no consumo | 16–32 (baixo, alinhado ao gate do runtime) |
| Modelo | canônico Etapa 5 (`models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf`) |
| Timeout do gate | 300s (`VERIFY_AGENT_TIMEOUT`) |
| Marcadores | `IA_LIVRE_AGENT_OK`, `IA_LIVRE_TOOL_OK`, `IA_LIVRE_MEMORY_OK` |

Ajustar paths/flags se necessário; documentar os valores finais em AGENTS + doc do protótipo.

### Notas de implementação (orientação, não código aqui)

- Workspace: `members` inclui `agent` junto de `kernel`, `runtime`, `node`.
- Preferir deps mínimas: `std` + parse de args simples; sem `uefi`, sem crates do `node/`.
- Subprocesso: localizar `ia-livre-runtime` via `CARGO_BIN_EXE` / path relativo ao target, ou invocar `cargo run -p ia-livre-runtime -- …` (mais lento, ok no protótipo se documentado).
- Não commitar conteúdo de memória nem pesos.
- Script de verify: logs em `/tmp` ou `build/`, `trap` para cleanup; pode remover/recriar o arquivo de memória do cenário de prova para idempotência, desde que a **prova de persistência** ocorra dentro do próprio script (escreve → re-lê ou segunda run).
- Não duplicar métricas de tokens/s do runtime como critério desta etapa (opcional ecoar; não gate).

## Arquivos prováveis

- `agent/Cargo.toml`, `agent/src/main.rs` (e módulos mínimos: `memory`, `tools`, `runtime_client`)
- `Cargo.toml` (workspace: adicionar `agent`)
- `docs/ambiente-autonomia-prototipo.md`
- `scripts/verify-agent.sh`
- `Makefile` — alvo `verify-agent`
- `AGENTS.md` — Como rodar / Como verificar / Estrutura / Stack (menção ao agente)
- `README.md` — menção curta opcional ao protótipo de autonomia
- `.gitignore` — se path de memória não estiver coberto por `build/`

Não editar como entrega: comportamento de `kernel/src/**`, `node/src/**`; manifesto; ADR 0001 (salvo link); P2P; GPU.

Opcional mínimo: atualizar tabela “Fronteira” / decisões abertas em `docs/architecture.md` refletindo o mínimo da camada 3 — **não** é critério de aceite (ADR novo só se surgir decisão estrutural permanente além do protótipo; doc do protótipo + AGENTS bastam).

## Dependências

- Etapas 1–6 feitas (scaffold, manifesto, architecture + ADR 0001, kernel, runtime CPU, nó P2P)
- Host: Rust estável; modelo GGUF da Etapa 5 disponível para o gate do agente
- Deps nativas já exigidas pelo runtime (cmake/libclang etc.) quando o gate invoca inferência
- Sem dependência de QEMU/OVMF para o agente
- Sem dependência do SO IA Livre nem do `node/` para o cenário de prova

## Verificação

1. Checklist de `spec.md` (critérios de aceite)
2. Gates anteriores não são substituídos: `make verify`, `make verify-runtime`, `make verify-node` permanecem válidos
3. Gate do agente em `AGENTS.md` → **Como verificar** (Etapa 7): `make verify-agent` / `scripts/verify-agent.sh`
4. Confirmar ausência de P2P/UEFI-agente/RAG/multi-agente na entrega
5. Após gate verde: agente principal chama `revisor-de-fatia`, atualiza ROADMAP/Memory Bank (fora do papel do especificador)
