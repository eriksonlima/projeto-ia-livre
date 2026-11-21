# Plan — Tool `read_local` allowlisted (host)

## Abordagem

Três fatias **verticais** até o Pronto quando da Etapa 54. Base: `agent/` E24/E40/E53. Ambiente: **host Linux** + GGUF canônico para o gate. **Não** tocar kernel/node/harness/runtime além do consumo já existente. **Não** introduzir shell/HTTP/write arbitrário.

Ordem: contrato + roots → implementação `read_local` (+ REPL desejável) → gate estendido + `AGENTS.md`.

### Task 1 — Contrato `read_local` + allowlist de paths (doc)

1. Criar `docs/autonomia-read-local.md` **ou** seção canônica em `docs/autonomia-alem-v1.md`: tool `read_local`, roots allowlisted, limite de bytes, erros, marcadores `TOOL=read_local` / `READ_LOCAL_OK`.
2. Fixar roots canônicos (sugerido: diretório do `--memory` / `build/agent-memory/` + `agent/fixtures/`) e fixture de prova (`agent/fixtures/read-local-smoke.txt`).
3. Pontes: `autonomia-alem-v1.md` (Futuro → E54), `autonomia-repl.md` (comando no REPL), `desenho-autonomia-v1.md` se houver tabela futuro.
4. Esboço do que `verify-agent` passará a exigir (incluindo negativo fora da allowlist).

Critério parcial: contrato legível + marcadores e roots fixados; **sem** código obrigatório nesta task (fixture texto pode ser criada aqui).

### Task 2 — Implementação `read_local` em `agent/` (+ REPL)

1. Função/módulo `tool_read_local(memory, path)`: normalizar/canonicalize; checar prefixo nos roots; ler texto; rejeitar fora/traversal/tamanho; registrar kind `tool`.
2. Atualizar `tool_help`; integrar na prova sem `--prompt` **e/ou** no parser REPL (`repl.rs`) com linha `read_local <path>`.
3. Fixture scripted: estender `agent/fixtures/repl-smoke.txt` **ou** fixture dedicada com `read_local` + `quit`.
4. Teste unitário mínimo accept (fixture) / reject (`/etc/passwd`, `../../`, path absoluto fora).
5. `cargo build -p ia-livre-agent` sucede; **sem** write arbitrário; **sem** `Command`/HTTP.

Critério parcial: smoke manual mostra `IA_LIVRE_TOOL=read_local` + `IA_LIVRE_READ_LOCAL_OK`; rejeição honesta fora da allowlist.

### Task 3 — Gate `verify-agent` + fechamento documental

1. Estender `scripts/verify-agent.sh`: exigir `IA_LIVRE_TOOL=read_local` + `IA_LIVRE_READ_LOCAL_OK`; manter E7/v1/E40/E53 (`calc`, `TOOL_SANDBOX_OK`, `REPL_OK`).
2. Atualizar `AGENTS.md` (Como rodar / Como verificar); README (`readme-por-fatia`).
3. `make verify-agent` verde; não marcar etapa `feita` aqui (agente principal após revisor).

Critério parcial: gate verde; docs e AGENTS sincronizados.

### Defaults canônicos (orientação)

| Item | Valor |
|------|-------|
| Fixture conteúdo | `agent/fixtures/read-local-smoke.txt` |
| Marcadores | `IA_LIVRE_TOOL=read_local`, `IA_LIVRE_READ_LOCAL_OK` |
| Roots | memory-dir + `agent/fixtures/` (ajustar na Task 1 se necessário) |
| Limite bytes | 64 KiB (ou valor fixado na Task 1) |
| Memória gate | `build/agent-memory-verify/memory.jsonl` (inalterado) |
| Timeout | `VERIFY_AGENT_TIMEOUT` (default 300s) |
| Allowlist prévia | `note`, `recall`, `help`, `calc` (+ REPL) — preservada |

### Notas de implementação (orientação)

- Preferir `agent/src/read_local.rs` se `main.rs` crescer; reexport para `repl.rs`.
- Nunca abrir path antes do check de allowlist pós-canonicalize.
- Symlink: se `canonicalize` falhar ou escapar root → rejeitar.
- `IA_LIVRE_TOOLS_USED` pode subir; gate v1 exige ≥2 — **não** reduzir.
- Negativo canônico: `read_local /etc/passwd` ou `read_local ../../secret` deve falhar **sem** `READ_LOCAL_OK`.

## Arquivos prováveis

- `agent/src/main.rs`, `agent/src/read_local.rs` (novo, provável), `agent/src/repl.rs`
- `agent/fixtures/read-local-smoke.txt` (novo), `agent/fixtures/repl-smoke.txt` (extensão)
- `docs/autonomia-read-local.md` (novo) e/ou `docs/autonomia-alem-v1.md`, `docs/autonomia-repl.md`
- `docs/desenho-autonomia-v1.md` (ponte)
- `scripts/verify-agent.sh`
- `AGENTS.md`, `README.md` (se `readme-por-fatia`)
- `specs/read-local-allowlisted/tasks.md`

Não editar como entrega desta etapa: `kernel/`, `node/`, harness, status `feita` no `ROADMAP.md` (agente principal).

## Dependências

- Etapas 40 e 53 feitas (`calc` + REPL).
- Host: Rust estável; `./scripts/fetch-model.sh` na primeira vez.
- Sem QEMU/UEFI para o agente.
- Coordenação: lease `memory-bank/AGENT_CLAIM.md` antes de implementar.

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
./scripts/fetch-model.sh
cargo build -p ia-livre-runtime -p ia-livre-agent

make verify-agent
grep -q 'IA_LIVRE_READ_LOCAL_OK' scripts/verify-agent.sh
grep -q 'read_local' docs/autonomia-alem-v1.md || test -f docs/autonomia-read-local.md
grep -q 'IA_LIVRE_TOOL=read_local' agent/src/main.rs || grep -q 'read_local' agent/src/read_local.rs
```

Gate da etapa = checklist da spec + `make verify-agent` com evidência `read_local`. Gates kernel/runtime/node/harness **inalterados** como critério desta etapa.
