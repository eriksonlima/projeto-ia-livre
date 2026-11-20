# ADR 0001 — Separação kernel × runtime e P2P independente do SO

- Status: aceita
- Data: 2026-11-20

## Contexto

O Projeto IA Livre combina um sistema operacional próprio (**IA Livre**) com uma rede P2P (**Rede IA Livre**) e a exigência de que participar da rede **não** dependa de instalar o SO. Colocar toda a inteligência artificial dentro do kernel aumentaria a superfície de falha, dificultaria evolução e auditoria, e atrasaria a formação da comunidade. Amarrar o protocolo P2P ao kernel impediria nós em Linux/Windows e contradiria o manifesto.

## Decisão

1. **Kernel × runtime (e camadas superiores):** o kernel fornece mecanismos (memória, dispositivos, isolamento, escalonamento orientado a inferência). Inferência, treinamento, agentes e ferramentas ficam **fora** do kernel (runtime e ambiente de autonomia), podendo evoluir em ritmo próprio.
2. **P2P independente do SO:** o protocolo da Rede IA Livre é definido de forma que nós nativos e nós em SO convencional falem a mesma linguagem. O IA Livre é a implementação nativa de referência, não pré-requisito de participação.

## Consequências

### Positivas

- Kernel menor, mais auditável e alinhado ao manifesto
- Runtime e autonomia podem avançar sem rebuild constante do núcleo
- Comunidade pode entrar via nó em SO convencional enquanto o SO amadurece
- Protocolo P2P desenvolvível em paralelo no host (ex.: Ubuntu) antes do bootstrap completo

### Negativas

- Mais interfaces a manter entre kernel e runtime
- Risco de “só Linux + runtime” se os mecanismos nativos do kernel não forem de fato diferenciados
- Duas superfícies de entrega (SO e nó) exigem disciplina de roadmap para não fragmentar o foco
