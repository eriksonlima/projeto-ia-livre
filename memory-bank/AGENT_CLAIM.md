# Agent claim (lease)

Arquivo canônico para **um escritor** na etapa `em_andamento`.  
Regra: `.cursor/rules/agentes-em-paralelo.mdc`.

## Estado atual

- **holder:** cursor-agent-main
- **etapa:** 31
- **issue:** #31
- **paths:** ROADMAP.md, BACKLOG.md, specs/forward-gguf-linha-b/, docs/, runtime-native/, kernel/, scripts/, memory-bank/, AGENTS.md
- **since:** 2026-11-21T06:55:23Z
- **expires:** 2026-11-21T08:55:23Z

## Como usar

1. `git fetch` + `pull --ff-only`.
2. Se `holder` preenchido e `expires` no futuro e **não** for você → **pare**.
3. Claim: commit+push só do claim; fetch de novo.
4. Ao terminar: limpe e push release.

TTL sugerido: **2 horas**.
