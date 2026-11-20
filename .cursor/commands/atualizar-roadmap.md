# atualizar-roadmap

Sincronize `ROADMAP.md` com Issues e Project do GitHub. Use `PATH` com `$HOME/.local/bin`.

## No início do projeto (criar)

1. `export PATH="$HOME/.local/bin:$PATH"` e `gh auth status` (pare se não autenticado).
2. Labels: `gh label create roadmap --force` e `status:pendente`, `status:em_andamento`, `status:feita`, `status:bloqueada` (cores quaisquer; `--force` se já existirem).
3. Para cada etapa do `ROADMAP.md`: `gh issue create --title "…" --body "Pronto quando: …" --label roadmap --label status:pendente` (a etapa atual usa `status:em_andamento`).
4. Project V2: `gh project create --owner USER --title "NOME-do-repo roadmap"` (USER = `gh api user -q .login`). Anote o número do project.
5. Configure o campo Status do project com opções Pendente / Em andamento / Feita / Bloqueada (`gh project field-list` / `gh project field-create` conforme a API disponível).
6. Vincule cada issue: `gh project item-add PROJECT_NUMBER --owner USER --url ISSUE_URL`.
7. Grave no `ROADMAP.md`: `Project: <url>` e `Issue: #N` por etapa.

## No fim da fatia (atualizar)

1. Atualize Status no `ROADMAP.md` (só uma `em_andamento`).
2. Ajuste labels da issue (`gh issue edit N --remove-label status:… --add-label status:…`).
3. Mova o item no Project para a coluna correspondente (`gh project item-edit` com o campo Status).
4. Se `gh` falhar, registre o bloqueio no `ROADMAP.md` e informe — não invente outro board.
