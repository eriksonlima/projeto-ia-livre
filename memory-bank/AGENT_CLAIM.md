# Agent claim (lease)

Arquivo canônico para **um escritor** na etapa `em_andamento`.  
Regra: `.cursor/rules/agentes-em-paralelo.mdc`.

## Estado atual

- **holder:** cursor-agent-principal-e26
- **etapa:** 26
- **issue:** #26
- **paths:** specs/loader-gguf-nativo-linha-b/, kernel/, scripts/, docs/runtime-nativo-linha-b.md, docs/harness-linha-a-b.md, Makefile, AGENTS.md, memory-bank/
- **since:** 2026-11-20T22:50:00-03:00
- **expires:** 2026-11-21T00:50:00-03:00

## Como usar

1. `git fetch` + `pull --ff-only`.
2. Se `holder` preenchido e `expires` no futuro e **não** for você → **pare** (não edite a etapa/`paths`).
3. Para claimar: preencha este arquivo, **commit + push só do claim** (mensagem `chore: claim Etapa N`), `fetch` de novo; se o tip ainda tiver o seu holder, siga.
4. Ao terminar a fatia/etapa (ou abortar): limpe para o estado “nenhum” e push `chore: release claim`.

TTL sugerido: **2 horas**. Se expirou, outro agente pode claimar após sync.
