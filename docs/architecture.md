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
- Aceleração multi-GPU / GPU manager **nativo**: alvo **posterior** à base CPU e ao protótipo host (ADR 0002); desenho Etapa 16 (ADR 0006); **stub host** verificável (Etapa 25) — [`gpu-manager-prototipo-host.md`](gpu-manager-prototipo-host.md) — **≠** manager nativo.
- Nenhuma decisão só por curiosidade técnica (manifesto).
- **Etapa 10:** primeiro mecanismo de memória no kernel UEFI — mapa + `AllocatePages`/bump sob Boot Services (sem inferência). Contrato: [`kernel-alem-do-boot.md`](kernel-alem-do-boot.md).
- **Etapa 11:** `ExitBootServices` + base estável (mapa owned + memória); I/O pós-exit via UART COM1. Contrato: [`kernel-pos-boot-services.md`](kernel-pos-boot-services.md).
- **Etapa 12:** Linha B mínima = proxy pós-ExitBoot (não TinyLlama); hipótese **não** comprovada. Contrato: [`runtime-nativo-linha-b.md`](runtime-nativo-linha-b.md).
- **Etapa 13:** desenho candidato memória model-aware + scheduler por fases (ADR 0003).
- **Etapa 19:** implementação mínima no kernel pós-ExitBoot (`Weights`/`KvCache` + Prefill/Decode + quantum) — [`memoria-scheduler-impl-minima.md`](memoria-scheduler-impl-minima.md); **sem** GGUF; hipótese **não** comprovada.
- **Etapa 20:** runtime/shim falando o contrato nativo + harness B com `HARNESS_CONTRACT_*` — [`runtime-contrato-nativo.md`](runtime-contrato-nativo.md); **sem** GGUF em B; hipótese **não** comprovada.
- **Etapa 21:** integração harness↔contrato (`CONTRACT_READY=1`) + bloqueio honesto `no_gguf_path` (sem loader); proxy permanece; hipótese **não** comprovada. Spec: [`../specs/carga-gguf-linha-b/`](../specs/carga-gguf-linha-b/).
- **Etapa 26:** loader GGUF nativo mínimo via ESP pré-ExitBoot (ADR [`0008`](adr/0008-loader-gguf-esp-pre-exitboot.md)) — `GGUF_NATIVE_LOADER=esp_header`; **sem** `TOKENS_PER_S` em B; hipótese **não** comprovada. Spec: [`../specs/loader-gguf-nativo-linha-b/`](../specs/loader-gguf-nativo-linha-b/).
- **Etapa 14:** desenho stack Rede IA Livre v1 (ADR 0004) — **sem** implementação no `node/`.
- **Etapa 15:** escopo autonomia v1 (ADR 0005) — **sem** implementação no `agent/`.
- **Etapa 16:** desenho GPU manager + multi-GPU (ADR 0006) — doc; stub host = Etapa 25 (não nativo).
- **Etapa 25:** stub host GPU manager (enum/placement/shard doc) — [`gpu-manager-prototipo-host.md`](gpu-manager-prototipo-host.md); `make verify-gpu-manager`; **sem** `kernel/`.
- **Etapa 18:** metodologia harness A otimizada / perfil GPU — [`harness-perfis-a-otimizada-gpu.md`](harness-perfis-a-otimizada-gpu.md); hipótese **não** comprovada.

## Decisões abertas

- ~~Desenho fino de memória model-aware e do scheduler de inferência~~ — **decidido no nível desenho (Etapa 13):** classes `Weights`/`KvCache` + hints Prefill/Decode — ADR [`0003`](adr/0003-memoria-model-aware-e-scheduler-fases.md) + [`desenho-memoria-scheduler-nativo.md`](desenho-memoria-scheduler-nativo.md). ~~Implementação mínima~~ — **Etapa 19:** [`memoria-scheduler-impl-minima.md`](memoria-scheduler-impl-minima.md). Runtime falando o contrato e prova da hipótese continuam **abertas**.
- ~~Stack concreta do protocolo P2P (bibliotecas, transporte, identidade)~~ — **decidida no nível desenho (Etapa 14):** TCP+UDP, ed25519/`PeerId`, HELLO assinado + IDENT — ADR [`0004`](adr/0004-stack-protocolo-rede-ia-livre.md) + [`desenho-protocolo-rede-ia-livre.md`](desenho-protocolo-rede-ia-livre.md). **Implementação continua aberta.**
- ~~Licenças definitivas por componente~~ — **decididas (Etapa 17):** Apache-2.0 para kernel, runtime, node, agent e docs — ADR [`0007`](adr/0007-licencas-por-componente.md) + [`LICENSE`](../LICENSE). Deps de terceiros: [`licencas-terceiros.md`](licencas-terceiros.md).
- ~~Estratégia de aceleração além de CPU~~ — **protótipo host (Etapa 8 / ADR 0002):** CUDA canônico / Vulkan alternativa via llama.cpp (single-GPU). ~~GPU manager no kernel e multi-GPU~~ — **desenho (Etapa 16 / ADR 0006)** + **stub host (Etapa 25)** — [`gpu-manager-prototipo-host.md`](gpu-manager-prototipo-host.md). **Manager nativo e multi-GPU real continuam abertos.** Host stub ≠ manager nativo ≠ prova A vs B.
- ~~Forma e escopo do ambiente de autonomia na primeira versão utilizável~~ — **decidido no nível desenho (Etapa 15):** host, `--prompt` one-shot, allowlist `note`/`recall`/`help`, política N últimas entradas — ADR [`0005`](adr/0005-autonomia-v1-utilizavel.md) + [`desenho-autonomia-v1.md`](desenho-autonomia-v1.md). **Implementação continua aberta.**
- ~~Critérios exatos e harness do benchmark Linha A vs Linha B~~ — **harness v1 (Etapa 9)** + **Linha B mínima (Etapa 12):** proxy pós-ExitBoot ([`runtime-nativo-linha-b.md`](runtime-nativo-linha-b.md)); **metodologia de perfis (Etapa 18):** A «Linux otimizado» + GPU espelhado A/B — [`harness-perfis-a-otimizada-gpu.md`](harness-perfis-a-otimizada-gpu.md). Etapa 21: bloqueio `no_gguf_path`. **Etapa 26:** loader ESP cabeçalho (`esp_header`) — ainda **sem** geração/`TOKENS_PER_S` em B. **Prova** da hipótese continua **aberta** até inferência canônica em B.

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
