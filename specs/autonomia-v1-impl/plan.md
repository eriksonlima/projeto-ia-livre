# Plan — Autonomia v1 utilizável (impl. em agent/)

## Abordagem

1. **CLI + política N=8** (Task 1): parse de `--prompt`; montar prompt = contexto curto + últimas 8 linhas JSONL + texto do usuário (ou prompt de prova se omitido); kinds `note`/`turn`/`tool`; emitir `IA_LIVRE_MEMORY_POLICY_OK`; manter `note` + marcadores E7 no path de prova.
2. **Ferramentas `recall` / `help`** (Task 2): implementar contratos da allowlist; no cenário de prova, invocar deterministicamente `note` **e** uma segunda tool; evidência stdout (`TOOLS_USED` e/ou marcadores por ferramenta).
3. **Gate + docs** (Task 3): estender `scripts/verify-agent.sh` (e AGENTS) para exigir marcadores v1 **sem** dropar E7; atualizar docs E7/desenho (ponte “implementado”); README avaliado.

Ordem: CLI/memória → tools → gate/docs (o gate depende dos marcadores das tasks 1–2).

## Arquivos prováveis

- `agent/src/main.rs` — CLI, montagem de prompt, tools, marcadores
- `agent/Cargo.toml` — só se precisar de dep mínima (preferir std + JSON manual como E7)
- `docs/ambiente-autonomia-prototipo.md` — evoluir ou ponte clara E7→v1 impl
- `docs/desenho-autonomia-v1.md` — marcar implementação (Etapa 24); não reabrir escopo
- `docs/adr/0005-autonomia-v1-utilizavel.md` — ponte curta “implementação = Etapa 24” (opcional se desenho + ambiente bastarem)
- `scripts/verify-agent.sh` — checks novos + regressão E7
- `Makefile` — só se o alvo `verify-agent` precisar de nota; preferir script
- `AGENTS.md` — Como rodar (`--prompt`) / Como verificar (marcadores v1)
- `README.md` — só se a capa ficar enganosa (`readme-por-fatia`)
- `specs/autonomia-v1-impl/tasks.md` — marcar fatias

## Dependências

- Etapas 7 e 15 feitas (protótipo + desenho/ADR 0005).
- Runtime CPU + GGUF canônico (`./scripts/fetch-model.sh`) para o gate.
- **Não** depende de Etapa 19 (kernel/scheduler), harness ou `node/`.
- Lease: Etapa 24 está `pendente`; implementação só quando o agente principal promover / claimar — esta spec **não** promove.

## Verificação

Por fatia, conforme `tasks.md`. Gate final da etapa:

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
./scripts/fetch-model.sh
make verify-agent
```

Esperado: exit 0; `IA_LIVRE_TOOL_OK` / `MEMORY_OK` / `AGENT_OK` + `IA_LIVRE_MEMORY_POLICY_OK` + evidência ≥2 ferramentas; sem QEMU/UEFI.
