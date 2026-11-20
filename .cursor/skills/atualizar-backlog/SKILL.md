---
name: atualizar-backlog
description: >-
  Captura, reordena ou arquiva demandas em BACKLOG.md com espelho GitHub
  best-effort (label backlog) e promove para ROADMAP.md só com confirmação.
  Use ao anotar ideia fora da etapa, ao esvaziar o roadmap, ou /atualizar-backlog.
disable-model-invocation: true
---

# Atualizar backlog

## Quando usar

- Usuário pede para anotar demanda / ideia / lacuna fora da etapa atual
- Roadmap sem `em_andamento` nem `pendente` e o pedido é “continuar” / “próximo”
- Comando `/atualizar-backlog`

## Canônico

- Arquivo: `BACKLOG.md` (Abertas = prioridade pelo topo; Promovidas / arquivadas)
- Espelho GitHub: **best-effort** com label `backlog`; falha de `gh` não bloqueia
- Project V2: obrigatório só para etapas do `ROADMAP.md` (após promoção)
- Rule: `.cursor/rules/backlog-do-projeto.mdc` (se existir); command: `.cursor/commands/atualizar-backlog.md`

## Capturar

1. Leia `BACKLOG.md`.
2. Em **Abertas**, acrescente `### B<n> — <título>` (próximo `n` livre), notas curtas e origem.
3. Best-effort: `gh label create backlog --force`; `gh issue create … --label backlog`; grave `Issue: #N` no item. Se falhar, só local + aviso em uma linha.
4. Não altere `ROADMAP.md` na captura.
5. Responda em uma linha: id + título + `#N` ou “sem espelho”.

## Reordenar / arquivar

- Reordenar: sob pedido, mova itens em **Abertas** (topo = próxima candidata).
- Arquivar: sob pedido, mova para **Promovidas / arquivadas** com motivo; não apague histórico sem pedido.

## Roadmap vazio (“continuar”)

1. Leia `ROADMAP.md` e `BACKLOG.md`.
2. Se não houver etapa `em_andamento`/`pendente` e houver item em **Abertas**: proponha o **topo** (título + `Pronto quando` sugerido) e **espere confirmação**.
3. Não invente etapa nem implemente produto só por estar no backlog.

## Promover (só com confirmação explícita)

Ex.: “promova B1”, “vamos para o topo do backlog”.

1. Grave a etapa em `ROADMAP.md` (`pendente` ou `em_andamento`).
2. Se já existir issue de backlog: remova label `backlog`, adicione `roadmap` + `status:*`, atualize `Pronto quando`, vincule ao Project. Senão, crie via `/atualizar-roadmap`.
3. Mova o item para **Promovidas / arquivadas** com `Issue: #N`.
4. Se `gh` falhar na promoção: mantenha `ROADMAP.md`/`BACKLOG.md` locais, registre bloqueio, não invente outro board.

## Durante a fatia

Não interrompa a fatia para perguntar sobre backlog. Capture só se pedido ou se o pedido for claramente fora de escopo — anote e continue a fatia.
