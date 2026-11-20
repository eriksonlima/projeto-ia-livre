# AGENTS.md

Brief do repositório para agentes. Em conflito com outros arquivos de ferramenta, este arquivo e `.cursor/rules/` vencem para o processo; `CLAUDE.md` apenas aponta para cá.

## Projeto

- Nome: `Projeto IA Livre`
- Resumo: Ecossistema open source brasileiro com SO próprio (IA Livre) especializado em IA nativa e rede P2P (Rede IA Livre) para colaboração computacional e de conhecimento. Participar da rede não exige o SO.
- Stack: Documentação e governança nesta fase; kernel planejado em Rust (x86-64, UEFI, QEMU); runtime de inferência e protocolo P2P a definir nas etapas seguintes.

## Como rodar

Nesta etapa não há binário. O repositório é documentação e scaffold.

```bash
# Leitura do contexto ativo
cat ROADMAP.md memory-bank/activeContext.md
```

## Como verificar

Gate da etapa de fundação (checklist):

```bash
test -f README.md && test -f AGENTS.md && test -f ROADMAP.md
test -d .cursor/rules && test -d .cursor/agents && test -d .cursor/commands && test -d .cursor/hooks && test -d .cursor/skills
test -d docs && test -d specs && test -d memory-bank
git remote get-url origin
grep -q 'em_andamento' ROADMAP.md
```

Quando houver código: adicione aqui os comandos reais (ex.: `cargo test`, build QEMU).

## PATH

Sempre inclua o GitHub CLI local:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Estrutura

- `ROADMAP.md` — etapas e status (fonte do próximo passo)
- `specs/` — Spec-Driven Development (spec → plan → tasks)
- `docs/` — produto, arquitetura e ADRs
- `memory-bank/` — contexto volátil entre chats (`activeContext.md`, `progress.md`)
- `.cursor/` — rules, agents, skills, commands, hooks

## Fora de escopo do agente

- Commitar segredos, `.env` ou chaves
- Force push, `--no-verify`, alterar config do git
- Abrir PR sem evidência do gate
- Implementar fora da etapa `em_andamento` do roadmap

## Ponte

- Rules: `.cursor/rules/`
- Roadmap: `ROADMAP.md`
- Specs: `specs/`
- Product context: `docs/product-context.md`
- Memory Bank: `memory-bank/activeContext.md`
