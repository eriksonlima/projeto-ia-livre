---
name: etapa-em-worktree-isolado
description: >-
  Quando vários agentes trocam a branch do worktree principal, implementa a
  etapa em_andamento num git worktree isolado, faz FF para main e espelha
  GitHub. Use sob disputa de checkout/paralelo, não no fluxo normal.
disable-model-invocation: true
---

# Etapa em worktree isolado

## Quando

- `git worktree list` mostra várias branches e o cwd principal muda de branch no meio da fatia
- Arquivos escritos somem após `checkout` de outro agente
- Lease da `em_andamento` é seu, mas o diretório principal não é estável

## Passos

1. `git fetch`; confirme claim em `memory-bank/AGENT_CLAIM.md` e tip de `origin/main`.
2. `git worktree add <path-eN> -b etapa-N-<slug> origin/main` (pasta fora do worktree principal).
3. Trabalhe **só** nesse path (paths absolutos); build/verify/`commit` lá.
4. `git push -u origin <branch>`; se `origin/main` estiver atrás só do seu tip: `git push origin <branch>:main` (FF, sem force).
5. Espelhe issue/Project; liberte o lease no mesmo tip que for para `main`.
6. Não dispute a `em_andamento` de outro holder; se a próxima etapa já tiver branch/`roadmap` no GitHub, alinhe docs e pare/integre — não duplique promoção.

## Não fazer

- `checkout -f` no worktree principal para “ganhar” a pasta
- Force push / `--no-verify`
- Segunda `em_andamento` no `ROADMAP.md`
