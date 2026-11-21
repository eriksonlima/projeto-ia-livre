# Spec — GPU manager / multi-GPU (protótipo mínimo)

## Resultado visível

Existe um **primeiro protótipo mínimo** alinhado ao desenho ADR 0006 / [`docs/desenho-gpu-manager-multi-gpu.md`](../../docs/desenho-gpu-manager-multi-gpu.md):

1. **Superfície de contrato** (enum de dispositivos, afinidade e/ou hint de placement, e/ou shard **documentado**) no **host** — stub/contrato honesto, não driver in-kernel.
2. **Fronteira clara host vs nativo** — o protótipo **não** finge ser GPU manager do SO IA Livre nem Linha B; documenta o caminho nativo futuro sem implementá-lo em `kernel/`.
3. **Caminho verificável** — gate ou script com **skip honesto** (sem fingir aceleração / multi-GPU); `make verify-runtime-gpu` e `IA_LIVRE_GPU_SKIP` da Etapa 8 **permanecem**.

Entrega **não** prova hipótese A vs B via multi-GPU; **não** entrega clusters/RDMA/tensor parallel completo.

## Contexto fixo (não reinventar)

- ADR 0006 (desenho aceito): enum / afinidade / placement; multi-GPU preferido = pipeline/layer sharding; host ADR 0002 ≠ manager nativo — [`docs/adr/0006-gpu-manager-multi-gpu.md`](../../docs/adr/0006-gpu-manager-multi-gpu.md).
- Doc de desenho: [`docs/desenho-gpu-manager-multi-gpu.md`](../../docs/desenho-gpu-manager-multi-gpu.md) (Etapa 16 = só doc; esta etapa = **primeiro stub verificável**).
- ADR 0002 / Etapa 8: single-GPU host via llama.cpp; gate `make verify-runtime-gpu`; skip `IA_LIVRE_GPU_SKIP` — **preservar** — [`docs/adr/0002-aceleracao-gpu-host-llama-cpp.md`](../../docs/adr/0002-aceleracao-gpu-host-llama-cpp.md), `scripts/verify-runtime-gpu.sh`.
- ADR 0001: inferência **fora** do kernel; kernel = mecanismos — **não** colocar llama.cpp/GGUF no núcleo.
- ADR 0003: Weights/KvCache + Prefill/Decode — complementar; GPU manager acrescenta “em qual device”, **não** substitui o scheduler.
- Etapa 19 (`em_andamento` noutro worktree): memória/scheduler no **kernel** — **esta etapa não toca `kernel/`**.
- Spec anterior (desenho): [`specs/gpu-manager-multi-gpu-desenho/`](../gpu-manager-multi-gpu-desenho/).
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`; se não precisar, registrar.

## Decisão de protótipo (obrigatória)

| Peça | Escolha nesta etapa |
|------|---------------------|
| Onde | **Host** (`std`) — stub/contrato + extensão honesta do caminho GPU; **não** `kernel/` |
| O quê | Superfície mínima alinhada ao contrato esboçado: **enum** (id / contagem / memória se disponível) + **afinidade ou placement hint** documentado; **shard** = documentação da estratégia preferida (pipeline/layer), não tensor parallel real |
| Relação com Etapa 8 | Offload `--n-gpu-layers` / `IA_LIVRE_ACCEL` **permanece**; protótipo **acrescenta** marcadores/contrato de manager, sem redefinir ADR 0002 como “já é o manager” |
| Gate | Extensão **honesta** de `verify-runtime-gpu` **ou** script/`make` separado (`verify-gpu-manager` ou nome fixado na Task 2) com skip canônico; **nunca** exit 0 fingindo multi-GPU/aceleração |
| Nativo | Doc aponta o caminho futuro (pós-ExitBoot / mecanismos kernel) **sem** implementar nem emitir `HARNESS_LINE=B` / prova A vs B |
| Multi-GPU | No máximo: **hint/documentação** de shard (layer range → device); **sem** exigir ≥2 GPUs reais no gate; sem RDMA/cluster/tensor parallel |

### Rejeitado (explícito)

- Editar `kernel/`, `node/`, `agent/` nesta etapa.
- Quebrar ou enfraquecer `make verify-runtime-gpu` / `IA_LIVRE_GPU_SKIP`.
- Tratar offload host como diferencial Linha B ou “GPU manager nativo entregue”.
- Clusters, RDMA, tensor parallel completo, expert parallel, treino.
- Prova A vs B via multi-GPU; medição harness multi-GPU como critério.
- Driver NVIDIA/AMD in-kernel; ABI/syscalls estáveis.
- Fingir `IA_LIVRE_ACCEL≠cpu` ou device count > 0 sem hardware/detecção real.

### Superfície mínima do stub (a fixar na implementação)

Marcadores / API host **candidatos** (implementação escolhe nomes estáveis e documenta):

```
IA_LIVRE_GPU_MGR=host_stub          # identidade: stub host ≠ nativo
IA_LIVRE_GPU_DEVICES=<N>            # enum: contagem (0 ok + skip)
IA_LIVRE_GPU_PLACE_HINT=<text>      # placement/afinidade documentada (ex. device0|weights)
# opcional: IA_LIVRE_GPU_SHARD_DOC=pipeline_layer  # estratégia preferida, não execução
```

Skip honesto (exemplos): reutilizar `IA_LIVRE_GPU_SKIP` quando o gate GPU for estendido; **ou** marcador dedicado `IA_LIVRE_GPU_MGR_SKIP` no script separado — exit 0 **sem** emitir sucesso de multi-GPU/aceleração falsa.

## Conteúdo obrigatório

### 1. Contrato / doc do protótipo

- Doc curta (ex. `docs/gpu-manager-prototipo-host.md`) descrevendo: o que o stub cobre, fronteira host vs nativo, relação com ADR 0006/0002, o que **não** está implementado, caminho nativo futuro (ponte ao desenho).
- Atualizar pontes no desenho ADR 0006 / `desenho-gpu-manager-multi-gpu.md` (seção “implementação futura” → primeiro item = este stub host, sem fingir nativo).

### 2. Stub host verificável

- Superfície mínima no host (preferência: estender `runtime/` com emissão de marcadores **ou** módulo/binário leve no workspace host) — **sem** `kernel/`.
- Enum e placement/afinidade (mesmo que stub com N=0/1 e hint fixo documentado).
- Shard: no mínimo documentado (estratégia pipeline/layer); código real de sharding **fora**.

### 3. Gate / skip

- Caminho `make …` documentado em `AGENTS.md`.
- Com GPU detectável: marcadores do stub presentes + Etapa 8 intacta.
- Sem GPU / CI: skip honesto exit 0.
- Gates existentes (`verify`, `verify-runtime`, `verify-runtime-gpu`, …) não regridem.

### 4. Pontes

- `AGENTS.md` (Como rodar / Como verificar / Estrutura).
- `docs/architecture.md` se ainda listar “só desenho” sem o stub.
- README: avaliar (`readme-por-fatia`).

## Fora de escopo

- Qualquer mudança em `kernel/` (Etapa 19 / B13).
- Clusters / RDMA / tensor parallel / expert parallel.
- Prova ou refutação da hipótese A vs B; perfil multi-GPU no harness.
- Troca do modelo canônico; GPU no QEMU/UEFI.
- Marketplace / P2P de GPU; treino.
- Marcar Etapa 25/`feita` nesta spec (só após gate + revisor pelo agente principal).
- Promover Etapa 25 a `em_andamento` além do que o agente principal já decidir (hoje: **pendente**, paralelo à 19).

## Critérios de aceite

- [x] Doc do protótipo + pontes deixam **explícito** host stub ≠ manager nativo ≠ Linha B
- [x] Stub host emite enum e/ou placement (marcadores estáveis) alinhados ao ADR 0006
- [x] Shard pipeline/layer está **documentado**; sem exigir execução multi-GPU real
- [x] Gate ou script verify com skip honesto; **não** finge aceleração
- [x] `make verify-runtime-gpu` e política `IA_LIVRE_GPU_SKIP` preservados
- [x] Nenhum diff em `kernel/`, `node/`, `agent/`
- [x] `AGENTS.md` documenta o caminho; README avaliado
- [x] Sem prova A vs B; sem clusters/RDMA/tensor parallel completo

## Riscos e rollback

- **Colisão com Etapa 19:** outro agente em `kernel/` no worktree principal — **mitigação:** esta spec **proíbe** `kernel/`; worktree `projeto-ia-livre-b19` / branch `etapa-b19-gpu-manager`.
- **Colisão com Etapa 8:** regressão do gate GPU — **mitigação:** Task 1 não altera a semântica de skip; Task 2 só estende ou adiciona script paralelo.
- **Confusão host = nativo:** docs e marcador `IA_LIVRE_GPU_MGR=host_stub` (ou equivalente).
- **Over-scope multi-GPU:** Pronto quando aceita shard **documentado**, não cluster.
- **Rollback:** reverter doc/stub/script; Etapa 8 permanece; etapa volta a pendente/em andamento sem “feita”.

## Etapa do roadmap

- Etapa 25 — GPU manager / multi-GPU (protótipo mínimo) (`pendente`, Issue [#25](https://github.com/eriksonlima/projeto-ia-livre/issues/25))
- Origin: B19 / ADR 0006; Etapa 8 / ADR 0002 = host GPU single ≠ manager nativo
- Spec: `specs/gpu-manager-multi-gpu-prototipo/`
- Pronto quando (roadmap): primeiro protótipo mínimo alinhado ao desenho ADR 0006 (enum/afinidade/placement e/ou shard documentado), com fronteira clara host vs nativo; caminho verificável documentado; gate ou skip honesto (sem fingir aceleração); sem prova A vs B via multi-GPU; sem clusters/RDMA/tensor parallel completo.
