# Spec — GPU manager no kernel / multi-GPU (desenho)

## Resultado visível

Existe um **desenho documentado** (ADR + doc de desenho) do **escopo candidato** de:

1. **GPU manager no kernel** — mecanismos nativos (enumeração, afinidade de memória/dispositivo, hints de placement) que o IA Livre poderia expor ao runtime.
2. **Multi-GPU** — estratégia candidata preferida (e alternativas nomeadas) além do offload single-GPU do host.
3. **Fronteira explícita vs aceleração host** (ADR 0002) — o que permanece no protótipo Linux/`llama.cpp` vs o que é caminho nativo futuro (Linha B / camada 1→2).

A etapa é **só documental**. Não há implementação de GPU no `kernel/`, nem multi-GPU no `runtime/`, nem prova de hipótese A vs B via aceleradores.

## Contexto fixo (não reinventar)

- Decisão ainda aberta em [`docs/architecture.md`](../../docs/architecture.md): «GPU manager no kernel e multi-GPU» (protótipo host CUDA/Vulkan já fechado pelo ADR 0002).
- ADR 0001: inferência **fora** do kernel; kernel fornece mecanismos (incl. aceleradores) — [`docs/adr/0001-separacao-camadas-e-p2p.md`](../../docs/adr/0001-separacao-camadas-e-p2p.md).
- ADR 0002: aceleração GPU **no host** via llama.cpp (CUDA canônico / Vulkan alternativa); **fora** daquela decisão: multi-GPU, GPU manager no kernel — [`docs/adr/0002-aceleracao-gpu-host-llama-cpp.md`](../../docs/adr/0002-aceleracao-gpu-host-llama-cpp.md).
- Métricas host (Etapa 8): [`docs/runtime-inferencia-gpu-metricas.md`](../../docs/runtime-inferencia-gpu-metricas.md) — prova de caminho single-GPU; **não** é GPU manager nem multi-GPU.
- ADR 0003: classes `Weights`/`KvCache` + hints Prefill/Decode — desenho de memória/scheduler **CPU/model-aware**; GPU manager **não** foi decidido lá — [`docs/adr/0003-memoria-model-aware-e-scheduler-fases.md`](../../docs/adr/0003-memoria-model-aware-e-scheduler-fases.md).
- Hipótese de pesquisa e harness: integração CPU–GPU nativa é candidata a diferencial Linha B; harness v1 **sem** perfil GPU — [`docs/harness-linha-a-b.md`](../../docs/harness-linha-a-b.md).
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`; se não precisar, registrar.

## Decisão de desenho (única — obrigatória)

| Peça | Escolha nesta etapa |
|------|---------------------|
| Forma | **Desenho** (ADR + doc) — **não** implementação completa |
| Fronteira host (ADR 0002) | Permanece o **caminho de prova atual**: single-GPU no host (`--n-gpu-layers`, CUDA/Vulkan). **Não** estender ADR 0002 para fingir multi-GPU/manager como diferencial do SO. Evolução host (ex. mais flags llama.cpp) ≠ GPU manager nativo |
| Fronteira kernel (ADR 0001) | Kernel expõe **mecanismos** de acelerador; runtime continua dono de kernels CUDA/Vulkan, tensores, GGUF, sampling e paralelismo lógico |
| GPU manager — escopo candidato | Contrato mínimo kernel↔runtime: (1) **enumeração** de dispositivos; (2) **afinidade** de regiões/memória a dispositivo (alinhável às classes ADR 0003 quando GPU-backed); (3) **hints de placement** (qual device / fase); (4) **não** embutir driver completo NVIDIA/AMD no núcleo nesta etapa de desenho — drivers/backends ficam no runtime ou em camadas futuras nomeadas |
| Multi-GPU — estratégia preferida | **Pipeline / layer sharding** entre dispositivos como **primeira** candidata de pesquisa (particionar camadas/fases ao longo de GPUs) — mais alinhada a Prefill/Decode e ao runtime atual |
| Multi-GPU — alternativas nomeadas | Tensor parallel, expert parallel, e clusters/RDMA = **futuro documentado**, fora do critério desta etapa e fora do “próximo protótipo” implícito |
| Relação com ADR 0003 | Hints Prefill/Decode e classes Weights/KvCache **estendem-se** conceitualmente a “em qual device”; GPU manager **não** substitui o scheduler de fases — complementar |
| Critério verificável documental | Checklist: ADR + doc com fronteira ADR 0002×nativo, escopo manager, estratégia multi-GPU preferida, não-objetivos, e ponte em `architecture.md`; **sem** gate `make verify*` novo |
| ADR | **Nova** (ex.: `docs/adr/0006-gpu-manager-multi-gpu.md`) — status **aceita** no nível *desenho candidato*; implementação = etapas/backlog futuros |
| Doc de desenho | `docs/desenho-gpu-manager-multi-gpu.md` (ou nome equivalente fixado na Task 2) |

### Rejeitado (explícito)

- Implementar GPU manager, drivers ou multi-GPU em `kernel/` / `runtime/` nesta etapa (salvo ponte documental).
- Colocar inferência, llama.cpp ou GGUF **dentro** do kernel.
- Tratar o offload host (ADR 0002 / Etapa 8) como se já fosse o GPU manager nativo.
- Declarar hipótese A vs B comprovada via GPU ou multi-GPU.
- RDMA, cluster multi-host, treino distribuído, ROCm/Metal como requisito desta etapa.
- Copiar AgentOS / TensorOS / SLM-OS como blueprint de GPU.
- Várias propostas concorrentes sem escolher escopo + estratégia preferida — a etapa **fecha um** desenho candidato.
- Alterar ou invalidar ADR 0001 / 0002 (só delimitar fronteiras).

### Esboço do contrato (a detalhar no doc de desenho)

```
Runtime (camada 2)                    Kernel (camada 1 — mecanismos)
──────────────────                    ──────────────────────────────
list_devices()                    →   enum de aceleradores (id, mem, caps)
alloc(class, device_hint)         →   região tipada + afinidade (Weights|KvCache…)
set_phase(Prefill|Decode)         →   hint (ADR 0003) + placement candidata
place_shard(layer_range, device)  →   registro de shard (pipeline/layer) — futuro
offload llama.cpp (host hoje)     →   **fora** deste contrato (ADR 0002 / host)
```

Não-objetivos do desenho v1: ABI/syscalls estáveis, IOMMU completo, MIG/SR-IOV, driver NVIDIA in-kernel, tensor parallel obrigatório, medição multi-GPU no harness, troca do modelo canônico.

## Conteúdo obrigatório

### 1. ADR

- Contexto: lacuna «GPU manager / multi-GPU» em `architecture.md` + limites explícitos do ADR 0002.
- Decisão: escopo candidato do manager + estratégia multi-GPU preferida (pipeline/layer sharding) + fronteira host vs nativo.
- Consequências positivas/negativas; o que **não** fica decidido (implementação, ABI, vendor driver, tensor parallel).
- Relação com ADR 0001 (mecanismos vs inferência), 0002 (host permanece), 0003 (complementar, não substitui).

### 2. Doc de desenho

- Motivação: por que single-GPU host ≠ diferencial Linha B; o que o manager nativo acrescentaria.
- Fronteira ADR 0002 × caminho nativo (tabela clara).
- Modelo do GPU manager (enum, afinidade, placement) e ciclo com Prefill/Decode.
- Multi-GPU: pipeline/layer sharding preferido; tensor/expert/RDMA como futuro.
- Não-objetivos e backlog de implementação futura (sem promover etapa sozinho).
- Honestidade: Etapa 8 / métricas GPU = prova host; este desenho **não** está implementado.

### 3. Pontes

- `docs/architecture.md`: marcar GPU manager / multi-GPU como **decidido no nível desenho** (link ADR + doc); implementação e prova continuam abertas; decisão “aceleração NVIDIA multi-GPU posterior” alinhada ao desenho.
- Ponte mínima em `docs/adr/0002-…` e/ou `docs/runtime-inferencia-gpu-metricas.md`: host ≠ manager nativo.
- Opcional: menção curta em `docs/desenho-memoria-scheduler-nativo.md` (complementaridade com 0003).
- `AGENTS.md`: ponte na estrutura/docs se couber, sem inventar gate de código.
- README: avaliar (`readme-por-fatia`).

## Fora de escopo

- Código de produto em `kernel/`, `runtime/`, `node/`, `agent/`
- Implementação de drivers GPU, multi-GPU real, syscalls, IOMMU
- Mudança do gate `make verify-runtime-gpu` ou do protótipo host da Etapa 8
- Prova ou refutação da hipótese A vs B
- Perfil GPU no harness (isso é B12 / backlog — só nomear se necessário)
- Marketplace, P2P de recursos GPU, treino
- Nova etapa de implementação sem confirmação / backlog

## Critérios de aceite

- [ ] ADR nova registra **um** escopo candidato (GPU manager + multi-GPU preferido) com fronteira vs ADR 0002 e ADR 0001
- [ ] Doc de desenho detalha contrato kernel↔runtime, estratégia multi-GPU, não-objetivos e o que fica para o futuro
- [ ] `architecture.md` deixa de listar GPU manager/multi-GPU como “aberto sem proposta”; aponta ADR/doc; implementação permanece aberta
- [ ] Pontes honestas: métricas/host Etapa 8 ≠ manager nativo ≠ multi-GPU implementado
- [ ] README avaliado (`readme-por-fatia`)
- [ ] Sem código de produto novo no kernel/runtime nesta etapa
- [ ] Etapa 16 não é marcada `feita` nesta spec (só após revisão pelo agente principal)

## Riscos e rollback

- **Risco:** leitor achar que Vulkan/CUDA no host = GPU manager do SO → avisos explícitos “host ≠ nativo”.
- **Risco:** escopo inchado (implementar driver agora) → Pronto quando = só doc/ADR.
- **Risco:** ADR contradizer 0001 (inferência no kernel) ou invalidar 0002 → rejeitar; delimitar, não substituir.
- **Rollback:** reverter ADR/doc/pontes; etapa continua `em_andamento`.

## Etapa do roadmap

- Etapa 16 — GPU manager no kernel / multi-GPU (desenho) (`em_andamento`, Issue [#16](https://github.com/eriksonlima/projeto-ia-livre/issues/16))
- Spec: `specs/gpu-manager-multi-gpu-desenho/`
- Pronto quando (roadmap): desenho (ADR/doc) do escopo candidato de GPU manager no kernel e multi-GPU — fronteira vs aceleração host (ADR 0002); desenho, não implementação completa.
