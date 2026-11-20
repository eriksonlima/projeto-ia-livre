# Agent claim (lease)

Arquivo canônico para **um escritor** na etapa `em_andamento`.  
Regra: `.cursor/rules/agentes-em-paralelo.mdc`.

## Estado atual

- **holder:** cursor-agent-df93a573
- **etapa:** 16 — GPU manager no kernel / multi-GPU (desenho)
- **issue:** #16
- **paths:** ROADMAP.md, BACKLOG.md, specs/gpu-manager-multi-gpu/, docs/adr/, docs/desenho*, docs/architecture.md, AGENTS.md, memory-bank/
- **since:** 2026-11-20T23:28:00Z
- **expires:** 2026-11-21T01:28:00Z

## Como usar

1. `git fetch` + `pull --ff-only`.
2. Se `holder` preenchido e `expires` no futuro e **não** for você → **pare** (não edite a etapa/`paths`).
3. Para claimar: preencha este arquivo, **commit + push só do claim** (mensagem `chore: claim Etapa N`), `fetch` de novo; se o tip ainda tiver o seu holder, siga.
4. Ao terminar a fatia/etapa (ou abortar): limpe para o estado “nenhum” e push `chore: release claim`.

TTL sugerido: **2 horas**. Se expirou, outro agente pode claimar após sync.
