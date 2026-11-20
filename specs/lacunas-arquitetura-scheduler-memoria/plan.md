# Plan — Lacunas de arquitetura (scheduler / memória model-aware)

## Abordagem

1. **ADR candidata** (Task 1): fixar em `docs/adr/0003-…` a decisão estrutural — interface kernel↔runtime com classes `Weights` / `KvCache` + hints `Prefill` / `Decode`; fronteiras ADR 0001; não-objetivos.
2. **Doc de desenho** (Task 2): expandir o contrato (ciclo de vida, políticas candidatas, lacunas SLM-OS/TensorOS/AgentOS, o que fica para implementação); sem código.
3. **Pontes e fechamento documental** (Task 3): atualizar `architecture.md` (decisão aberta → desenho candidato), pontes harness/Linha B, `AGENTS.md` se couber, README avaliado.

Ordem: ADR → desenho detalhado → pontes (as pontes citam paths estáveis do ADR/doc).

## Arquivos prováveis

- `docs/adr/0003-memoria-model-aware-e-scheduler-fases.md` (nome final alinhado à Task 1)
- `docs/desenho-memoria-scheduler-nativo.md`
- `docs/architecture.md` — decisão aberta → decidida no nível desenho
- `docs/runtime-nativo-linha-b.md` e/ou `docs/harness-linha-a-b.md` — ponte honestidade
- `AGENTS.md` — ponte curta em Estrutura / docs (sem gate novo de código)
- `README.md` — só se a capa ficar enganosa sem menção ao desenho
- `specs/lacunas-arquitetura-scheduler-memoria/tasks.md` — marcar fatias

## Dependências

- Etapas 1–12 feitas (camadas, ADR 0001, harness, proxy Linha B).
- Sem QEMU, GGUF ou build de produto como pré-requisito do gate desta etapa.
- Não depende de fechar carga canônica em B.

## Verificação

Gate desta etapa = **checklist documental** (não `make verify*` novo):

```bash
test -f docs/adr/0003-memoria-model-aware-e-scheduler-fases.md   # ou nome fixado
test -f docs/desenho-memoria-scheduler-nativo.md
grep -q 'Weights\|KvCache\|Prefill\|Decode' docs/desenho-memoria-scheduler-nativo.md
grep -q '0003\|memoria-model-aware\|scheduler' docs/architecture.md
# Sem diff de código de produto em kernel/ runtime/ node/ agent/ (salvo ponte doc)
```

Critério de pronto da etapa: ADR + doc de desenho coerentes com a proposta única; architecture atualizado; hipótese **não** declarada comprovada.
