# Plan — Licenças definitivas por componente

## Abordagem

1. **ADR de política** (Task 1): fixar em `docs/adr/0007-…` a decisão — Apache-2.0 para `kernel`, `runtime`, `node`, `agent` e `docs`; GPLv3 não usada nesta etapa; nota de não-parecer-jurídico; mapa por componente; deps de terceiros fora do relicenciamento.
2. **Arquivos LICENSE no repo** (Task 2): gravar `LICENSE` (Apache-2.0) na raiz; `NOTICE` ou doc curto de terceiros; campo `license = "Apache-2.0"` nos quatro crates.
3. **Pontes e fechamento documental** (Task 3): atualizar manifesto (remover «a confirmar»), `architecture.md` (decisão aberta → decidida), README/AGENTS/CONTRIBUTING conforme `readme-por-fatia`.

Ordem: ADR → arquivos de licença/metadados → pontes (as pontes citam paths estáveis).

## Arquivos prováveis

- `docs/adr/0007-licencas-por-componente.md` (nome final alinhado à Task 1)
- `LICENSE` (raiz)
- `NOTICE` e/ou `docs/licencas-terceiros.md`
- `kernel/Cargo.toml`, `runtime/Cargo.toml`, `node/Cargo.toml`, `agent/Cargo.toml` — só campo `license` (e opcional `authors`/`repository` se já houver padrão; não inventar metadados irrelevantes)
- `docs/manifesto.md` — § Política open source
- `docs/architecture.md` — decisões abertas
- `README.md` — menção curta à licença se a capa precisar
- `AGENTS.md` / `CONTRIBUTING.md` — ponte opcional
- `specs/licencas-por-componente/tasks.md` — marcar fatias

## Dependências

- Etapas 1–16 feitas (manifesto e architecture existem; crates nomeados).
- Sem QEMU, GGUF ou `make verify*` como pré-requisito do gate desta etapa.
- Texto oficial Apache-2.0 (fonte SPDX / apache.org) para o arquivo `LICENSE`.

## Verificação

Gate desta etapa = **checklist documental + arquivos** (não gate de produto novo):

```bash
test -f LICENSE
test -f docs/adr/0007-licencas-por-componente.md   # ou nome fixado na Task 1
grep -q 'Apache-2.0' kernel/Cargo.toml
grep -q 'Apache-2.0' runtime/Cargo.toml
grep -q 'Apache-2.0' node/Cargo.toml
grep -q 'Apache-2.0' agent/Cargo.toml
grep -qiE 'Apache|0007|licen' docs/manifesto.md
grep -qiE '0007|Apache-2.0|licen' docs/architecture.md
# NOTICE ou docs/licencas-terceiros.md
test -f NOTICE || test -f docs/licencas-terceiros.md
# Manifesto não deve mais dizer só "a confirmar" como estado da preferência
! grep -q 'Preferência de licenças (decisão a confirmar' docs/manifesto.md
```

Critério de pronto da etapa: ADR + LICENSE + metadados Cargo + pontes manifesto/architecture; alinhado à preferência Apache do manifesto; deps de terceiros apenas documentadas.
