# Backlog

Fila de demandas **ainda não** comprometidas no roadmap. Ordem = prioridade (topo primeiro).

Fonte: ideias do usuário, lacunas de `docs/architecture.md` / `docs/product-context.md`, ou pedidos fora da etapa atual.
Este arquivo é **canônico**. Espelho GitHub é **best-effort** (label `backlog`); se `gh` falhar, o item permanece só aqui e a fatia não trava.
Promoção para `ROADMAP.md` é **autônoma** (topo das Abertas quando o roadmap esvazia / etapa fecha / “continuar”) — ver `.cursor/rules/backlog-do-projeto.mdc` / skill `atualizar-backlog`. Com agentes em paralelo: sync + claim check antes de promover (`.cursor/rules/agentes-em-paralelo.mdc`). Não inventar etapa fora deste arquivo.

## Abertas

### B9 — Ambiente de autonomia além do protótipo (v1 utilizável)

- Origem: análise 2026-11-20; decisão aberta em `docs/architecture.md`; protótipo E7 = loop + `note` + JSONL.
- Pronto quando sugerido: escopo documentado da primeira versão utilizável da camada 3 e critério verificável mínimo — ainda no host, sem exigir o SO IA Livre.
- Issue: [#15](https://github.com/eriksonlima/projeto-ia-livre/issues/15)

### B10 — GPU manager no kernel / multi-GPU (desenho)

- Origem: análise 2026-11-20; `docs/architecture.md` + ADR 0002 (host fechado; manager/multi-GPU abertos).
- Pronto quando sugerido: desenho (doc/ADR) do escopo candidato — fronteira vs aceleração host; desenho, não implementação completa.
- Issue: [#16](https://github.com/eriksonlima/projeto-ia-livre/issues/16)

### B11 — Licenças definitivas por componente

- Origem: análise 2026-11-20; `docs/manifesto.md` (preferência a confirmar) + decisão aberta em `docs/architecture.md`.
- Pronto quando sugerido: licença por componente (kernel, runtime, node, agent, docs) registrada no repositório, alinhada ao manifesto.
- Issue: [#17](https://github.com/eriksonlima/projeto-ia-livre/issues/17)

### B12 — Evolução do harness (Linha A otimizada / perfil GPU)

- Origem: análise 2026-11-20; limitações explícitas em `docs/harness-linha-a-b.md` (A sem tuning; GPU fora do v1).
- Pronto quando sugerido: metodologia documentada para «Linux otimizado» na A e/ou perfil GPU espelhado A/B; gate só se houver execução real.
- Issue: [#18](https://github.com/eriksonlima/projeto-ia-livre/issues/18)

## Promovidas / arquivadas

### B8 — Protocolo P2P além do protótipo (stack / identidade)

- Promovido para Etapa 14 do roadmap (promoção autônoma).
- Issue: [#14](https://github.com/eriksonlima/projeto-ia-livre/issues/14)
- Etapa: [Etapa 14 — Protocolo P2P além do protótipo (stack / identidade)](ROADMAP.md)

### B6 — Lacunas de arquitetura (scheduler / memória model-aware)

- Promovido para Etapa 13 do roadmap com confirmação explícita.
- Issue: [#12](https://github.com/eriksonlima/projeto-ia-livre/issues/12)
- Etapa: [Etapa 13 — Lacunas de arquitetura (scheduler / memória model-aware)](ROADMAP.md)

### B5 — Runtime nativo / Linha B real (mínimo)

- Promovido para Etapa 12 do roadmap com confirmação explícita.
- Issue: [#11](https://github.com/eriksonlima/projeto-ia-livre/issues/11)
- Etapa: [Etapa 12 — Runtime nativo / Linha B real (mínimo)](ROADMAP.md)

### B7 — Kernel pós-Boot Services (ExitBootServices + base mínima)

- Promovido para Etapa 11 do roadmap com confirmação explícita.
- Issue: [#13](https://github.com/eriksonlima/projeto-ia-livre/issues/13)
- Etapa: [Etapa 11 — Kernel pós-Boot Services](ROADMAP.md)

### B4 — Kernel além do boot

- Promovido para Etapa 10 do roadmap com confirmação explícita.
- Issue: [#10](https://github.com/eriksonlima/projeto-ia-livre/issues/10)
- Etapa: [Etapa 10 — Kernel além do boot](ROADMAP.md)

### B3 — Harness da hipótese Linha A vs Linha B

- Promovido para Etapa 9 do roadmap com confirmação explícita.
- Issue: [#9](https://github.com/eriksonlima/projeto-ia-livre/issues/9)
- Etapa: [Etapa 9 — Harness da hipótese Linha A vs Linha B](ROADMAP.md)

### B2 — Aceleração além de CPU (GPU)

- Promovido para Etapa 8 do roadmap com confirmação explícita.
- Issue: [#8](https://github.com/eriksonlima/projeto-ia-livre/issues/8)
- Etapa: [Etapa 8 — Aceleração além de CPU (GPU)](ROADMAP.md)

### B1 — Ambiente de autonomia (camada 3)

- Promovido para Etapa 7 do roadmap com confirmação explícita.
- Issue: [#7](https://github.com/eriksonlima/projeto-ia-livre/issues/7)
- Etapa: [Etapa 7 — Ambiente de autonomia (camada 3)](ROADMAP.md)
