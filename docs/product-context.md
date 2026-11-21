# Product context

## Problema

Grandes modelos de IA concentram-se em infraestrutura proprietária e centralizada. Quem quer executar, aprender e colaborar localmente enfrenta sistemas operacionais genéricos e redes fechadas. Falta uma infraestrutura aberta, brasileira na origem, em que a IA seja finalidade do sistema — não um aplicativo grudado nele.

## Usuários

- Desenvolvedores e pesquisadores que querem contribuir com kernel Linux afinado, runtime ou protocolo
- Pessoas com hardware ocioso que desejam participar da Rede IA Livre sem trocar de SO
- Operadores que querem um SO TTY com shell, configs livres e qualquer GGUF local

## Princípios

Fonte canônica: [`docs/manifesto.md`](manifesto.md).

- Open source e sem fins lucrativos
- Participação na Rede IA Livre **não** exige instalar o SO IA Livre
- Governança descentralizada com proteções contra captura (princípios + comunidade + técnica)
- Acesso comunitário básico à inteligência compartilhada sem cobrança por token
- Nenhuma decisão só por curiosidade técnica: deve servir liberdade, autonomia, eficiência ou descentralização

## Camadas do ponto de vista do produto

Detalhe técnico: [`docs/architecture.md`](architecture.md).

| Camada | Valor para o usuário / contribuidor |
|--------|-------------------------------------|
| **IA Livre (Linux IA-nativo)** | SO TTY-first customizado para LLM (shell, configs, tuning/kernel Linux); sem desktop genérico |
| **Runtime de IA** | Executar GGUF com eficiência (`ia-livre-runtime` / llama.cpp); evolui sem reescrever o kernel |
| **Ambiente de autonomia** | Agentes, memória e ferramentas no próprio SO (ou host convencional) |
| **Rede IA Livre** | Colaborar P2P **sem** precisar do SO IA Livre |

## Meta do protótipo (checklist)

Critério histórico dos três pilares: [`prototipo-objetivo-atingido.md`](prototipo-objetivo-atingido.md) — **cumprido**.  
**Produto atual (ADR [`0027`](adr/0027-produto-linux-ia-nativo.md)):** SO = **Linux IA-nativo**; Linha B UEFI **arquivada**. Sem `COMPROVA` (ADR [`0026`](adr/0026-produto-sem-comprovacao-ab.md)).

## Não objetivos

- Desktop genérico ou compatibilidade com apps de escritório
- Substituir Linux em todos os cenários (somos um Linux especializado)
- Cobrar tokens no acesso comunitário básico
- Exigir o SO para entrar na rede P2P
- Novas etapas de produto na Linha B (UEFI freestanding)
- Declarar vitória `COMPROVA` da hipótese A/B

## Hipótese de pesquisa (arquivada)

Lab histórico (ADR 0026 / 0022). Instrumentos A/B no repo ≠ meta de produto. Linha B UEFI ≠ caminho de uso.

## Métricas de sucesso (produto)

- Imagem Linux IA Livre bootável (QEMU + USB) com TTY/shell
- Runtime/agent/node no SO; qualquer GGUF via config
- Tuning/kernel Linux progressivamente mais “nativo” para inferência
- Rede utilizável no SO e em nós convencionais (ADR 0001)

## Estado atual (produto)

- Direção: **Linux IA-nativo** (ADR 0027); Linha B **arquivada**
- Stack host + scaffold distro (E77–81): config/GGUF, tune, smoke userspace, USB tarball
- **Próximo (Abertas):** B77 rootfs Debian bootável em QEMU → … → B91 checklist `verify-produto-linux` (ver [`BACKLOG.md`](../BACKLOG.md))
- Artefatos UEFI/bare-metal = lab histórico (gates podem permanecer)

Glossário: [`glossario.md`](glossario.md). Detalhe técnico: [`architecture.md`](architecture.md). Operacional: `AGENTS.md`.
