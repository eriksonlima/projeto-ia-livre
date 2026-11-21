# Arquitetura

Visão do **Projeto IA Livre**. Detalhes evoluem por etapa e ADR; este documento fixa camadas, hipótese e o que está decidido vs **realmente** aberto (pós-E71).

Princípios: [`docs/manifesto.md`](manifesto.md).  
Produto: [`docs/product-context.md`](product-context.md).  
Camadas: [`docs/adr/0001-separacao-camadas-e-p2p.md`](adr/0001-separacao-camadas-e-p2p.md).  
Glossário: [`glossario.md`](glossario.md).

## Camadas

| # | Camada | Responsabilidade |
|---|--------|------------------|
| 1 | **IA Livre (kernel)** | Boot UEFI, memória, dispositivos, isolamento, escalonamento orientado a inferência. Kernel **pequeno e auditável**. |
| 2 | **Runtime nativo de IA** | Inferência (e depois treino); tensores; KV; quantização; backends. **Fora** do kernel (`runtime-native/` + host `runtime/`). |
| 3 | **Ambiente de autonomia** | Agentes, memória, ferramentas. Consome o runtime; **não** exige o SO (ADR 0001). |
| 4 | **Rede IA Livre** | P2P: descoberta, identidade, tarefas, conhecimento. Nós nativos **e** em SO convencional. |

## Hipótese de pesquisa

**Afirmação:** um SO só para IA pode aproveitar melhor o hardware que um SO genérico otimizado para a mesma carga, se trouxer mecanismos nativos (memória model-aware, scheduler Prefill/Decode, etc.).

Comparar Linha A (Linux + runtime) vs Linha B (IA Livre + runtime nativo), mesma carga.  
**Estado do pilar 1:** **`BLOQUEIO_FINAL`** (ADR [`0022`](adr/0022-bloqueio-final-hipotese-ab.md)) — espécie canônica / passo intermediário inviáveis no gate atual (ADR [`0020`](adr/0020-runtime-native-passo-intermediario-inviavel.md) / [`0021`](adr/0021-especie-canonica-linha-b-inviavel.md)); B55 adiada. **Sem** `COMPROVA` fingido.

## Decisões tomadas (resumo)

- Rede / autonomia **não** exigem o SO IA Livre (ADR 0001).
- Kernel pequeno; motor em `runtime-native/` (ADR 0010); ABI mínima freestanding v1 (E71) — [`abi-runtime-native.md`](abi-runtime-native.md).
- Bootstrap: x86-64 + UEFI + QEMU; CPU antes de GPU.
- **Kernel:** boot → ExitBoot → MEM_SCHED (E19) → obs GOP (E37) → GPU nativo sintético (E38) — `make verify`.
- **Linha B:** BlockIO + Prefill/Decode subset + `TOKENS_PER_S` medidos (E44); espécie ≠ canônica → comparable **INCONCLUSIVO** até reabertura.
- **Path metal:** SFS/ESP (`esp_sfs_full` E63); legado `B_BLOCK_METAL` (E48); evidência padrão = report ESP (E73 / ADR 0025); **`METAL_OK`** com report de PC real (2026-11-21).
- **Harness:** A/B + A_otimizada + `sym_cpu` (E64); simetria GPU A/B inviável até VFIO (ADR [`0023`](adr/0023-simetria-gpu-harness-inviavel.md)).
- **GPU:** host E8; stub E25; nativo E38; shard E41; `host_multi` E69 (skip se &lt;2 GPUs); guest passthrough E65 (skip `need_vfio`).
- **Rede:** v1 + bootstrap E39 + mDNS E50 + TASK E51 + bridge UEFI E52 + relay intro E67 + KNOW E68; TCP guest inviável (ADR [`0024`](adr/0024-tcp-rede-guest-inviavel.md)).
- **Autonomia:** v1 + `calc` + REPL + `read_local` + bridge E49 + consumo nativo E70 (`NATIVE_CONSUME_*`).
- **Bare-metal:** ESP/USB + guia/release (E30/E47/E57); QEMU ≠ metal.
- **Checklist protótipo:** [`prototipo-objetivo-atingido.md`](prototipo-objetivo-atingido.md) (E58).
- Licenças Apache-2.0 (E17).

## Decisões abertas (reais)

| Tema | Estado honesto |
|------|----------------|
| Hipótese A vs B / `COMPROVA` | **`BLOQUEIO_FINAL`**; reabertura só com critérios ADR 0022 (B55 adiada) |
| `METAL_OK` em PC | Pendente de evidência real (E62 = skip honesto neste host) |
| DHT / NAT avançado | Adiado; relay intro ≠ DHT completo |
| Simetria GPU A/B | Até passthrough VFIO utilizável (ADR 0023) |
| TCP Rede no guest | **Inviável** no path atual (ADR 0024) — não “ainda a fazer” |
| Inferência multi-GPU host plena (llama) | Além de `host_multi` placement; sem fingir TOKENS |

**Já fechados (não listar como abertos):** REPL/`read_local`; mDNS; relay intro; KNOW; multi-GPU host_multi; ABI v1; consumo autonomia nativo; path metal SFS full.

## Estado do mapa (pós-E71)

| Faixa | Status |
|-------|--------|
| Kernel boot → ExitBoot → MEM_SCHED → ABI → obs → GPU nativo | Feito (`make verify`) |
| Runtime host CPU/GPU + contrato shim E20 | Feito |
| Linha B subset + Decode/`TOKENS_PER_S` | Feito; espécie canônica **bloqueada** |
| Path metal SFS + bridge/consumo autonomia | Feito (host); `METAL_OK` pendente |
| Nó P2P v1 + bootstrap + mDNS + TASK + KNOW + relay | Feito |
| Autonomia v1 + calc + REPL + read_local | Feito |
| Bare-metal artefato / guia USB | Feito |
| Hipótese A vs B comprovável no gate atual | **`BLOQUEIO_FINAL`** |

## Referências próximas

Estudar como **lacunas**, não blueprint: AgentOS, SLM-OS, TensorOS, CLLM — GPU eficiente, multi-GPU completo, KV avançado, multi-tenant.
