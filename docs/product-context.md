# Product context

## Problema

Grandes modelos de IA concentram-se em infraestrutura proprietária e centralizada. Quem quer executar, aprender e colaborar localmente enfrenta sistemas operacionais genéricos e redes fechadas. Falta uma infraestrutura aberta, brasileira na origem, em que a IA seja finalidade do sistema — não um aplicativo grudado nele.

## Usuários

- Desenvolvedores e pesquisadores que querem contribuir com kernel, runtime ou protocolo
- Pessoas com hardware ocioso que desejam participar da Rede IA Livre sem trocar de SO
- Comunidade interessada em IA local, soberania tecnológica e colaboração P2P

## Princípios

Fonte canônica: [`docs/manifesto.md`](manifesto.md).

- Open source e sem fins lucrativos
- Participação na Rede IA Livre **não** exige instalar o SO IA Livre
- Governança descentralizada com proteções contra captura (princípios + comunidade + técnica)
- Acesso comunitário básico à inteligência compartilhada sem cobrança por token
- Nenhuma decisão só por curiosidade técnica: deve servir liberdade, autonomia, eficiência ou descentralização

## Camadas do ponto de vista do produto

Detalhe técnico: [`docs/architecture.md`](architecture.md). Em resumo, o que cada camada entrega a quem usa ou contribui:

| Camada | Valor para o usuário / contribuidor |
|--------|-------------------------------------|
| **IA Livre (kernel)** | Base controlável e auditável; hardware e isolamento pensados para IA, sem desktop genérico |
| **Runtime nativo de IA** | Executar e servir modelos com eficiência; evolui sem reescrever o núcleo |
| **Ambiente de autonomia** | Agentes, memória e ferramentas para aprender e experimentar no próprio ambiente |
| **Rede IA Livre** | Colaborar e compartilhar recursos/conhecimento **sem** precisar trocar de SO |

## Meta do protótipo (checklist)

Critério verificável dos três pilares: [`prototipo-objetivo-atingido.md`](prototipo-objetivo-atingido.md).  
**Estado (2026-11-21): checklist cumprido** (pilar 1 = `BLOQUEIO_FINAL`, pilar 2 = `METAL_OK`, pilar 3 = host ok).  
Evolução de produto: **Linha B** (SO / bare-metal / runtime nativo) — ADR [`0026`](adr/0026-produto-sem-comprovacao-ab.md). Sem buscar `COMPROVA` no roadmap.

## Não objetivos

- Desktop genérico ou compatibilidade com apps de escritório
- Substituir Linux em todos os cenários
- Cobrar tokens no acesso comunitário básico
- Exigir o SO para entrar na rede P2P
- Declarar vitória da hipótese de pesquisa (`COMPROVA`) ou reabrir A/B no roadmap sem pedido explícito

## Hipótese de pesquisa (arquivada como meta de produto)

Histórico de lab (não meta de produto — ADR 0026 / 0022):

> O IA Livre, com mecanismos nativos de gerenciamento para inferência, aproveita melhor o hardware do que um Linux otimizado rodando carga equivalente.

Instrumentos A/B permanecem no repo como lab (`INCONCLUSIVO` / `BLOQUEIO_FINAL`). **Não** geram etapas novas de produto.

## Métricas de sucesso (produto)

- SO IA Livre bootável (QEMU + metal com report ESP) e caminho de IA nativo honesto
- Comunidade capaz de contribuir e participar sem barreira de troca de SO
- Rede + autonomia utilizáveis no host; Linha B evolui com evidência (`baremetal-report`, gates)

## Estado atual (produto)

- Checklist 3 pilares **ok**; hipótese A/B **arquivada** (ADR 0026); B55 arquivada
- Kernel UEFI + gates QEMU; obs GOP; GPU nativo sintético; ABI mínima v1 (`ABI_OK`)
- Runtime host (CPU/GPU) + Linha B subset (`TOKENS_PER_S` medidos; espécie ≠ canônica — lab)
- Agente: allowlist `note`/`recall`/`help`/`calc` + REPL + `read_local` + consumo evidência nativa
- Rede: v1 + bootstrap + mDNS + TASK + KNOW + relay intro; TCP guest inviável (bridge E52)
- Path metal: SFS full (E63); **`METAL_OK`** via report ESP (E73)
- Bare-metal: artefato ESP + guia/release USB; canal padrão = report (ADR 0025)
- GPU host: shard + `host_multi` (skip se &lt;2 devices); guest passthrough skip sem VFIO

Glossário: [`glossario.md`](glossario.md). Detalhe técnico: [`architecture.md`](architecture.md). Operacional: `AGENTS.md`.
