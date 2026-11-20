# Plan — Ambiente de autonomia além do protótipo (v1 utilizável)

## Abordagem

1. **ADR candidata** (Task 1): fixar em `docs/adr/0005-…` a decisão estrutural — autonomia v1 no host (sem exigir SO IA Livre): UX CLI one-shot com `--prompt`, allowlist `note`/`recall`/`help`, política de memória JSONL com últimas N entradas, critério verificável mínimo documentado; P2P/kernel/marketplace/RAG/multi-agente fora; fronteiras ADR 0001 e protótipo Etapa 7.
2. **Doc de desenho** (Task 2): expandir fronteira E7×v1, contratos das ferramentas, política de memória, cenário/marcadores do critério verificável, alternativas rejeitadas; sem código.
3. **Pontes e fechamento documental** (Task 3): atualizar `architecture.md` (decisão aberta → desenho candidato), ponte em `ambiente-autonomia-prototipo.md`, `AGENTS.md` se couber, README avaliado.

Ordem: ADR → desenho detalhado → pontes (as pontes citam paths estáveis do ADR/doc).

## Arquivos prováveis

- `docs/adr/0005-autonomia-v1-utilizavel.md` (nome final alinhado à Task 1)
- `docs/desenho-autonomia-v1.md`
- `docs/architecture.md` — decisão aberta da autonomia v1 → decidida no nível desenho
- `docs/ambiente-autonomia-prototipo.md` — ponte honestidade (Etapa 7 vs desenho Etapa 15)
- `AGENTS.md` — ponte curta em Estrutura / docs (sem gate novo de código)
- `README.md` — só se a capa ficar enganosa sem menção ao desenho
- `specs/autonomia-v1-utilizavel/tasks.md` — marcar fatias

## Dependências

- Etapas 1–14 feitas (ADR 0001, protótipo de autonomia E7, arquitetura, desenho P2P).
- Sem QEMU, GGUF ou build de `agent/` como pré-requisito do gate **desta** etapa (checklist documental).
- Não depende de implementação do protocolo Rede v1 nem de Linha B real com GGUF.

## Verificação

Gate desta etapa = **checklist documental** (não `make verify-agent` novo nem alteração de código):

```bash
test -f docs/adr/0005-autonomia-v1-utilizavel.md   # ou nome fixado
test -f docs/desenho-autonomia-v1.md
grep -qiE 'recall|help|note|memória|memory|allowlist' docs/desenho-autonomia-v1.md
grep -qiE 'critério verificável|MEMORY_POLICY|AGENT_OK|verify-agent' docs/desenho-autonomia-v1.md
grep -qiE '0005|autonomia v1|desenho-autonomia' docs/architecture.md
grep -qiE 'Etapa 15|desenho|v1' docs/ambiente-autonomia-prototipo.md
# Sem diff de código de produto em agent/ runtime/ node/ kernel/ (salvo ponte doc)
```

Critério de pronto da etapa: ADR + doc de desenho coerentes com a proposta única; architecture e ponte do protótipo atualizados; sem P2P/kernel/marketplace/implementação completa.
