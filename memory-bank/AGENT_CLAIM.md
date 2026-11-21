# Agent claim (lease)

Arquivo canônico para **um escritor** na etapa `em_andamento`.  
Regra: `.cursor/rules/agentes-em-paralelo.mdc`.

## Estado atual

- **holder:** agente-principal-integracao-b17-b19
- **etapa:** 23
- **issue:** #23
- **paths:** node/, specs/protocolo-rede-v1/, docs/desenho-protocolo-rede-ia-livre.md, docs/rede-ia-livre-prototipo.md, AGENTS.md, ROADMAP.md, memory-bank/, scripts/verify-node.sh
- **since:** 2026-11-21T00:53:07Z
- **expires:** 2026-11-21T02:53:07Z

## Como usar

1. `git fetch` + `pull --ff-only`.
2. Se `holder` preenchido e `expires` no futuro e **não** for você → **pare** (não edite a etapa/`paths`).
3. Para claimar: preencha este arquivo, **commit + push só do claim** (mensagem `chore: claim Etapa N`), `fetch` de novo; se o tip ainda tiver o seu holder, siga.
4. Ao terminar a fatia/etapa (ou abortar): limpe para o estado “nenhum” e push `chore: release claim`.

TTL sugerido: **2 horas**. Se expirou, outro agente pode claimar após sync.
