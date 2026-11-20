# Arquitetura

Visão inicial (sujeita a ADRs nas etapas seguintes).

## Camadas

1. **IA Livre (kernel)** — boot, memória, CPU/GPU, dispositivos, isolamento, escalonamento orientado a inferência
2. **Runtime nativo de IA** — inferência/treinamento, tensores, KV cache, backends de aceleração
3. **Ambiente de autonomia** — agentes, memória persistente, ferramentas, experimentação
4. **Rede IA Livre** — protocolo P2P comum (nós nativos e nós em SO convencional)

## Decisões preliminares

- Kernel pequeno e auditável; inteligência pesada fora do kernel
- Começar x86-64 + UEFI + QEMU; CPU antes de GPU; NVIDIA multi-GPU como alvo posterior
- Protocolo P2P independente do kernel (desenvolvível em paralelo no host)

## Hipótese a comprovar

Um SO construído só para inferência/IA aproveita melhor o hardware do que um SO de propósito geral otimizado para a mesma carga — desde que haja mecanismos próprios (memória model-aware, scheduler prefill/decode, etc.), não só o mesmo runtime sobre drivers genéricos.

## Referências próximas

AgentOS, SLM-OS, TensorOS, CLLM — estudar lacunas (GPU, multi-GPU, KV cache, multi-tenant) antes de fechar desenho.
