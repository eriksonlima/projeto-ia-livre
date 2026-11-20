# Desenho — Memória model-aware e scheduler por fases

Proposta candidata que diferencia a **Linha B** (IA Livre + mecanismos) da **Linha A** (Linux genérico + runtime).  
**Nível:** desenho (Etapa 13). **Não** implementação. **Não** prova da hipótese.

ADR: [`docs/adr/0003-memoria-model-aware-e-scheduler-fases.md`](adr/0003-memoria-model-aware-e-scheduler-fases.md).  
ADR estrutural: [`docs/adr/0001-separacao-camadas-e-p2p.md`](adr/0001-separacao-camadas-e-p2p.md).

## Motivação vs Linha A

No Linux de propósito geral, pesos e KV competem como heap anônimo; o kernel não sabe se a CPU está em **prefill** (compute-bound, bursts) ou **decode** (latência por token, KV quente).  
No IA Livre, o contrato nativo **nomeia** essas classes e fases para o SO aplicar política — sem colocar llama.cpp no núcleo.

O proxy atual da Linha B ([`runtime-nativo-linha-b.md`](runtime-nativo-linha-b.md)) **não** implementa este contrato; só prova caminho pós-ExitBoot.

## Ciclo de vida candidato

```
Load  →  Prefill  →  Decode  ↔  Idle
 │          │           │
 Weights    KV cresce   KV quente / tipado
 (RO pós)   (fase hint) (fase hint)
```

1. **Load:** runtime pede `Weights`; após popular, marca RO (política candidata).
2. **Prefill:** `set_phase(Prefill)`; throughput de prompt; pode alocar/estender `KvCache`.
3. **Decode:** `set_phase(Decode)`; priorizar latência e localidade do KV.
4. **Idle:** hint opcional para ceder CPU / adiar compactação.

## Contrato esboçado (não ABI)

```
Runtime                              Kernel
───────                              ──────
mem_alloc(class=Weights|KvCache, n) → região tipada (+ pin/RO candidatas)
mem_free / resize (futuro)          → liberação / compactação candidata
sched_set_phase(Prefill|Decode|…)   → atualiza hint do scheduler
```

O runtime continua dono de tensores, quantização e sampling.

## Políticas candidatas do scheduler

| Fase | Política candidata (desenho) |
|------|------------------------------|
| Prefill | Quantum maior / batch-friendly; menos preempt |
| Decode | Quantum menor; prioridade a latência; afinidade de CPU se houver |
| Idle | Ceder tempo; permitir manutenção de memória |
| Load | I/O-bound; não misturar com decode de outro tenant (futuro) |

O kernel **não** decide tokens, temperatura nem layout de tensores.

## Lacunas (referências — não blueprint)

| Projeto | Lacuna útil | O que **não** copiar |
|---------|-------------|----------------------|
| SLM-OS | Memória/escalonamento conscientes de modelo | Assumir o desenho deles como SO IA Livre |
| TensorOS | Integração kernel↔runtime / tensores | Empurrar tensores para dentro do núcleo |
| AgentOS | Bare-metal / servidor | Substituir hipótese e camadas do manifesto |

## Não-objetivos (esta etapa / contrato v1 desenho)

- Syscalls finais, ABI estável, MMU completa
- Swap de KV para disco, multi-tenant completo
- GPU manager nativo / multi-GPU nesta etapa — ver desenho complementar [`desenho-gpu-manager-multi-gpu.md`](desenho-gpu-manager-multi-gpu.md) (ADR 0006); RDMA
- Implementação no `kernel/` ou medição A vs B com este contrato
- Declarar hipótese comprovada

## Implementação futura (backlog — sem auto-promover)

1. Allocator tipado pós-ExitBoot (`Weights` / `KvCache`)
2. Hints de fase + política mínima de quantum
3. Runtime host/nativo falando o contrato
4. Só então: carga GGUF canônica em B e comparação justa no harness
