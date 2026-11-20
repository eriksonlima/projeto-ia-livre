# Arquitetura

Visão inicial do **Projeto IA Livre**. Detalhes de implementação evoluem por etapa e ADR; este documento fixa camadas, hipótese de pesquisa e o que já está decidido vs aberto.

Princípios e governança: [`docs/manifesto.md`](manifesto.md).  
Contexto de produto: [`docs/product-context.md`](product-context.md).  
Decisão estrutural de camadas: [`docs/adr/0001-separacao-camadas-e-p2p.md`](adr/0001-separacao-camadas-e-p2p.md).

## Camadas

| # | Camada | Responsabilidade |
|---|--------|------------------|
| 1 | **IA Livre (kernel)** | Boot (UEFI), memória física/virtual, CPU e aceleradores, dispositivos, isolamento, interrupções e escalonamento orientado a inferência (ex.: distinguir prefill e decode quando houver mecanismo nativo). Kernel **pequeno e auditável**. |
| 2 | **Runtime nativo de IA** | Inferência e, depois, treinamento; tensores; KV cache; quantização; backends de aceleração. Evolui **fora** do kernel, usando os mecanismos que o kernel expõe. |
| 3 | **Ambiente de autonomia** | Agentes, memória persistente, ferramentas, experimentação e desenvolvimento de capacidades. Consome o runtime; não faz parte do núcleo. |
| 4 | **Rede IA Livre** | Protocolo P2P comum: descoberta, identidade, tarefas, conhecimento e recursos. Serve **nós nativos** (IA Livre) e **nós em SO convencional** (Linux, Windows, etc.). |

As camadas formam um ecossistema, não quatro produtos desconectados. A ordem de entrega no roadmap (kernel → runtime CPU → nó P2P) não exige que a autonomia esteja madura antes do nó.

## Hipótese de pesquisa

**Afirmação a testar:** um SO construído exclusivamente para inferência/IA pode aproveitar melhor o hardware do que um SO de propósito geral **otimizado para a mesma carga**, quando o SO próprio traz mecanismos nativos (memória model-aware, scheduler consciente de prefill/decode, integração CPU–GPU sem camadas genéricas desnecessárias, etc.).

### O que comparar

- Mesmo hardware, mesmo modelo, mesma quantização e carga de trabalho comparável.
- Linha A (referência): Linux otimizado + runtime de inferência otimizado + API.
- Linha B (projeto): IA Livre (kernel + mecanismos) + runtime nativo + API.
- Métricas candidatas: tokens/s, latência p95, RAM/VRAM por requisição, joules por milhão de tokens, tempo de carregamento, disponibilidade — sempre controlando qualidade e contexto.

### O que não assumir

- Que “ter SO próprio” vence só por existir.
- Que repetir o **mesmo** runtime e os **mesmos** drivers genéricos sobre um kernel vazio justifica o custo de um SO.
- Que multi-GPU, RDMA ou clusters já estão resolvidos no desenho atual.
- Que benchmarks de projetos bare-metal próximos (AgentOS, etc.) são prova independente sem metodologia equivalente.
- Que GPU NVIDIA/AMD está no caminho crítico da Etapa 4 (primeiro alvo é CPU/QEMU).

## Decisões tomadas

- Participar da Rede IA Livre **não** exige instalar o SO IA Livre.
- Kernel pequeno; inteligência pesada (modelos, agentes) **fora** do kernel — ver ADR 0001.
- Protocolo P2P **independente** do kernel/SO — desenvolvível em paralelo no host — ver ADR 0001.
- Bootstrap inicial: **x86-64 + UEFI + QEMU**; **CPU antes de GPU**.
- Aceleração NVIDIA multi-GPU como alvo **posterior** (após base CPU e runtime mínimo).
- Nenhuma decisão só por curiosidade técnica (manifesto).
- **Etapa 10:** primeiro mecanismo de memória no kernel UEFI — mapa + `AllocatePages`/bump sob Boot Services (sem inferência). Contrato: [`kernel-alem-do-boot.md`](kernel-alem-do-boot.md).
- **Etapa 11 (em andamento):** `ExitBootServices` + base estável (mapa owned + memória); I/O pós-exit via UART COM1. Contrato: [`kernel-pos-boot-services.md`](kernel-pos-boot-services.md).

## Decisões abertas

- Desenho fino de memória model-aware e do scheduler de inferência.
- Stack concreta do protocolo P2P (bibliotecas, transporte, identidade).
- Licenças definitivas por componente (preferência a confirmar no manifesto).
- ~~Estratégia de aceleração além de CPU~~ — **protótipo host:** CUDA canônico / Vulkan alternativa via llama.cpp (ADR 0002); GPU manager no kernel e multi-GPU continuam abertos.
- Forma e escopo do ambiente de autonomia na primeira versão utilizável.
- ~~Critérios exatos e harness do benchmark Linha A vs Linha B~~ — **harness v1 (Etapa 9):** metodologia + Linha A no host + stub Linha B em [`harness-linha-a-b.md`](harness-linha-a-b.md); prova da hipótese e runtime nativo em B continuam abertos.

## Referências próximas

Estudar como **lacunas**, não como blueprint a copiar:

| Projeto | Interesse |
|---------|-----------|
| AgentOS | Kernel bare-metal, execução em servidor |
| SLM-OS | Memória e escalonamento conscientes de modelo |
| TensorOS | Integração kernel ↔ runtime / tensores |
| CLLM | Unikernel + HTTP + caminho para inferência |

Lacunas típicas a investigar: GPU eficiente, multi-GPU, KV cache avançado, multi-tenant / muitas requisições simultâneas.

## Fronteira com Etapas 4+

| Etapa | Entrega | Esta doc |
|-------|---------|----------|
| **3** (atual) | Product-context + architecture + ADR estrutural | Feita quando os critérios do roadmap/spec forem cumpridos |
| **4** | Bootstrap kernel UEFI/QEMU (Rust), saída serial | Código começa aqui |
| **5** | Runtime mínimo de inferência em CPU | — |
| **6** | Protótipo do nó Rede IA Livre em SO convencional | — |

Nenhum bootstrap de código nesta etapa.
