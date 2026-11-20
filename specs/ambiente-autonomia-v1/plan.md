# Plan — Ambiente de autonomia além do protótipo (v1 utilizável)

## Abordagem

1. **ADR de escopo** (Task 1): fixar em `docs/adr/0005-…` a decisão estrutural — autonomia v1 no host (sem exigir SO), evoluindo `agent/`: sessão com `--goal` + N turnos, JSONL + consulta, registro com `note` + ferramenta de recall/listagem; esta etapa = desenho (**doc-only**); implementação = futuro.
2. **Doc de escopo** (Task 2): expandir motivação vs E7, contrato de sessão/ferramentas/memória, **critério verificável mínimo** (marcadores candidatos além de E7), fronteira do próximo protótipo e não-objetivos; sem código.
3. **Pontes e fechamento documental** (Task 3): atualizar `architecture.md` (decisão aberta → escopo decidido no nível desenho), ponte em `ambiente-autonomia-prototipo.md`, `AGENTS.md` se couber, README avaliado.

Ordem: ADR → desenho detalhado → pontes (as pontes citam paths estáveis do ADR/doc).

## Arquivos prováveis

- `docs/adr/0005-ambiente-autonomia-v1.md` (nome final alinhado à Task 1)
- `docs/desenho-ambiente-autonomia-v1.md`
- `docs/architecture.md` — decisão aberta da autonomia v1 → decidida no nível desenho/escopo
- `docs/ambiente-autonomia-prototipo.md` — ponte honestidade (Etapa 7 vs desenho Etapa 15)
- `AGENTS.md` — ponte curta em Estrutura / docs (sem gate novo de código)
- `README.md` — só se a capa ficar enganosa sem menção ao escopo v1
- `specs/ambiente-autonomia-v1/tasks.md` — marcar fatias

## Dependências

- Etapas 1–14 feitas (ADR 0001, protótipo de autonomia E7, arquitetura).
- Sem QEMU, GGUF ou build de `agent/` como pré-requisito do gate **desta** etapa (documental).
- Não depende de implementação P2P v1, runtime nativo em B, nem GPU no agente.

## Verificação

Gate desta etapa = **checklist documental** (não `make verify-agent` novo nem alteração de código):

```bash
test -f docs/adr/0005-ambiente-autonomia-v1.md   # ou nome fixado
test -f docs/desenho-ambiente-autonomia-v1.md
grep -qiE 'goal|turno|recall|list_notes|GOAL_OK|RECALL_OK' docs/desenho-ambiente-autonomia-v1.md
grep -qiE '0005|autonomia-v1|versão utilizável|escopo.*autonomia' docs/architecture.md
grep -qiE 'Etapa 15|desenho|v1' docs/ambiente-autonomia-prototipo.md
# Sem diff de código de produto em agent/ kernel/ runtime/ node/ (salvo ponte doc)
```

Critério de pronto da etapa: ADR + doc de escopo coerentes com a proposta única (**doc-only**); architecture e ponte do protótipo atualizados; critério verificável mínimo da v1 documentado; sem implementação do agente v1.
