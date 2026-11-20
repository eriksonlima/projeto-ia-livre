---
name: claim-agente-paralelo
description: >-
  Claim/release do lease multi-agente em memory-bank/AGENT_CLAIM.md antes de
  editar a etapa em_andamento ou promover backlog. Use ao iniciar fatia com
  risco de segundo chat, ao “claimar”, ou ao liberar o lease.
disable-model-invocation: true
---

# Claim de agente (lease)

## Quando usar

- Antes de promover item do backlog ou editar a etapa `em_andamento`
- Usuário pede “claim” / “claimar” / liberar lease
- Segundo chat pode estar ativo no mesmo `main`

## Canônico

- Lease: `memory-bank/AGENT_CLAIM.md`
- Rule: `.cursor/rules/agentes-em-paralelo.mdc`
- Preferência: **um** agente escritor no `main`; outro só observa ou item distinto em branch

## Claim (antes de editar produto)

1. `git fetch` + `git pull --ff-only` (se atrás). Divergência → **pare** (sem force / rebase `-i`).
2. Leia `AGENT_CLAIM.md`, `ROADMAP.md`, `BACKLOG.md`, `memory-bank/activeContext.md`.
3. Se `holder` preenchido, `expires` no futuro e **não** for você → **pare** e relate. Não edite a etapa/`paths`.
4. Se expirou (TTL sugerido **2h**): pode claimar após sync.
5. Preencha o lease (`holder`, `etapa`, `issue`, `paths`, `since`, `expires`).
6. **Commit + push só do claim** (`chore: claim Etapa N`).
7. `git fetch` de novo; confirme que o tip ainda tem o seu `holder`. Só então edite spec/docs/código.

## Claim check (promoção)

Além do lease: item ainda em **Abertas**? Issue ainda `backlog`? Etapa/issue já no `ROADMAP`? Se já promovido → não duplique.

## Durante o trabalho

- Um escritor por conjunto de arquivos da etapa
- Não abra segunda `em_andamento`
- Subagente não sobrescreve lease nem promove etapa
- Não feche issue / marque `feita` se o lease não for seu

## Release

1. Ao concluir fatia/etapa ou abortar: limpe `AGENT_CLAIM.md` (holder = nenhum).
2. Commit + push (`chore: release claim`).
3. Antes de push de produto: `fetch`; se atrás, `pull --ff-only`; non-ff → pare.

## Conflito já ocorrido

Pare o segundo agente → sync → canônico = `Spec:` do `ROADMAP.md` → remova duplicatas → um commit de consolidação → só então claimar de novo.
