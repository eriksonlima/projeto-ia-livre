---
name: fechar-etapa-documental-adr
description: >-
  Fecha etapa só-documental do Projeto IA Livre: ADR (ou doc metodológica) +
  desenho/checklist + pontes em architecture/ADRs irmãos/AGENTS, sem código de
  produto. Use em etapas de desenho (ex. GPU manager, protocolo, autonomia v1,
  perfis harness) ou ao pedir “ADR + desenho + pontes”.
disable-model-invocation: true
---

# Fechar etapa documental (ADR + desenho + pontes)

## Quando

- Etapa do roadmap é **só desenho / metodologia** (sem implementar `kernel/`/`runtime/`/…)
- Spec tem o padrão de 3 fatias: ADR → doc de desenho → pontes + fechamento
- Exemplos: ADR 0003–0007, GPU manager, protocolo Rede, autonomia v1, perfis harness

## Ordem das fatias (uma por vez)

1. **ADR** em `docs/adr/NNNN-….md` (template `docs/adr/0000-template.md`)
   - Status aceita **no nível desenho** (não fingir implementação)
   - Fronteiras explícitas (o que fica no host vs nativo; o que **não** decide)
2. **Desenho / metodologia** em `docs/desenho-….md` ou doc dedicada (ex. harness perfis)
   - Contrato/checklist repetível; não-objetivos; “ainda não implementado” se couber
3. **Pontes + gate**
   - `docs/architecture.md`: marcar **decidido no desenho**, prova/implementação abertas
   - Pontes mínimas em ADRs/docs irmãos relevantes
   - `AGENTS.md` só se a estrutura pública precisar do ponteiro
   - Decisão de gate explícita: gate novo **ou** gate existente permanece (sem skip disfarçado)
   - README: avaliar `readme-por-fatia` (muitas vezes sem mudança — registrar)

## Pronto / não fazer

- Sem código de produto nesta etapa (salvo se a spec pedir script de medição)
- Não marcar a etapa `feita` na última task de pontes — deixar para revisão + roadmap
- Não inventar métricas / prova (ex.: não emitir `TOKENS_PER_S` GGUF na Linha B proxy)
- Não duplicar o corpo da ADR na architecture — link + uma frase de status
- Gate de verificação: checklist do `Pronto quando` + links/arquivos existem (sem inventar `make` novo)

## Referências

- Template ADR: `docs/adr/0000-template.md`
- Specs recentes: `specs/gpu-manager-multi-gpu-desenho/`, `specs/evolucao-harness-linha-a-gpu/`
- Gate harness (se a etapa tocar A/B): skill `verificar-harness` — distinto desta skill
