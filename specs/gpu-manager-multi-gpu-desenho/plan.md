# Plan — GPU manager no kernel / multi-GPU (desenho)

## Abordagem

1. **ADR candidata** (Task 1): fixar em `docs/adr/0006-…` a decisão estrutural — fronteira host (ADR 0002) vs GPU manager nativo; escopo mínimo do manager (enum / afinidade / placement); multi-GPU preferido = pipeline/layer sharding; complementaridade com ADR 0001 e 0003; não-objetivos.
2. **Doc de desenho** (Task 2): expandir contrato kernel↔runtime, tabela fronteira host×nativo, ciclo Prefill/Decode + devices, alternativas multi-GPU nomeadas, honestidade vs Etapa 8; sem código.
3. **Pontes e fechamento documental** (Task 3): atualizar `architecture.md` (aberto → desenho candidato), pontes em ADR 0002 e/ou métricas GPU, `AGENTS.md` se couber, README avaliado.

Ordem: ADR → desenho detalhado → pontes (as pontes citam paths estáveis do ADR/doc).

## Arquivos prováveis

- `docs/adr/0006-gpu-manager-multi-gpu.md` (nome final alinhado à Task 1)
- `docs/desenho-gpu-manager-multi-gpu.md`
- `docs/architecture.md` — decisão aberta GPU manager/multi-GPU → decidida no nível desenho
- `docs/adr/0002-aceleracao-gpu-host-llama-cpp.md` e/ou `docs/runtime-inferencia-gpu-metricas.md` — ponte “host ≠ manager”
- `docs/desenho-memoria-scheduler-nativo.md` — ponte opcional de complementaridade com 0003
- `AGENTS.md` — ponte curta em Estrutura / docs (sem gate novo de código)
- `README.md` — só se a capa ficar enganosa sem menção ao desenho
- `specs/gpu-manager-multi-gpu-desenho/tasks.md` — marcar fatias

## Dependências

- Etapas 1–15 feitas no que importa (camadas, ADR 0001–0005, protótipo GPU host Etapa 8).
- Sem QEMU, GGUF ou build de produto como pré-requisito do gate desta etapa.
- Não depende de B12 (harness GPU) nem de implementação Linha B com aceleradores.

## Verificação

Gate desta etapa = **checklist documental** (não `make verify*` novo):

```bash
test -f docs/adr/0006-gpu-manager-multi-gpu.md   # ou nome fixado
test -f docs/desenho-gpu-manager-multi-gpu.md
grep -qiE 'GPU manager|multi-GPU|pipeline|layer shard' docs/desenho-gpu-manager-multi-gpu.md
grep -q '0006\|gpu-manager\|multi-GPU' docs/architecture.md
# Sem diff de código de produto em kernel/ runtime/ node/ agent/ (salvo ponte doc)
```

Critério de pronto da etapa: ADR + doc de desenho coerentes com a proposta única; architecture atualizado; ADR 0002 **não** invalidado; implementação **não** declarada feita.
