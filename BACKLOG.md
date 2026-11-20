# Backlog

Fila de demandas **ainda não** comprometidas no roadmap. Ordem = prioridade (topo primeiro).

Fonte: ideias do usuário, lacunas de `docs/architecture.md` / `docs/product-context.md`, ou pedidos fora da etapa atual.
Este arquivo é **canônico**. Espelho GitHub é **best-effort** (label `backlog`); se `gh` falhar, o item permanece só aqui e a fatia não trava.
Promoção para `ROADMAP.md` exige **confirmação explícita** (ver `.cursor/rules/backlog-do-projeto.mdc` / skill `atualizar-backlog`).

## Abertas

### B7 — Kernel pós-Boot Services (ExitBootServices + base mínima)

- Origem: análise 2026-11-20; Etapa 10 sob Boot Services; fora de escopo em `docs/kernel-alem-do-boot.md` (ExitBoot / MMU / heap); ponte típica para B5.
- Pronto quando sugerido: caminho documentado e verificável no UEFI/QEMU para sair de Boot Services (ou equivalente mínimo) com base estável (mapa preservado / memória utilizável), gate serial — ainda sem inferência no kernel.
- Issue: [#13](https://github.com/eriksonlima/projeto-ia-livre/issues/13)

### B5 — Runtime nativo / Linha B real (mínimo)

- Origem: seed pós Etapas 1–9 (confirmação do usuário); harness Etapa 9 deixa Linha B como stub.
- Pronto quando sugerido: caminho documentado e verificável para a carga canônica do harness emitir `IA_LIVRE_HARNESS_*` com `LINE=B` no ambiente IA Livre (ou stub honestamente substituído por execução real mínima); sem fingir hipótese comprovada.
- Issue: [#11](https://github.com/eriksonlima/projeto-ia-livre/issues/11)

### B6 — Lacunas de arquitetura (scheduler / memória model-aware)

- Origem: seed pós Etapas 1–9; lacunas abertas em `docs/architecture.md`.
- Pronto quando sugerido: desenho (doc/ADR) do mecanismo nativo candidato que diferencia Linha B da A — escopo de desenho, não implementação completa.
- Issue: [#12](https://github.com/eriksonlima/projeto-ia-livre/issues/12)

### B8 — Protocolo P2P além do protótipo (stack / identidade)

- Origem: análise 2026-11-20; decisão aberta em `docs/architecture.md`; fora de escopo de `docs/rede-ia-livre-prototipo.md`.
- Pronto quando sugerido: escolha documentada (ADR/doc) da stack candidata (transporte, identidade, descoberta além de HELLO/MSG/ACK) e fronteira do próximo protótipo — sem marketplace nem integração runtime/kernel.
- Issue: [#14](https://github.com/eriksonlima/projeto-ia-livre/issues/14)

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
