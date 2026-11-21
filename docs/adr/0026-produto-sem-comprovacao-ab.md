# ADR 0026 — Produto sem comprovação da hipótese A/B

- Status: aceita
- Data: 2026-11-21

## Contexto

O checklist do protótipo (E58) está cumprido: pilar 1 = `BLOQUEIO_FINAL` (ADR [`0022`](0022-bloqueio-final-hipotese-ab.md)), pilar 2 = `METAL_OK` (report ESP), pilar 3 = Rede/autonomia host. A decisão de produto (2026-11-21) é **não** continuar buscando `COMPROVA`/`REFUTA` da hipótese A vs B no roadmap.

## Decisão

1. **Meta de produto** daqui em diante: evoluir a **Linha B** (SO IA Livre, bare-metal, runtime nativo, Rede/autonomia) com evidência honesta (`baremetal-report`, gates existentes).
2. **Não** promover B55 nem reabrir ADR 0022 **por default**. Reabertura só com pedido explícito futuro + critérios da 0022.
3. Instrumentos A/B (`verify-harness-comparable`, etc.) permanecem no repo como **lab/histórico** — não geram etapas novas de produto.
4. **Proibido** declarar `COMPROVA` ou “hipótese vencida”.

## Consequências

- B55 arquivada (não “adiada aguardando”).
- Backlog prioriza pós-exit no report, inferência metal subset, DX de coleta.
- Narrativa: protótipo checklist **ok**; pesquisa A/B **fora do escopo de produto**.
