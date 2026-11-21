# Agent claim (lease)

Arquivo canônico para **um escritor** na etapa `em_andamento`.  
Regra: `.cursor/rules/agentes-em-paralelo.mdc`.

## Estado atual

- **holder:** cursor-agent-main
- **etapa:** 30
- **issue:** #30
- **paths:** ROADMAP.md, BACKLOG.md, specs/boot-hardware-real/, docs/, scripts/, Makefile, memory-bank/, AGENTS.md, README.md
- **since:** 2026-11-21T06:43:56Z
- **expires:** 2026-11-21T08:43:56Z

## Como usar

1. `git fetch` + `pull --ff-only`.
2. Se `holder` preenchido e `expires` no futuro e **não** for você → **pare**.
3. Para claimar: preencha, commit+push só do claim, fetch de novo.
4. Ao terminar: limpe e push `chore: release claim`.

TTL sugerido: **2 horas**.
