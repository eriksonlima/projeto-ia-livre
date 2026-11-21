# ADR 0006 — GPU manager no kernel e multi-GPU (desenho candidato)

- Status: aceita (nível **desenho**; implementação = etapas/backlog futuros)
- Data: 2026-11-20

## Contexto

A Etapa 8 / ADR 0002 fechou aceleração GPU **no host**: llama.cpp, CUDA canônico / Vulkan alternativa, offload single-GPU via `--n-gpu-layers`. Em [`docs/architecture.md`](../architecture.md) restavam abertos «GPU manager no kernel» e «multi-GPU».

Sem desenho, o risco é (a) tratar o offload host como se já fosse diferencial do SO IA Livre, ou (b) puxar drivers/inferência para dentro do kernel — contradizendo ADR 0001.

ADR 0001 permanece: inferência **fora** do kernel; o kernel fornece **mecanismos** (incl. aceleradores). ADR 0003 (Weights/KvCache + Prefill/Decode) é **complementar**: tipagem de memória e fase; esta ADR acrescenta **dispositivo / placement**.

Esta ADR **não** implementa manager nem multi-GPU em `kernel/` ou `runtime/`. Detalhe: [`docs/desenho-gpu-manager-multi-gpu.md`](../desenho-gpu-manager-multi-gpu.md) (Task 2).

## Decisão

1. **Fronteira host (ADR 0002):** permanece o caminho de prova atual — single-GPU no host Linux. **Não** estender ADR 0002 para fingir multi-GPU/manager como diferencial do SO. Evolução host (mais flags llama.cpp) ≠ GPU manager nativo.
2. **Fronteira kernel (ADR 0001):** o kernel expõe **mecanismos** de acelerador; o runtime continua dono de kernels CUDA/Vulkan, tensores, GGUF, sampling e paralelismo lógico.
3. **GPU manager — escopo candidato (contrato mínimo kernel↔runtime):**
   - **Enumeração** de dispositivos (id, memória, capacidades);
   - **Afinidade** de regiões/memória a dispositivo (alinhável a `Weights` / `KvCache` do ADR 0003 quando GPU-backed);
   - **Hints de placement** (qual device / fase);
   - **Não** embutir driver completo NVIDIA/AMD no núcleo neste desenho — backends/drivers ficam no runtime ou em camadas futuras nomeadas.
4. **Multi-GPU — estratégia preferida:** **pipeline / layer sharding** entre dispositivos (particionar camadas/fases ao longo de GPUs) — alinhada a Prefill/Decode e ao runtime atual.
5. **Multi-GPU — alternativas nomeadas (futuro):** tensor parallel, expert parallel, clusters/RDMA — fora do critério desta etapa e fora do “próximo protótipo” implícito.
6. **Relação com ADR 0003:** Prefill/Decode e classes de memória **estendem-se** conceitualmente a “em qual device”; o GPU manager **não** substitui o scheduler de fases.
7. **Critério verificável desta etapa:** documental (ADR + doc + pontes). **Sem** gate `make verify*` novo.

### Rejeitado nesta decisão

- Tratar Etapa 8 / métricas GPU host como se já fossem o GPU manager nativo.
- Colocar inferência, llama.cpp ou GGUF **dentro** do kernel.
- Declarar hipótese A vs B comprovada via GPU ou multi-GPU.
- RDMA, cluster multi-host, treino distribuído, ROCm/Metal como requisito deste desenho.
- Implementação de manager/multi-GPU em código nesta etapa.
- Invalidar ADR 0001 / 0002 (só delimitar fronteiras).

## Consequências

### Positivas

- Fecha a lacuna de architecture no nível desenho com **uma** proposta clara
- Mantém ADR 0002 como prova host honesta; abre horizonte nativo sem fingir entrega
- Alinha multi-GPU preferido a Prefill/Decode (pipeline/layer sharding)

### Negativas

- Contrato ainda não implementado nem medido
- Risco de over-design se ABI/syscalls forem congeladas cedo — por isso ABI/driver in-kernel ficam **fora** desta ADR
- Exige disciplina para não confundir host Vulkan/CUDA com diferencial Linha B

## O que não fica decidido

- Implementação no `kernel/` / `runtime/`
- ABI / syscalls estáveis
- Vendor driver in-kernel
- Tensor/expert parallel como caminho obrigatório
- Medição multi-GPU no harness
- Troca do modelo canônico

## Relação com etapas

| Etapa / ADR | Papel |
|-------------|--------|
| 8 / 0002 | Prova GPU **host** single-GPU — **não** é este manager |
| 0003 | Memória/fase model-aware — complementar |
| 12 | Proxy Linha B — **não** implementa GPU manager |
| 25 / B19 | Stub **host** verificável (enum/placement/shard doc) — [`gpu-manager-prototipo-host.md`](../gpu-manager-prototipo-host.md); **≠** manager nativo |
| Futuro nativo | Enum + afinidade + placement no kernel; depois pipeline multi-GPU |
