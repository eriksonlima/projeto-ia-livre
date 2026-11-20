# Desenho — GPU manager no kernel e multi-GPU

Proposta candidata de mecanismos nativos de acelerador e de estratégia multi-GPU.  
**Nível:** desenho (Etapa 16). **Não** implementação. **Não** prova da hipótese A vs B.

ADR: [`docs/adr/0006-gpu-manager-multi-gpu.md`](adr/0006-gpu-manager-multi-gpu.md).  
Host (prova atual): [`docs/adr/0002-aceleracao-gpu-host-llama-cpp.md`](adr/0002-aceleracao-gpu-host-llama-cpp.md).  
Memória/fase: [`docs/adr/0003-memoria-model-aware-e-scheduler-fases.md`](adr/0003-memoria-model-aware-e-scheduler-fases.md) + [`desenho-memoria-scheduler-nativo.md`](desenho-memoria-scheduler-nativo.md).  
Estrutural: [`docs/adr/0001-separacao-camadas-e-p2p.md`](adr/0001-separacao-camadas-e-p2p.md).

## Motivação vs offload host (Etapa 8)

No host Linux, a Etapa 8 prova offload **single-GPU** via llama.cpp (`--n-gpu-layers`, CUDA/Vulkan) — ver [`runtime-inferencia-gpu-metricas.md`](runtime-inferencia-gpu-metricas.md). Isso é caminho de prova da **camada 2 no host**, não um GPU manager do SO IA Livre.

O diferencial Linha B candidato é o kernel expor **enumeração, afinidade e placement** conscientes de modelo/fase, e (depois) **pipeline/layer sharding** entre dispositivos — sem colocar llama.cpp ou GGUF dentro do núcleo.

`kernel/` e `runtime/` atuais **não** implementam este manager nem multi-GPU.

## Fronteira ADR 0002 × caminho nativo

| Aspecto | Host (ADR 0002 / Etapa 8) | Caminho nativo (este desenho) |
|---------|---------------------------|-------------------------------|
| Onde | Linux `std` + `ia-livre-runtime` | Kernel IA Livre (mecanismos) + runtime |
| GPU | Single-GPU via llama.cpp features | Enum + afinidade + placement; multi-GPU depois |
| Gate | `make verify-runtime-gpu` | Nenhum gate novo nesta etapa (só doc) |
| Inferência | No runtime (host) | Continua no runtime (ADR 0001) |
| Confusão a evitar | «Já temos GPU no SO» | Host ≠ manager nativo |

## Contrato esboçado (não ABI)

```
Runtime (camada 2)                    Kernel (camada 1 — mecanismos)
──────────────────                    ──────────────────────────────
list_devices()                    →   enum de aceleradores (id, mem, caps)
alloc(class, device_hint)         →   região tipada + afinidade (Weights|KvCache…)
set_phase(Prefill|Decode)         →   hint (ADR 0003) + placement candidata
place_shard(layer_range, device)  →   registro de shard (pipeline/layer) — futuro
offload llama.cpp (host hoje)     →   **fora** deste contrato (ADR 0002 / host)
```

O runtime continua dono de kernels CUDA/Vulkan, tensores, quantização e sampling.

## Ciclo com Prefill / Decode

```
Load  →  Prefill  →  Decode  ↔  Idle
 │          │           │
 enum+      placement   KV quente no
 Weights    candidata   device afinado
 (device)   (fase)      (fase + afinidade)
```

1. **Load:** `list_devices` + `alloc(Weights, device_hint)`; pesos em device(s) escolhido(s).
2. **Prefill:** `set_phase(Prefill)`; throughput; pode estender `KvCache` com afinidade.
3. **Decode:** `set_phase(Decode)`; priorizar localidade do KV no device.
4. **Multi-GPU (futuro próximo do desenho):** `place_shard(layer_range, device)` para pipeline/layer sharding.

O GPU manager **não** substitui o scheduler de fases do ADR 0003 — **complementa** com “em qual device”.

## Multi-GPU — estratégia preferida

**Pipeline / layer sharding:** particionar camadas (ou faixas de camadas) e/ou fases ao longo de GPUs. Motivo: alinha-se a Prefill/Decode e ao modelo mental do runtime atual (camadas sequenciais), sem exigir all-reduce denso de tensor parallel no primeiro passo.

### Alternativas nomeadas (futuro)

| Estratégia | Papel neste desenho |
|------------|---------------------|
| Tensor parallel | Futuro — comunicação intensa entre devices |
| Expert parallel | Futuro — MoE / roteamento |
| Clusters / RDMA | Futuro — multi-host; fora do próximo protótipo |

## Não-objetivos (desenho v1)

- ABI/syscalls estáveis, IOMMU completo, MIG/SR-IOV
- Driver NVIDIA/AMD **in-kernel** nesta etapa
- Tensor parallel obrigatório
- Medição multi-GPU no harness (ver backlog B12 / harness)
- Troca do modelo canônico
- Declarar hipótese A vs B comprovada
- Implementação em `kernel/` ou `runtime/` nesta etapa

## Alternativas consideradas (e rejeitadas agora)

| Alternativa | Por que não agora |
|-------------|-------------------|
| Estender ADR 0002 com multi-GPU host como “manager” | Confunde prova host com diferencial SO |
| Inferência / llama.cpp no kernel | Viola ADR 0001 |
| Tensor parallel como preferido | Mais complexo; menos alinhado ao primeiro passo Prefill/Decode |
| Copiar AgentOS / TensorOS / SLM-OS | Lacunas a estudar, não blueprint |

## Implementação futura (backlog — sem auto-promover)

1. Enumeração mínima de aceleradores pós-ExitBoot (ou ponte host→nativo)
2. Afinidade `Weights`/`KvCache` + device hint
3. Placement por fase (Prefill/Decode)
4. Pipeline/layer sharding em ≥2 devices
5. Só então: métricas multi-GPU / perfil no harness (coordenar com evolução do harness)
