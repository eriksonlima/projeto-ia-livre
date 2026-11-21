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

Critério verificável dos três pilares (hipótese A/B; USB/metal; Rede+autonomia sem exigir SO): [`prototipo-objetivo-atingido.md`](prototipo-objetivo-atingido.md). Celebrar só com evidência.

## Não objetivos

- Desktop genérico ou compatibilidade com apps de escritório
- Substituir Linux em todos os cenários
- Cobrar tokens no acesso comunitário básico
- Exigir o SO para entrar na rede P2P
- Declarar vitória da hipótese de pesquisa sem benchmark comparável

## Hipótese de pesquisa (métrica central)

Queremos **comprovar ou refutar**, com método justo:

> O IA Livre, com mecanismos nativos de gerenciamento para inferência, aproveita melhor o hardware do que um Linux otimizado rodando carga equivalente.

- **Comparar:** mesmo hardware, modelo, quantização e carga; Linha A (Linux + runtime otimizado) vs Linha B (IA Livre + runtime nativo). Ver architecture, o harness v1 em [`harness-linha-a-b.md`](harness-linha-a-b.md) e o instrumento de veredito (Etapa 22) em [`harness-a-b-comparavel.md`](harness-a-b-comparavel.md).
- **Não conta como prova:** só empilhar o mesmo runtime em um kernel vazio; números anedóticos sem baseline equivalente; assumir ganho multi-GPU antes de existir o mecanismo; tratar B proxy (`PROXY_MS`) como se fosse `TOKENS_PER_S`.

## Métricas de sucesso

- Hipótese documentada e, nas etapas de runtime/benchmark, **comparável** (IA Livre vs Linux otimizado)
- Comunidade capaz de contribuir e participar sem barreira de troca de SO
- Entregas progressivas: boot QEMU → inferência CPU → nó P2P → autonomia → caminhos bare-metal/GPU — ver [`architecture.md`](architecture.md)

## Estado atual (produto)

- Kernel UEFI + gates QEMU; obs GOP; GPU nativo sintético; ABI mínima v1 (`ABI_OK`)
- Runtime host (CPU/GPU) + Linha B subset (`TOKENS_PER_S` medidos; espécie ≠ canônica)
- Agente: allowlist `note`/`recall`/`help`/`calc` + REPL + `read_local` + consumo evidência nativa (`NATIVE_CONSUME_*`)
- Rede: v1 + bootstrap + mDNS + TASK + KNOW + relay intro; TCP guest inviável (bridge E52)
- Harness A vs B: **INCONCLUSIVO** / teto; pilar 1 em **`BLOQUEIO_FINAL`** (ADR [`0022`](adr/0022-bloqueio-final-hipotese-ab.md)) — sem `COMPROVA` fingido
- Path metal: SFS full (E63); `METAL_OK` pendente de log PC
- Bare-metal: artefato ESP + guia/release USB (QEMU ≠ PC real)
- GPU host: shard + `host_multi` (skip se &lt;2 devices); guest passthrough skip sem VFIO

Glossário: [`glossario.md`](glossario.md). Detalhe técnico: [`architecture.md`](architecture.md). Operacional: `AGENTS.md`.
