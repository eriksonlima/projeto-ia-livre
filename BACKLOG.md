# Backlog

Fila de demandas **ainda não** comprometidas no roadmap. Ordem = prioridade (topo primeiro).

Fonte: ideias do usuário, lacunas de `docs/architecture.md` / `docs/product-context.md`, ou pedidos fora da etapa atual.
Este arquivo é **canônico**. Espelho GitHub é **best-effort** (label `backlog`); se `gh` falhar, o item permanece só aqui e a fatia não trava.
Promoção para `ROADMAP.md` é **autônoma** (topo das Abertas quando o roadmap esvazia / etapa fecha / “continuar”) — ver `.cursor/rules/backlog-do-projeto.mdc` / skill `atualizar-backlog`. Com agentes em paralelo: sync + claim check antes de promover (`.cursor/rules/agentes-em-paralelo.mdc`). Não inventar etapa fora deste arquivo.

## Abertas

### B15 — Carga GGUF canônica na Linha B (mínimo honesto)

- Issue: [#21](https://github.com/eriksonlima/projeto-ia-livre/issues/21)
- Origem: `docs/runtime-nativo-linha-b.md` / architecture (GGUF em B aberto)
- Notas: caminho mínimo da carga canônica do harness em B (QEMU/IA Livre). Depende de B13/B14.
- Pronto quando (candidato): métricas B em espécie comparáveis às de A, ou bloqueio honesto documentado.

### B16 — Harness A vs B comparável (prova ou refutação da hipótese)

- Issue: [#22](https://github.com/eriksonlima/projeto-ia-livre/issues/22)
- Origem: hipótese central (product-context); Etapas 9/12/18 = metodologia, não prova
- Notas: corrida lado a lado mesmo modelo/quantização/carga; resultado comprova, refuta ou inconclusivo. Depende de B15.
- Pronto quando (candidato): corrida reproduzível documentada; sem vitória sem evidência.

### B17 — Protocolo Rede IA Livre v1 (impl. em node/)

- Issue: [#23](https://github.com/eriksonlima/projeto-ia-livre/issues/23)
- Origem: Etapa 14 / ADR 0004; `node/` ainda é protótipo E6
- Notas: ed25519/PeerId, HELLO assinado, IDENT, MSG/ACK, PING/PONG; sem libp2p/NAT/DHT; independente do SO.
- Pronto quando (candidato): contratos do desenho em `node/` + gate `verify-node` (ou extensão).

### B18 — Autonomia v1 utilizável (impl. em agent/)

- Issue: [#24](https://github.com/eriksonlima/projeto-ia-livre/issues/24)
- Origem: Etapa 15 / ADR 0005; `agent/` ainda é protótipo E7
- Notas: `--prompt`, allowlist `note`/`recall`/`help`, política N=8; host only.
- Pronto quando (candidato): prova v1 com ≥2 ferramentas + marcadores de política; `verify-agent` preservado/estendido.

### B19 — GPU manager / multi-GPU (protótipo mínimo)

- Issue: [#25](https://github.com/eriksonlima/projeto-ia-livre/issues/25)
- Origem: Etapa 16 / ADR 0006; E8 = host GPU ≠ manager nativo
- Notas: enum/afinidade/placement e/ou shard documentado; posterior à trilha da hipótese.
- Pronto quando (candidato): caminho verificável; skip/gate honesto; sem prova A vs B via multi-GPU.

## Promovidas / arquivadas

### B14 — Runtime falando o contrato nativo (além do proxy Linha B)

- Promovido para Etapa 20 do roadmap (espelho GitHub `roadmap`/`status:pendente`; alinhamento pós-Etapa 19 — branch `etapa-b14-runtime-contrato`).
- Issue: [#20](https://github.com/eriksonlima/projeto-ia-livre/issues/20)
- Etapa: [Etapa 20 — Runtime falando o contrato nativo (além do proxy Linha B)](ROADMAP.md)

### B13 — Memória model-aware + scheduler por fases (impl. mínima)

- Promovido para Etapa 19 do roadmap (promoção autônoma após “continuar”; etapas 1–18 feitas).
- Issue: [#19](https://github.com/eriksonlima/projeto-ia-livre/issues/19)
- Etapa: [Etapa 19 — Memória model-aware + scheduler por fases (impl. mínima)](ROADMAP.md)

### B12 — Evolução do harness (Linha A otimizada / perfil GPU)

- Promovido para Etapa 18 do roadmap (promoção autônoma após Etapa 17).
- Issue: [#18](https://github.com/eriksonlima/projeto-ia-livre/issues/18)
- Etapa: [Etapa 18 — Evolução do harness (Linha A otimizada / perfil GPU)](ROADMAP.md)

### B11 — Licenças definitivas por componente

- Promovido para Etapa 17 do roadmap (promoção autônoma após Etapa 16).
- Issue: [#17](https://github.com/eriksonlima/projeto-ia-livre/issues/17)
- Etapa: [Etapa 17 — Licenças definitivas por componente](ROADMAP.md)

### B10 — GPU manager no kernel / multi-GPU (desenho)

- Promovido para Etapa 16 do roadmap (promoção autônoma após “continuar”).
- Issue: [#16](https://github.com/eriksonlima/projeto-ia-livre/issues/16)
- Etapa: [Etapa 16 — GPU manager no kernel / multi-GPU (desenho)](ROADMAP.md)

### B9 — Ambiente de autonomia além do protótipo (v1 utilizável)

- Promovido para Etapa 15 do roadmap (promoção autônoma após Etapa 14).
- Issue: [#15](https://github.com/eriksonlima/projeto-ia-livre/issues/15)
- Etapa: [Etapa 15 — Ambiente de autonomia além do protótipo (v1 utilizável)](ROADMAP.md)

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
