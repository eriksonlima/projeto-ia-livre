# Plan — Autonomia além de v1 (tool sandboxed `calc`)

## Abordagem

Três fatias **verticais** até o Pronto quando da Etapa 40. Base: `agent/` v1 (E24). Ambiente: **host Linux** + GGUF canônico para o gate. **Não** puxar REPL nesta etapa. **Não** tocar kernel/node/harness/runtime além do consumo já existente.

Ordem: contrato `calc` → implementação em `agent/` → gate estendido + docs/`AGENTS.md`.

### Task 1 — Contrato autonomia além v1 + sandbox `calc` (doc)

1. Criar `docs/autonomia-alem-v1.md`: tool `calc`, subset de expressão, erros, marcadores `TOOL=calc` / `TOOL_SANDBOX_OK`, limites, futuro REPL/`read_local`.
2. Fixar expressão canônica da prova (ex. `1+2*3` → `7`) e regras de rejeição (charset, div/0).
3. Ponte em `docs/desenho-autonomia-v1.md` (linha futuro → E40).
4. Esboço de extensão do gate na doc (o que `verify-agent` passará a exigir).
5. ADR 0005: addendum mínimo «sandbox calc E40» se couber em uma seção — sem reabrir escopo v1.

Critério parcial: contrato legível + marcadores fixados; **sem** código obrigatório nesta task.

### Task 2 — Implementação `calc` em `agent/`

1. Função/módulo `tool_calc(memory, expr)` com validação de charset e avaliação segura (sem subprocess/shell/rede/FS).
2. Atualizar `tool_help` com entrada `calc`.
3. Integrar no cenário de prova sem `--prompt` **após** fluxo v1 existente (note/recall/help): chamar `calc` com expressão canônica; emitir `IA_LIVRE_TOOL=calc` e `IA_LIVRE_TOOL_SANDBOX_OK`.
4. Teste unitário mínimo para accept/reject de `expr` (preferível nesta task).
5. `cargo build -p ia-livre-agent` (+ runtime se necessário) sucede.

Critério parcial: smoke manual com GGUF opcional; prova sem `--prompt` mostra marcadores novos no stdout.

### Task 3 — Gate estendido + fechamento documental

1. Estender `scripts/verify-agent.sh`: grep `IA_LIVRE_TOOL=calc` + `IA_LIVRE_TOOL_SANDBOX_OK`; manter todos os checks E7/v1.
2. Atualizar `AGENTS.md` (Como rodar / Como verificar); README (`readme-por-fatia`).
3. `make verify-agent` verde; não marcar etapa `feita` aqui (agente principal após revisor).

Critério parcial: gate verde; doc e AGENTS sincronizados.

### Defaults canônicos (orientação)

| Item | Valor |
|------|-------|
| Expressão prova | `1+2*3` |
| Resultado esperado | `7` |
| Memória gate | `build/agent-memory-verify/memory.jsonl` (inalterado) |
| Timeout | `VERIFY_AGENT_TIMEOUT` (default 300s) |
| Modelo | TinyLlama Q4_K_M canônico |
| Tools v1 | `note`, `recall`, `help` — inalterados |

### Notas de implementação (orientação)

- Preferir `agent/src/tools.rs` ou `agent/src/calc.rs` se `main.rs` crescer — reexport em `main.rs`.
- Rejeitar `expr` com `std::process::Command` ou imports de rede — code review explícito na fatia.
- `IA_LIVRE_TOOLS_USED` pode subir (ex. 4); gate v1 exige ≥2 — **não** reduzir.
- Negativo: `calc("; rm")` ou `calc("2+foo")` deve falhar antes de `TOOL_SANDBOX_OK`.

## Arquivos prováveis

- `agent/src/main.rs`, `agent/src/calc.rs` ou `agent/src/tools.rs` (novo, provável)
- `agent/Cargo.toml` — dep expr **só** se inevitável e auditável
- `docs/autonomia-alem-v1.md` (novo)
- `docs/desenho-autonomia-v1.md`
- `docs/adr/0005-autonomia-v1-utilizavel.md` — addendum opcional
- `scripts/verify-agent.sh`, `Makefile` (se necessário)
- `AGENTS.md`
- `specs/autonomia-alem-v1/tasks.md`

Não editar como entrega desta etapa: `kernel/`, `node/`, harness, status `ROADMAP.md` (agente principal).

## Dependências

- Etapa 24 feita (v1 + gate).
- Host: Rust estável; `./scripts/fetch-model.sh` na primeira vez.
- Sem QEMU/UEFI para o agente.
- Coordenação: lease `memory-bank/AGENT_CLAIM.md` antes de implementar.

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
./scripts/fetch-model.sh
cargo build -p ia-livre-runtime -p ia-livre-agent

# Smoke (após Task 2, sem --prompt = prova)
# cargo run -p ia-livre-agent -- \
#   --model models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
#   --memory build/agent-memory/memory.jsonl

make verify-agent
test -f docs/autonomia-alem-v1.md
grep -q 'IA_LIVRE_TOOL_SANDBOX_OK' scripts/verify-agent.sh
grep -q 'calc' docs/autonomia-alem-v1.md
```

Gate da etapa = checklist da spec + `make verify-agent` com evidência `calc`. Gates kernel/runtime/node/harness **inalterados** como critério desta etapa.