# Agent claim (lease)

Arquivo canônico para **um escritor** na etapa `em_andamento`.  
Regra: `.cursor/rules/agentes-em-paralelo.mdc`.

## Estado atual

- **holder:** cursor-agent-principal
- **etapa:** 21 — Carga GGUF canônica na Linha B (mínimo honesto)
- **issue:** #21
- **paths:** ROADMAP.md, BACKLOG.md, memory-bank/, specs/carga-gguf-linha-b/, docs/, AGENTS.md, Makefile, scripts/, kernel/ (só se carga GGUF real exigir)
- **since:** 2026-11-21T00:37:00Z
- **expires:** 2026-11-21T02:37:00Z

## Como usar

1. `git fetch` + `pull --ff-only`.
2. Se `holder` preenchido e `expires` no futuro e **não** for você → **pare** (não edite a etapa/`paths`).
3. Para claimar: preencha este arquivo, **commit + push só do claim** (mensagem `chore: claim Etapa N`), `fetch` de novo; se o tip ainda tiver o seu holder, siga.
4. Ao terminar a fatia/etapa (ou abortar): limpe para o estado “nenhum” e push `chore: release claim`.

TTL sugerido: **2 horas**. Se expirou, outro agente pode claimar após sync.
