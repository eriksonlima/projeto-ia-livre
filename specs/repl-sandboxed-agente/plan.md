# Plan — REPL sandboxed no agente (host)

## Abordagem

Três fatias **verticais** até o Pronto quando da Etapa 53. Base: `agent/` com allowlist E24 + `calc` E40. Ambiente: **host Linux** + GGUF para o gate. **Não** tocar kernel/node/harness/bridges. **Não** adicionar tools novas.

Ordem: contrato REPL + fixture → implementação CLI/loop → gate estendido + docs/`AGENTS.md`.

### Task 1 — Contrato REPL + fixture scripted (doc)

1. Criar `docs/autonomia-repl.md`: flags `--repl` / `--repl-script`, formato de linha, allowlist, rejeições, marcadores `REPL_MODE` / `REPL_OK`, limites (sem shell/HTTP), relação com prova E7/v1/E40.
2. Ponte em `docs/autonomia-alem-v1.md` (Futuro REPL → E53) e linha em `docs/desenho-autonomia-v1.md` se couber.
3. Fixture versionada com ≥2 comandos allowlist + `quit` (path fixado na doc).
4. Esboço do estágio no `verify-agent` (o que passará a exigir).

Critério parcial: contrato + fixture legíveis; código opcional nesta task.

### Task 2 — CLI `--repl` / `--repl-script` + loop sandboxed

1. Parse de `--repl` e `--repl-script <FILE>`; erro se combinado ilegalmente com `--prompt`.
2. Loop: ler linhas (stdin interativo ou arquivo); despachar só `note`/`recall`/`help`/`calc`; `quit`/`exit` sai; fora da allowlist → erro honesto.
3. Emitir `IA_LIVRE_REPL_MODE=interactive|scripted` e `IA_LIVRE_REPL_OK` ao concluir scripted com sucesso (≥1 tool executada).
4. Reutilizar implementações `tool_*` existentes; **sem** `Command`/HTTP.
5. `cargo build -p ia-livre-agent` sucede; smoke scripted local.

Critério parcial: `cargo run … -- --repl-script <fixture>` imprime `REPL_MODE=scripted` + `REPL_OK`.

### Task 3 — Gate `verify-agent` + fechamento documental

1. Estender `scripts/verify-agent.sh` com estágio REPL scripted (marcadores novos); manter greps E7/v1/E40.
2. Atualizar `AGENTS.md` (Como rodar / Como verificar); avaliar README.
3. `make verify-agent` verde; não marcar etapa `feita` aqui.

Critério parcial: gate verde; doc e AGENTS sincronizados.

### Defaults canônicos (orientação)

| Item | Valor |
|------|-------|
| Fixture | `agent/fixtures/repl-smoke.txt` (ou path fixado na Task 1) |
| Conteúdo mínimo | `help` + `calc 1+2*3` + `quit` |
| Marcadores | `IA_LIVRE_REPL_MODE=scripted`, `IA_LIVRE_REPL_OK` |
| Memória gate | pode reutilizar dir verify existente ou subdir `…/repl/` |
| Timeout | `VERIFY_AGENT_TIMEOUT` (default 300s) |
| Allowlist | `note`, `recall`, `help`, `calc` — sem novas tools |

### Notas de implementação (orientação)

- Preferir `agent/src/repl.rs` se `main.rs` crescer.
- Scripted **não** precisa chamar o runtime se a fixture for só tools — reduz flakiness/timeout; documentar se o path `--repl` interativo ainda carrega modelo sob demanda.
- Negativo: linha `sh rm -rf /` ou `http get …` deve falhar antes de `REPL_OK`.

## Arquivos prováveis

- `agent/src/main.rs`, `agent/src/repl.rs` (novo, provável)
- `agent/fixtures/repl-smoke.txt` (novo)
- `docs/autonomia-repl.md` (novo)
- `docs/autonomia-alem-v1.md`, `docs/desenho-autonomia-v1.md` (pontes)
- `scripts/verify-agent.sh`, `Makefile` (se necessário)
- `AGENTS.md`, `README.md` (avaliar)
- `specs/repl-sandboxed-agente/tasks.md`

Não editar como entrega desta etapa: `kernel/`, `node/`, harness, bridges E49/E52, status final do `ROADMAP.md` (agente principal).

## Dependências

- Etapa 40 feita (`calc` + gate).
- Host: Rust estável; `./scripts/fetch-model.sh` se o estágio clássico ainda exige GGUF (sim).
- Sem QEMU/UEFI para o agente.
- Coordenação: lease `memory-bank/AGENT_CLAIM.md` antes de implementar.

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
./scripts/fetch-model.sh
cargo build -p ia-livre-runtime -p ia-livre-agent

# Smoke scripted (após Task 2)
# cargo run -p ia-livre-agent -- \
#   --model models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
#   --memory build/agent-memory/memory.jsonl \
#   --repl-script agent/fixtures/repl-smoke.txt

make verify-agent
test -f docs/autonomia-repl.md
grep -q 'IA_LIVRE_REPL_OK' scripts/verify-agent.sh
grep -q 'repl-script' AGENTS.md
```

Gate da etapa = checklist da spec + `make verify-agent` com evidência REPL. Gates kernel/runtime/node/harness **inalterados** como critério desta etapa.
