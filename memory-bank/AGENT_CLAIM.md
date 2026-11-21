# Agent claim (lease)

Arquivo canônico para **um escritor** na etapa `em_andamento`.  
Regra: `.cursor/rules/agentes-em-paralelo.mdc`.

## Estado atual

- **holder:** cursor-agent-main
- **etapa:** 28
- **issue:** #28
- **paths:** ROADMAP.md, BACKLOG.md, specs/recorrida-harness-quieta/, docs/, scripts/, memory-bank/, AGENTS.md
- **since:** 2026-11-21T02:03:46Z
- **expires:** 2026-11-21T04:03:46Z

## Como usar

1. `git fetch` + `pull --ff-only`.
2. Se `holder` preenchido e `expires` no futuro e **não** for você → **pare**.
3. Para claimar: preencha, commit+push só do claim, fetch de novo.
4. Ao terminar: limpe e push `chore: release claim`.

TTL sugerido: **2 horas**.
