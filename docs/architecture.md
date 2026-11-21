# Arquitetura

Visão inicial do **Projeto IA Livre**. Detalhes de implementação evoluem por etapa e ADR; este documento fixa camadas, hipótese de pesquisa e o que já está decidido vs aberto.

Princípios e governança: [`docs/manifesto.md`](manifesto.md).  
Contexto de produto: [`docs/product-context.md`](product-context.md).  
Decisão estrutural de camadas: [`docs/adr/0001-separacao-camadas-e-p2p.md`](adr/0001-separacao-camadas-e-p2p.md).

## Camadas

| # | Camada | Responsabilidade |
|---|--------|------------------|
| 1 | **IA Livre (kernel)** | Boot (UEFI), memória física/virtual, CPU e aceleradores, dispositivos, isolamento, interrupções e escalonamento orientado a inferência (ex.: distinguir prefill e decode quando houver mecanismo nativo). Kernel **pequeno e auditável**. |
| 2 | **Runtime nativo de IA** | Inferência e, depois, treinamento; tensores; KV cache; quantização; backends de aceleração. Evolui **fora** do kernel, usando os mecanismos que o kernel expõe. |
| 3 | **Ambiente de autonomia** | Agentes, memória persistente, ferramentas, experimentação e desenvolvimento de capacidades. Consome o runtime; não faz parte do núcleo. |
| 4 | **Rede IA Livre** | Protocolo P2P comum: descoberta, identidade, tarefas, conhecimento e recursos. Serve **nós nativos** (IA Livre) e **nós em SO convencional** (Linux, Windows, etc.). |

As camadas formam um ecossistema, não quatro produtos desconectados. A ordem de entrega no roadmap (kernel → runtime CPU → nó P2P) não exige que a autonomia esteja madura antes do nó.

## Hipótese de pesquisa

**Afirmação a testar:** um SO construído exclusivamente para inferência/IA pode aproveitar melhor o hardware do que um SO de propósito geral **otimizado para a mesma carga**, quando o SO próprio traz mecanismos nativos (memória model-aware, scheduler consciente de prefill/decode, integração CPU–GPU sem camadas genéricas desnecessárias, etc.).

### O que comparar

- Mesmo hardware, mesmo modelo, mesma quantização e carga de trabalho comparável.
- Linha A (referência): Linux otimizado + runtime de inferência otimizado + API.
- Linha B (projeto): IA Livre (kernel + mecanismos) + runtime nativo + API.
- Métricas candidatas: tokens/s, latência p95, RAM/VRAM por requisição, joules por milhão de tokens, tempo de carregamento, disponibilidade — sempre controlando qualidade e contexto.

### O que não assumir

- Que “ter SO próprio” vence só por existir.
- Que repetir o **mesmo** runtime e os **mesmos** drivers genéricos sobre um kernel vazio justifica o custo de um SO.
- Que multi-GPU, RDMA ou clusters já estão resolvidos no desenho atual.
- Que benchmarks de projetos bare-metal próximos (AgentOS, etc.) são prova independente sem metodologia equivalente.
- Que GPU NVIDIA/AMD está no caminho crítico da Etapa 4 (primeiro alvo é CPU/QEMU).

## Decisões tomadas

