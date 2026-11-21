# Spec — Multi-GPU completo além do shard host

Etapa 69 · Issue [#69](https://github.com/eriksonlima/projeto-ia-livre/issues/69) (ex-B64)  
Depende: Etapa 41 (`host_shard_exec` / [`shard-multi-gpu-host.md`](../../docs/shard-multi-gpu-host.md)); ADR [`0006`](../../docs/adr/0006-gpu-manager-multi-gpu.md) + [`desenho-gpu-manager-multi-gpu.md`](../../docs/desenho-gpu-manager-multi-gpu.md).  
Host de referência típico: **1× GTX 1050** → caminho de sucesso costuma ser **skip** `need_2_devices` (honesto).

---

## Resultado visível

Existe no **host Linux** (`std`) um caminho **além** do shard E41 que fecha «multi-GPU completo» no sentido do Pronto quando (placement/execução multi-device **real** com evidência), **sem** fingir:

| Caminho | Condição | Esperado |
|---------|----------|----------|
| **A — Placement dual / N-device (escolhido)** | ≥2 GPUs detectáveis | Plano multi-device **além** de só faixas de camada E41: afinidade dual **Weights + KvCache** (e/ou plano N-device ≥2) + query/execução mínima **por device** + marcadores `IA_LIVRE_GPU_MULTI_*` + `IA_LIVRE_GPU_MULTI_EXEC_OK`; gate `make verify-gpu-multi` |
| **B — Inviabilidade (só se A colapsar)** | «Completo» exigir inferência llama multi-GPU full / `TOKENS_PER_S` | ADR **`0025`**: multi-GPU completo inviável no gate atual (teto = E41); gate prova skip/ADR; **sem** fingir |

Com &lt;2 GPUs / CI: **skip honesto** `need_2_devices` (ou equiv.) — exit 0 **sem** `EXEC_OK`.

**Proibido:** `TOKENS_PER_S` inventado; guest/VFIO; `COMPROVA`; stub E25 como sucesso desta etapa; `EXEC_OK` com 1 device; confundir com manager nativo E38.

---

## Contexto fixo (não reinventar)

- **E41:** `IA_LIVRE_GPU_MGR=host_shard_exec`, `pipeline_layer`, plano `0:0-10,1:11-21`, `SHARD_EXEC_OK` ou `SHARD_SKIP`/`need_2_devices`. Gate `verify-gpu-shard-host` **permanece**.
- **E25:** `host_stub` + `SHARD_DOC` — só documentado; **≠** sucesso E69.
- **E8 / ADR 0002:** offload **single-GPU** (`--n-gpu-layers`); **não** redefine «manager multi-GPU entregue».
- **E38:** `GPU_MGR=native` no guest — **fora**; esta etapa é **host**.
- **E55 / E65:** GPU real host / passthrough guest — **fora**; ≠ multi-GPU completo.
- Architecture: «multi-GPU completo» ainda aberto após E41 — esta etapa fecha o item no host com A (placement) **ou** B (ADR se A exigir llama full).
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A — Placement dual Weights+Kv + N-device + `GPU_MULTI_*`** | Estender além de E41 (só layer ranges): plano com afinidade Weights/Kv por device (e/ou N≥2 devices), query/exec mínima por device, gate `verify-gpu-multi`, skip `need_2_devices` | **Escolhida** |
| **B — ADR 0025 «completo inviável» (teto = E41)** | Declarar que «completo» = inferência multi-GPU real; inviável no gate atual | **Reserva** — só se Task 1 medir que A exige llama multi-GPU full / métricas de geração |
| **C — Inferência llama multi-GPU full + `TOKENS_PER_S` no gate** | «Completo» = tokens multi-device | **Rejeitada** — finge entrega; Pronto quando pede placement/execução, não throughput; host ref. 1 GPU |
| **D — `EXEC_OK` com 1 GPU (dois papéis no mesmo device)** | Cosmético | **Rejeitada** — contradiz «sem fingir» |
| **E — Stub E25 / só docs como sucesso** | Sem evidência multi-device | **Rejeitada** |
| **F — Guest VFIO / native multi-GPU** | Pass-through / kernel | **Rejeitada** — E65/E38; fora |

### Escolha: **A — multi-GPU host «completo» = placement dual / N-device além do shard E41**

| Peça | Nesta etapa |
|------|-------------|
| Onde | Host apenas — estender scripts E41 **ou** entrypoint novo (`scripts/run-gpu-multi-host.sh` ou nome fixado na Task 1); **proibido** `kernel/` |
| Identidade | Distinta de E41: preferência `IA_LIVRE_GPU_MGR=host_multi` (ou `host_multi_place` — Task 1 fixa); **≠** `host_stub` / `host_shard_exec` / `native` |
| Além de E41 | (1) **Placement dual:** plano explícito Weights→device(s) + KvCache→device(s) (afinidade alinhada ao desenho ADR 0006 / Prefill-Decode); **e/ou** (2) **N-device:** plano estável para N≥2 (não só o bipartido 22L fixo de E41 se N>2 for detectável — mínimo honesto: N=2 com dual place) |
| Execução mínima «real» | Por device tocado: query verificável (`nvidia-smi -i` / equivalente) + evidência de seleção/alocação mínima **sem** GGUF obrigatório e **sem** `TOKENS_PER_S` |
| Inferência multi-GPU llama | **Fora** do critério; se alguém exigir isso como «completo», **pivota para B** (ADR 0025) em vez de fingir |
| Marcadores | Família `IA_LIVRE_GPU_MULTI_*` + `IA_LIVRE_GPU_MULTI_EXEC_OK` (lista estável na Task 1) |
| Skip | `need_2_devices` / `no_gpu` / `VERIFY_GPU_MULTI_SKIP=1` → exit 0 **sem** `MULTI_EXEC_OK` |
| Gate | `make verify-gpu-multi` (aditivo); E41/`verify-gpu-shard-host` e E25/`verify-gpu-manager` **intactos** |
| Contrato | Novo `docs/multi-gpu-completo-host.md` (+ pontes no desenho E41/ADR 0006) |

### Justificativa (por que A, não B agora)

- O Pronto quando pede **placement/execução multi-device com evidência**, não inferência multi-GPU nem `TOKENS_PER_S`.
- A preferida do pedido (**dual Weights+Kv / N-device + query por device**) **não** exige llama multi-GPU full — fecha a lacuna «além do shard» (E41 = só `pipeline_layer` ranges) com honestidade.
- B só se «completo» for redefinido como inferência multi-GPU real: aí A colapsa e ADR **0025** declara inviável (teto = shard E41) — alinhado a ADR 0020–0024.
- Host 1×1050: A entrega skip canônico no gate de referência; ≥2 GPUs entregam `MULTI_EXEC_OK` real.

### Pivot B (obrigatório se A colapsar)

Se na Task 1 ficar claro que o único significado útil de «completo» exige offload/shards **llama.cpp multi-GPU full** + métricas de geração:

1. Parar implementação de A teatral.
2. ADR **`0025`** (título sugerido: multi-GPU completo host inviável no gate atual — teto E41).
3. Gate `verify-gpu-multi` prova skip/ADR (ou estágio que exige presença da ADR + `GPU_MULTI_BLOCK=…`); **sem** `MULTI_EXEC_OK` fingido.
4. E41 permanece o máximo executado.

### Superfície mínima de marcadores (A — estabilizar na Task 1)

```
IA_LIVRE_GPU_MGR=host_multi          # ou nome fixado
IA_LIVRE_GPU_DEVICES=<N>
IA_LIVRE_GPU_MULTI_MODE=weights_kv_place   # ou n_device_plan — Task 1
IA_LIVRE_GPU_MULTI_PLAN=<texto estável>    # ex. W:0,K:1 | 0:W+K,1:W+K …
IA_LIVRE_GPU_MULTI_DEVICE=<id>             # repetível
IA_LIVRE_GPU_MULTI_PLACE=<Weights|KvCache|…>  # por device / papel
IA_LIVRE_GPU_MULTI_EXEC_OK
# skip:
IA_LIVRE_GPU_MULTI_SKIP
IA_LIVRE_GPU_MULTI_SKIP_REASON=need_2_devices|no_gpu|forced
```

E41 (`SHARD_*`) **não** é substituído; regressão do shard gate permanece.

---

## Conteúdo obrigatório

### 1. Documentação

- Novo: `docs/multi-gpu-completo-host.md` — o que A prova; fronteira vs E25/E41/E38/E8; skip; anti-fraude; se B: ponte ADR 0025.
- Pontes: `desenho-gpu-manager-multi-gpu.md` (item pós-E41), `shard-multi-gpu-host.md`, opcional `architecture.md` (lacuna «completo»).
- Se B: `docs/adr/0025-….md`.

### 2. Executor verificável (A)

- Entrypoint host documentado.
- ≥2 GPUs: plano dual/N-device + evidência por device + `MULTI_EXEC_OK`.
- &lt;2 GPUs: só skip, **sem** `MULTI_EXEC_OK`.

### 3. Gate

- `scripts/verify-gpu-multi.sh` + `make verify-gpu-multi`.
- Skip espelhando tabela; anti-fraude: falha se `MULTI_EXEC_OK` com `DEVICES<2` ou só stub.
- Não regressão: `verify-gpu-shard-host`, `verify-gpu-manager`, `verify-runtime-gpu`.

### 4. Pontes

- `AGENTS.md` (Como rodar / Como verificar / Estrutura).
- README avaliado (`readme-por-fatia`).

---

## Fora de escopo

- `TOKENS_PER_S` / métricas de inferência como critério.
- Inferência llama multi-GPU full (tensor/pipeline real no llama.cpp) — se for o único caminho, **B**, não stub teatral.
- Guest VFIO / PCI pass-through (E65); manager nativo (E38); stub-only (E25) como sucesso.
- Harness A vs B / `COMPROVA`; clusters/RDMA/tensor parallel obrigatório.
- Quebrar E41 / E8 / E25.
- Editar `kernel/` para fechar a etapa.
- Promover etapa a `feita` (agente principal após gate).

---

## Critérios de aceite

- [ ] Decisão A (ou pivot B com ADR 0025) registrada e honesta.
- [ ] Com ≥2 GPUs (caminho A): placement dual e/ou N-device + `IA_LIVRE_GPU_MULTI_EXEC_OK` com evidência por device — **além** do plano E41-only.
- [ ] Com &lt;2 GPUs / skip env: `IA_LIVRE_GPU_MULTI_SKIP` (+ `need_2_devices` quando couber) exit 0 **sem** `MULTI_EXEC_OK`.
- [ ] `make verify-gpu-multi` documentado; E41/E25/E8 gates preservados.
- [ ] Sem `TOKENS_PER_S` fingido; sem guest; sem `COMPROVA`; sem stub como sucesso E69.
- [ ] `AGENTS.md` atualizado; README avaliado.
- [ ] Se B: ADR 0025 + gate prova inviabilidade; teto = E41 explícito.

---

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| Host ref. 1 GPU | Skip canônico; verde sem `EXEC_OK` |
| Confundir E41 com «completo» | Identidade/`GPU_MULTI_*` distintas; doc «além do shard» |
| Pressão por llama full / tokens | Critério escrito; pivot B / ADR 0025 |
| `EXEC_OK` cosmético 1 device | Anti-fraude no gate |
| Escopo guest/native | Fora; sem `kernel/` |

Rollback: remover doc/executor/gate multi; E41 intacto; etapa volta a `em_andamento`.

---

## Etapa do roadmap

Etapa 69 — Multi-GPU completo além do shard host  
Issue: [#69](https://github.com/eriksonlima/projeto-ia-livre/issues/69) (ex-B64)  
Status roadmap: _(promover / `em_andamento` — agente principal)_  
Pronto quando: placement/execução multi-device real com evidência; sem fingir.  
Spec: `specs/multi-gpu-completo-host/`  
**Agente principal:** gravar `Spec: specs/multi-gpu-completo-host/` na entrada da Etapa 69 no `ROADMAP.md` ao promover.
