# Spec — Shard multi-GPU host executado (além do stub)

Etapa 41 · Issue [#40](https://github.com/eriksonlima/projeto-ia-livre/issues/40) (ex-B34)  
Depende: Etapa 25 (stub host `SHARD_DOC` apenas documentado), Etapa 8 (offload single-GPU / ADR 0002), Etapa 38 (manager **nativo** — **≠** esta etapa).

---

## Resultado visível

Existe no **host Linux** (`std`) um caminho que **executa** placement/shard mínimo de pipeline/layer **além** do stub E25 (`IA_LIVRE_GPU_SHARD_DOC` sem execução):

1. **Identidade distinta** — `IA_LIVRE_GPU_MGR=host_shard_exec` (ou equivalente fixado na Task 1); **≠** `host_stub` (E25) **≠** `native` (E38).
2. **Com ≥2 GPUs detectáveis** — plano de shard pipeline/layer **materializado e executado** (ex.: faixas de camadas lógicas em `device0` e `device1`); marcadores de plano + evidência de execução mínima por device **sem** inventar throughput.
3. **Com &lt;2 GPUs** — **skip honesto** (`IA_LIVRE_GPU_SHARD_SKIP`, exit 0); **não** fingir shard multi-device nem `IA_LIVRE_GPU_SHARD_EXEC_OK`.
4. **Gate dedicado** — `make verify-gpu-shard-host` (nome fixado na implementação) documentado em `AGENTS.md`; stub E25 (`make verify-gpu-manager`) e Etapa 8 (`make verify-runtime-gpu`) **inalterados** em semântica.
5. **Contrato** — `docs/shard-multi-gpu-host.md` descreve fronteira, marcadores, critério de execução mínima, política de skip e o que **não** é multi-GPU completo.

**Proibido nesta etapa:** `TOKENS_PER_S` fingido, prova harness A vs B, tensor parallel/RDMA/cluster, editar `kernel/` para manager, substituir ou confundir com E38.

---

## Contexto fixo (não reinventar)

- E25 / [`docs/gpu-manager-prototipo-host.md`](../../docs/gpu-manager-prototipo-host.md): enum, placement hint, `IA_LIVRE_GPU_SHARD_DOC=pipeline_layer` — **só documentado**; **esta etapa acrescenta execução** sem remover o stub.
- ADR 0006 + [`docs/desenho-gpu-manager-multi-gpu.md`](../../docs/desenho-gpu-manager-multi-gpu.md): estratégia preferida = pipeline/layer sharding; `place_shard(layer_range, device)` — esboço; implementação host mínima aqui.
- ADR 0002 / Etapa 8: `--n-gpu-layers`, `IA_LIVRE_ACCEL`, `IA_LIVRE_GPU_SKIP` — offload single-GPU **permanece**; shard executado **não** redefine ADR 0002 como «manager entregue».
- E38 / [`docs/gpu-manager-nativo.md`](../../docs/gpu-manager-nativo.md): enum/afinidade/placement **no kernel** com `IA_LIVRE_GPU_MGR=native` — **fora** do escopo desta etapa.
- ADR 0001: inferência continua no runtime; execução de shard host **pode** usar CUDA/Vulkan já usados pelo runtime, **sem** llama.cpp no kernel.
- Modelo canônico TinyLlama ~22 camadas — faixas lógicas no plano são referência estável; **não** é obrigatório carregar GGUF completo no gate de shard se a execução mínima for honesta (ver decisão abaixo).
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A** | Estender `gpu-manager-stub.sh` para fingir `SHARD_EXEC` com o mesmo script | **Rejeitada** — confunde stub doc-only com execução |
| **B** | Executor host novo (script + binário leve / extensão `runtime/`) com plano + ops mínimas por GPU | **Escolhida** |
| **C** | Exigir inferência multi-GPU com `TOKENS_PER_S` no gate | **Rejeitada** — finge entrega; fora do Pronto quando |
| **D** | Shard «lógico» em 1 GPU (duas faixas no mesmo device) como sucesso do gate | **Rejeitada** — não é multi-GPU real; contradiz «senão skip honesto» |
| **E** | Reusar gate `verify-gpu-manager` sem separar identidade | **Rejeitada** — regressão semântica E25 |
| **F** | Implementar no `kernel/` | **Rejeitada** — é E38 / futuro nativo |

### Escolha: **B — executor host `host_shard_exec` com gate aditivo**

| Peça | Escolha nesta etapa |
|------|---------------------|
| Onde | Host apenas — preferência: `scripts/` + crate opcional no workspace (`gpu-shard-host/` ou módulo em `runtime/`) **sem** `kernel/` |
| Identidade | `IA_LIVRE_GPU_MGR=host_shard_exec` |
| Estratégia | `pipeline_layer` (ADR 0006) — partições de **camadas lógicas** (ex.: 22 → `0-10` em device0, `11-21` em device1) |
| Execução mínima «real» | Por device: seleção de GPU (`cudaSetDevice` / `vk` equivalente **ou** subprocesso com `CUDA_VISIBLE_DEVICES`) + operação verificável (alocação/lib init mínima **ou** offload parcial documentado); emite `IA_LIVRE_GPU_SHARD_DEVICE=<id>` + `IA_LIVRE_GPU_SHARD_RANGE=<lo>-<hi>` por particionamento |
| Inferência | **Opcional** e **não** critério; se usar runtime, **proibido** exigir/publicar `TOKENS_PER_S` como prova desta etapa |
| Enum | Reutilizar detecção estilo stub (`nvidia-smi -L`) ou API CUDA; contagem honesta |
| Stub E25 | Intocado; `IA_LIVRE_GPU_SHARD_DOC` permanece no stub |

### Decisão de skip (obrigatória — fixa no gate)

| Condição | Comportamento | Marcador | Exit |
|----------|---------------|----------|------|
| `VERIFY_GPU_SHARD_SKIP=1` | Skip explícito CI | `IA_LIVRE_GPU_SHARD_SKIP` + motivo | **0** |
| GPU indetectável (`nvidia-smi` falha) e sem `VERIFY_GPU_SHARD_FORCE=1` | Skip honesto | `IA_LIVRE_GPU_SHARD_SKIP` | **0** |
| `IA_LIVRE_GPU_DEVICES=1` (ou 0 com GPU «detectável» inconsistente) | **Não** executa shard multi-device; skip honesto | `IA_LIVRE_GPU_SHARD_SKIP` (motivo: `need_2_devices`) | **0** |
| `IA_LIVRE_GPU_DEVICES≥2` | Executa plano + evidência | `IA_LIVRE_GPU_SHARD_EXEC_OK` (+ plano/ranges) | **0** se ok, **1** se falha |
| Inventar `DEVICES≥2` sem hardware | **Proibido** | — | gate deve falhar |

**Não** reutilizar `IA_LIVRE_GPU_MGR_SKIP` do stub como substituto — marcador dedicado `IA_LIVRE_GPU_SHARD_SKIP` para não confundir gates.

### Superfície mínima de marcadores (a estabilizar na Task 1)

```
IA_LIVRE_GPU_MGR=host_shard_exec
IA_LIVRE_GPU_DEVICES=<N>
IA_LIVRE_GPU_SHARD_MODE=pipeline_layer
IA_LIVRE_GPU_SHARD_PLAN=<texto estável>     # ex. 0:0-10,1:11-21
IA_LIVRE_GPU_SHARD_DEVICE=<id>               # repetível por device tocado
IA_LIVRE_GPU_SHARD_RANGE=<lo>-<hi>           # por device
IA_LIVRE_GPU_SHARD_EXEC_OK
# skip:
IA_LIVRE_GPU_SHARD_SKIP
```

---

## Conteúdo obrigatório

### 1. Documentação

- Novo: `docs/shard-multi-gpu-host.md` — contrato, fluxo, skip, fronteira host_stub / host_shard_exec / native, relação ADR 0006/0002, limites (sem TP/RDMA).
- Ponte em `docs/gpu-manager-prototipo-host.md` («E41 executa shard; stub permanece doc-only»).
- Ponte em `docs/desenho-gpu-manager-multi-gpu.md` item 3 da seção implementação («shard host executado E41»).

### 2. Executor verificável

- Entrypoint documentado (script + binário se necessário).
- ≥2 GPUs: emite plano + toca cada device com evidência.
- &lt;2 GPUs: só skip, **sem** `SHARD_EXEC_OK`.

### 3. Gate

- `scripts/verify-gpu-shard-host.sh` + `make verify-gpu-shard-host`.
- Política de skip espelhando tabela acima.
- Não regressão: `make verify-gpu-manager`, `make verify-runtime-gpu`.

### 4. Pontes

- `AGENTS.md` (Como rodar / Como verificar / Estrutura).
- README avaliado (`readme-por-fatia`).

---

## Fora de escopo

- `kernel/` (manager nativo E38 já feito; **não** duplicar na etapa 41).
- `node/`, `agent/`, harness A vs B, `verify-harness-comparable`.
- Tensor parallel, expert parallel, RDMA, multi-host.
- Exigir ≥2 GPUs em **todo** CI sem skip.
- `TOKENS_PER_S` / métricas de inferência como critério desta etapa.
- Quebrar ou fundir semântica de `IA_LIVRE_GPU_MGR=host_stub`.
- Driver in-kernel; ABI estável.

---

## Critérios de aceite

- [ ] `docs/shard-multi-gpu-host.md` existe e declara skip vs execução
- [ ] Identidade `host_shard_exec` distinta de `host_stub` e `native`
- [ ] Com ≥2 GPUs: plano pipeline/layer + `IA_LIVRE_GPU_SHARD_EXEC_OK` com evidência por device
- [ ] Com &lt;2 GPUs ou skip env: `IA_LIVRE_GPU_SHARD_SKIP` e exit 0 **sem** `SHARD_EXEC_OK`
- [ ] `make verify-gpu-shard-host` documentado; stub E25 e `verify-runtime-gpu` preservados
- [ ] Sem `TOKENS_PER_S` fingido; sem prova A vs B
- [ ] Nenhum diff obrigatório em `kernel/` para fechar a etapa
- [ ] `AGENTS.md` atualizado; README avaliado

---

## Riscos e rollback

- **Hardware CI sem 2 GPUs:** mitigação — skip canônico; gate verde com `IA_LIVRE_GPU_SHARD_SKIP`, não com execução fingida.
- **Confusão E25/E41/E38:** mitigação — três identidades (`host_stub`, `host_shard_exec`, `native`) e três gates/docs distintos.
- **Colisão Etapa 8:** mitigação — não alterar `verify-runtime-gpu.sh` salvo ponte documental; shard não exige nova feature obrigatória no runtime CPU default.
- **Over-scope llama.cpp multi-GPU completo:** mitigação — execução mínima por device basta; inferência full multi-GPU fica backlog.
- **Rollback:** remover executor/gate/doc; E25 intacto; etapa volta a `em_andamento`.

---

## Etapa do roadmap

- Etapa 41 — Shard multi-GPU host executado (além do stub) (`em_andamento`, Issue [#40](https://github.com/eriksonlima/projeto-ia-livre/issues/40))
- Origin: B34; E25 = stub; E38 = nativo ≠ host shard executado
- Spec: `specs/shard-multi-gpu-host/`
- Pronto quando: placement/shard mínimo **real** no host com evidência **ou** skip honesto; ≠ manager nativo.