- Participar da Rede IA Livre **não** exige instalar o SO IA Livre.
- Kernel pequeno; inteligência pesada (modelos, agentes) **fora** do kernel — ver ADR 0001.
- Protocolo P2P **independente** do kernel/SO — desenvolvível em paralelo no host — ver ADR 0001.
- Bootstrap inicial: **x86-64 + UEFI + QEMU**; **CPU antes de GPU**.
- **Etapa 30:** imagem ESP/USB empacotável + gate de artefato (`verify-baremetal`) — ADR [`0011`](adr/0011-boot-imagem-esp-baremetal.md) / [`boot-hardware-real.md`](boot-hardware-real.md); **QEMU ≠ bare-metal**; hardware real = checklist manual + skip honesto.
- Aceleração GPU: host single-GPU (E8/ADR 0002); stub host (E25); **manager nativo mínimo** (E38) — [`gpu-manager-nativo.md`](gpu-manager-nativo.md); **shard host executado** (E41) — [`shard-multi-gpu-host.md`](shard-multi-gpu-host.md); multi-GPU completo / métricas A vs B **ainda abertos**.
- Nenhuma decisão só por curiosidade técnica (manifesto).
- **Etapa 10:** primeiro mecanismo de memória no kernel UEFI — mapa + `AllocatePages`/bump sob Boot Services (sem inferência). Contrato: [`kernel-alem-do-boot.md`](kernel-alem-do-boot.md).
- **Etapa 11:** `ExitBootServices` + base estável (mapa owned + memória); I/O pós-exit via UART COM1. Contrato: [`kernel-pos-boot-services.md`](kernel-pos-boot-services.md).
- **Etapa 12:** Linha B mínima = proxy pós-ExitBoot (não TinyLlama); hipótese **não** comprovada. Contrato: [`runtime-nativo-linha-b.md`](runtime-nativo-linha-b.md).
- **Etapa 13:** desenho candidato memória model-aware + scheduler por fases (ADR 0003).
- **Etapa 19:** implementação mínima no kernel pós-ExitBoot (`Weights`/`KvCache` + Prefill/Decode + quantum) — [`memoria-scheduler-impl-minima.md`](memoria-scheduler-impl-minima.md); **sem** GGUF; hipótese **não** comprovada.
- **Etapa 20:** runtime/shim falando o contrato nativo + harness B com `HARNESS_CONTRACT_*` — [`runtime-contrato-nativo.md`](runtime-contrato-nativo.md); **sem** GGUF em B; hipótese **não** comprovada.
- **Etapa 21–33 (Linha B):** loader BlockIO full → layout → attn/FFN/prefill layer0; bloqueio atual `B_BLOCK=no_gguf_full_prefill` — **sem** Prefill 22L/Decode/`TOKENS_PER_S` em B; veredito harness comparável tipicamente **INCONCLUSIVO**. Contratos: [`runtime-nativo-linha-b.md`](runtime-nativo-linha-b.md), ADR [`0013`](adr/0013-geracao-canonica-fatiada-linha-b.md).
- **Etapa 14 / 23 / 39:** desenho + protocolo Rede v1 + descoberta bootstrap — [`rede-ia-livre-v1.md`](rede-ia-livre-v1.md), [`rede-descoberta-wan.md`](rede-descoberta-wan.md).
- **Etapa 15 / 24 / 40:** autonomia v1 + tool `calc` sandboxed — [`desenho-autonomia-v1.md`](desenho-autonomia-v1.md), [`autonomia-alem-v1.md`](autonomia-alem-v1.md).
- **Etapa 16 / 25 / 38 / 41:** desenho GPU → stub host → nativo mínimo → shard host executado (ou skip).
- **Etapa 18 / 34:** perfis harness A otimizada — [`harness-perfis-a-otimizada-gpu.md`](harness-perfis-a-otimizada-gpu.md).
- **Etapa 35–36:** boot metal (evidência/skip) + GGUF completo opt-in na ESP — [`boot-hardware-real.md`](boot-hardware-real.md), [`gguf-baremetal-midia.md`](gguf-baremetal-midia.md).
- **Etapa 37:** observabilidade mínima GOP/input — [`observabilidade-minima-so.md`](observabilidade-minima-so.md).

## Decisões abertas

- Memória model-aware / scheduler: desenho E13 + impl. mínima E19 + consumidor E20 — **feitos**; prova A vs B com geração em B **aberta**.
- Rede: desenho E14 + v1 E23 + bootstrap E39 — **feitos**; DHT/NAT/relay **abertos**.
- Autonomia: desenho E15 + v1 E24 + `calc` E40 — **feitos**; REPL/`read_local` **abertos**.
- GPU: E8 host + E25 stub + E38 nativo mínimo + E41 shard host (ou skip) — **feitos**; multi-GPU completo / harness GPU **abertos**.
- Harness A vs B: instrumento E22 + A otimizada E34 — **feitos**; hipótese **não** comprovada enquanto `B_BLOCK=no_gguf_full_prefill` (sem `TOKENS_PER_S` em B).
- Licenças: Apache-2.0 (E17) — **feitas**.

Glossário: [`glossario.md`](glossario.md).

## Referências próximas

Estudar como **lacunas**, não como blueprint a copiar: AgentOS, SLM-OS, TensorOS, CLLM — GPU eficiente, multi-GPU completo, KV avançado, multi-tenant.

## Estado do mapa (pós-E41)

| Faixa | Status |
|-------|--------|
| Kernel boot → ExitBoot → MEM_SCHED → obs GOP → GPU nativo | Feito (gates `make verify`) |
| Runtime host CPU/GPU + contrato shim | Feito |
| Linha B proxy + BlockIO + attn/FFN/prefill parcial | Feito; **sem** geração canônica |
| Nó P2P v1 + bootstrap | Feito |
| Autonomia v1 + `calc` | Feito |
| Bare-metal artefato (+ metal/GGUF opt-in) | Feito (metal SKIP sem log PC) |
| Hipótese A vs B com `TOKENS_PER_S` em B | **Aberta** |
