# Arquitetura

Visão do **Projeto IA Livre**. Detalhes evoluem por etapa e ADR; este documento fixa camadas e o que está decidido vs aberto (**pós-ADR 0027**).

Princípios: [`docs/manifesto.md`](manifesto.md).  
Produto: [`docs/product-context.md`](product-context.md).  
Camadas: [`docs/adr/0001-separacao-camadas-e-p2p.md`](adr/0001-separacao-camadas-e-p2p.md).  
Produto Linux: [`docs/adr/0027-produto-linux-ia-nativo.md`](adr/0027-produto-linux-ia-nativo.md).  
Glossário: [`glossario.md`](glossario.md).

## Camadas

| # | Camada | Responsabilidade |
|---|--------|------------------|
| 1 | **IA Livre (Linux IA-nativo)** | SO TTY-first sobre **kernel Linux** customizado/afinado para LLM (shell, configs, isolamento). Sem desktop genérico. |
| 2 | **Runtime de IA** | Inferência (e depois treino); GGUF; backends. Userspace: `runtime/` (llama.cpp). Lab histórico: `runtime-native/` freestanding. |
| 3 | **Ambiente de autonomia** | Agentes, memória, ferramentas. Consome o runtime; **não** exige o SO (ADR 0001). |
| 4 | **Rede IA Livre** | P2P: descoberta, identidade, tarefas, conhecimento. Nós no SO IA Livre **e** em SO convencional. |

## Decisão de produto (ADR 0027)

- **Canônico:** Linux IA-nativo (Linha A ampliada) — imagem, tuning, evolutivamente patches do kernel Linux.
- **Arquivado (não produto):** Linha B UEFI freestanding / harness B / ESP bare-metal como caminho de uso.
- Sem meta `COMPROVA` (ADR [`0026`](adr/0026-produto-sem-comprovacao-ab.md)).

## Hipótese de pesquisa (lab)

Afirmação histórica A vs B: **`BLOQUEIO_FINAL`** (ADR [`0022`](adr/0022-bloqueio-final-hipotese-ab.md)). Fora do roadmap de produto.

## Decisões tomadas (resumo)

- Rede / autonomia **não** exigem o SO IA Livre (ADR 0001).
- Produto = Linux TTY + stack `runtime` / `agent` / `node` (ADR 0027).
- Runtime host CPU/GPU (E5/E8); autonomia REPL + tools; Rede v1 + bootstrap/mDNS/TASK/KNOW/relay.
- Tuning LLM-nativo: perfil tipo `A_otimizada` como default do SO (hugepages, isolcpus, …) — em evolução.
- Kernel Linux custom (defconfig/patches model-aware): **aberto**, após imagem bootável.
- **Lab arquivado:** kernel UEFI + `runtime-native` + bare-metal ESP + gates associados (código pode permanecer).
- Licenças Apache-2.0 (E17). Checklist protótipo E58 cumprido.

## Decisões abertas (reais)

| Tema | Estado honesto |
|------|----------------|
| Imagem live/instalável Linux IA Livre | Em construção (backlog) |
| Kernel Linux defconfig/patches IA-nativos | Depois da imagem bootável |
| DHT / NAT avançado | Adiado; relay intro ≠ DHT |
| Inferência multi-GPU host plena (llama) | Além de `host_multi`; sem fingir TOKENS |
| Hipótese A/B / Linha B UEFI | **Arquivadas** como produto |

## Estado do mapa

| Faixa | Status |
|-------|--------|
| Stack host runtime/agent/node | Feito |
| Checklist protótipo E58 | Ok |
| Produto Linux IA-nativo (ADR 0027) | **Direção ativa** |
| Imagem distro + smoke QEMU | Próximo |
| Linha B UEFI / harness B | **Arquivada** (lab) |

## Referências próximas

Estudar como **lacunas**: afinidade de memória/scheduler no Linux, GPU eficiente, multi-tenant — sem blueprint de SO UEFI.
