# atualizar-backlog

Gerencie `BACKLOG.md` (capturar, reordenar, arquivar) e o espelho GitHub **best-effort**. **Não** promove para o roadmap sozinho.

## Capturar

1. Leia `BACKLOG.md`.
2. Adicione item em **Abertas** com id `B<n>` (próximo livre), título, notas curtas e origem se houver.
3. Espelho best-effort (`export PATH="$HOME/.local/bin:$PATH"`):
   - `gh label create backlog --force` (ignore se já existir).
   - `gh issue create --title "…" --body "…" --label backlog`.
   - Grave `Issue: #N` no item do `BACKLOG.md`.
   - Se `gh` falhar: deixe só o arquivo local, avise em uma linha; **não** bloqueie a fatia.
4. Confirme em uma linha o id, o título e o `#N` (ou “sem espelho”).

## Reordenar

1. Sob pedido do usuário, mova itens em **Abertas** (topo = prioridade).
2. Não altere `ROADMAP.md`.

## Arquivar

1. Sob pedido (descartar / já feito fora do roadmap), mova para **Promovidas / arquivadas** com motivo curto.
2. Não delete histórico sem pedido.

## Promover (só se o usuário confirmar nesta conversa)

1. Não rode promoção só porque o comando foi invocado — precisa de “promova B…” / “vamos para o topo do backlog” explícito.
2. Se confirmado:
   - Se o item já tem `Issue: #N` de backlog: `gh issue edit N` — remover label `backlog`, adicionar `roadmap` + `status:*`, atualizar body com `Pronto quando`; vincular ao Project se ainda não estiver.
   - Se não tem issue: criar via `/atualizar-roadmap` como etapa nova.
   - Grave a etapa em `ROADMAP.md` e mova o item para **Promovidas / arquivadas** com `Issue: #N`.
