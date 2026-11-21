# Roadmap

Project: https://github.com/users/eriksonlima/projects/1

## Etapa 1 — Fundação do repositório

Status: feita  
Issue: [#1](https://github.com/eriksonlima/projeto-ia-livre/issues/1)  
Spec: _(opcional nesta etapa)_  
Pronto quando: README, AGENTS.md, ROADMAP.md, scaffold `.cursor/` e remote GitHub existem; labels/issues/project criados.

## Etapa 2 — Manifesto Fundador e identidade

Status: feita  
Issue: [#2](https://github.com/eriksonlima/projeto-ia-livre/issues/2)  
Spec: specs/manifesto-fundador/  
Pronto quando: manifesto com missão, princípios imutáveis, nomenclatura (Projeto IA Livre / IA Livre / Rede IA Livre), governança B com proteções e política open source publicados em `docs/`.

## Etapa 3 — Contexto de produto e arquitetura inicial

Status: feita  
Issue: [#3](https://github.com/eriksonlima/projeto-ia-livre/issues/3)  
Spec: specs/arquitetura-inicial/  
Pronto quando: `docs/product-context.md` e `docs/architecture.md` descrevem camadas (kernel, runtime, autonomia, P2P), hipóteses de pesquisa e decisões abertas; ADR inicial se houver escolha estrutural.

## Etapa 4 — Bootstrap do kernel IA Livre

Status: feita  
Issue: [#4](https://github.com/eriksonlima/projeto-ia-livre/issues/4)  
Spec: specs/bootstrap-kernel/  
Pronto quando: boot UEFI em QEMU (x86-64), kernel mínimo em Rust com saída serial verificável; instruções em AGENTS.md.

## Etapa 5 — Runtime mínimo de inferência (CPU)

Status: feita  
Issue: [#5](https://github.com/eriksonlima/projeto-ia-livre/issues/5)  
Spec: specs/runtime-inferencia-cpu/  
Pronto quando: carregar e executar um modelo pequeno em CPU no ambiente do projeto (ou protótipo no host de referência), com métricas básicas documentadas.

## Etapa 6 — Protótipo do nó Rede IA Livre

Status: feita  
Issue: [#6](https://github.com/eriksonlima/projeto-ia-livre/issues/6)  
Spec: specs/no-rede-ia-livre/  
Pronto quando: cliente/nó em SO convencional comunica-se entre dois hosts (ou processos) com descoberta mínima e troca de mensagem documentada; participação sem exigir o SO IA Livre.

## Etapa 7 — Ambiente de autonomia (camada 3)

Status: feita  
Issue: [#7](https://github.com/eriksonlima/projeto-ia-livre/issues/7)  
Spec: specs/ambiente-autonomia/  
Pronto quando: protótipo da camada 3 no host Linux (`std`) com agente mínimo, memória persistente simples e pelo menos uma ferramenta; consome o runtime CPU existente; documentado; gate verificável — sem exigir o kernel UEFI / QEMU.

## Etapa 8 — Aceleração além de CPU (GPU)

Status: feita  
Issue: [#8](https://github.com/eriksonlima/projeto-ia-livre/issues/8)  
Spec: specs/aceleracao-gpu/  
Pronto quando: protótipo de aceleração GPU no host sobre o runtime existente (backend do llama.cpp), com escolha CUDA/Vulkan (ou equivalente suportado) documentada, fallback CPU preservado, métricas comparáveis às da Etapa 5 e gate verificável quando houver GPU — sem exigir o kernel UEFI / QEMU; multi-GPU e GPU manager completo fora de escopo.

## Etapa 9 — Harness da hipótese Linha A vs Linha B

Status: feita  
Issue: [#9](https://github.com/eriksonlima/projeto-ia-livre/issues/9)  
Spec: specs/harness-linha-a-b/  
Pronto quando: harness comparável (mesmo modelo/quantização/carga) documentado para Linha A (Linux otimizado) vs Linha B (IA Livre), sem confundir com métricas dos protótipos CPU/GPU das Etapas 5/8.

## Etapa 10 — Kernel além do boot

Status: feita  
Issue: [#10](https://github.com/eriksonlima/projeto-ia-livre/issues/10)  
Spec: specs/kernel-alem-do-boot/  
Pronto quando: no UEFI/QEMU, mecanismos mínimos além de `IA_LIVRE_BOOT_OK` (ex.: alocação/mapa de memória ou carregamento mínimo documentado), com gate serial verificável — ainda sem inferência no kernel.

## Etapa 11 — Kernel pós-Boot Services

Status: feita  
Issue: [#13](https://github.com/eriksonlima/projeto-ia-livre/issues/13)  
Spec: specs/kernel-pos-boot-services/  
Pronto quando: caminho documentado e verificável no UEFI/QEMU para sair de Boot Services (ou equivalente mínimo) com base estável (mapa preservado / memória utilizável), gate serial — ainda sem inferência no kernel.

## Etapa 12 — Runtime nativo / Linha B real (mínimo)

Status: feita  
Issue: [#11](https://github.com/eriksonlima/projeto-ia-livre/issues/11)  
Spec: specs/runtime-nativo-linha-b/  
Pronto quando: caminho documentado e verificável para a carga canônica do harness emitir `IA_LIVRE_HARNESS_*` com `LINE=B` no ambiente IA Livre (ou stub honestamente substituído por execução real mínima); sem fingir hipótese comprovada.

## Etapa 13 — Lacunas de arquitetura (scheduler / memória model-aware)

Status: feita  
Issue: [#12](https://github.com/eriksonlima/projeto-ia-livre/issues/12)  
Spec: specs/lacunas-arquitetura-scheduler-memoria/  
Pronto quando: desenho (doc/ADR) do mecanismo nativo candidato que diferencia Linha B da A — escopo de desenho, não implementação completa.

## Etapa 14 — Protocolo P2P além do protótipo (stack / identidade)

Status: feita  
Issue: [#14](https://github.com/eriksonlima/projeto-ia-livre/issues/14)  
Spec: specs/protocolo-p2p-alem-prototipo/  
Pronto quando: escolha documentada (ADR/doc) da stack candidata (transporte, identidade, descoberta além de HELLO/MSG/ACK) e fronteira do próximo protótipo — sem marketplace nem integração runtime/kernel.

## Etapa 15 — Ambiente de autonomia além do protótipo (v1 utilizável)

Status: feita  
Issue: [#15](https://github.com/eriksonlima/projeto-ia-livre/issues/15)  
Spec: specs/autonomia-v1-utilizavel/  
Pronto quando: escopo documentado da primeira versão utilizável da camada 3 e critério verificável mínimo — ainda no host, sem exigir o SO IA Livre.

## Etapa 16 — GPU manager no kernel / multi-GPU (desenho)

Status: feita  
Issue: [#16](https://github.com/eriksonlima/projeto-ia-livre/issues/16)  
Spec: specs/gpu-manager-multi-gpu-desenho/  
Pronto quando: desenho (ADR/doc) do escopo candidato de GPU manager no kernel e multi-GPU — fronteira vs aceleração host (ADR 0002); desenho, não implementação completa.

## Etapa 17 — Licenças definitivas por componente

Status: feita  
Issue: [#17](https://github.com/eriksonlima/projeto-ia-livre/issues/17)  
Spec: specs/licencas-por-componente/  
Pronto quando: licença por componente (kernel, runtime, node, agent, docs) registrada no repositório, alinhada ao manifesto.

## Etapa 18 — Evolução do harness (Linha A otimizada / perfil GPU)

Status: feita  
Issue: [#18](https://github.com/eriksonlima/projeto-ia-livre/issues/18)  
Spec: specs/evolucao-harness-linha-a-gpu/  
Pronto quando: metodologia documentada para «Linux otimizado» na Linha A e/ou perfil GPU espelhado A/B; gate só se houver execução real.

## Etapa 19 — Memória model-aware + scheduler por fases (impl. mínima)

Status: feita  
Issue: [#19](https://github.com/eriksonlima/projeto-ia-livre/issues/19)  
Spec: specs/memoria-scheduler-impl-minima/  
Pronto quando: contrato mínimo verificável no kernel pós-ExitBoot — allocator tipado `Weights`/`KvCache`, hints Prefill/Decode com política de quantum mínima e marcadores serial; `make verify` (ou extensão documentada) cobre o caminho; sem GGUF; sem prova da hipótese; sem ABI estável/multi-tenant/GPU manager.

## Etapa 20 — Runtime falando o contrato nativo (além do proxy Linha B)

Status: feita  
Issue: [#20](https://github.com/eriksonlima/projeto-ia-livre/issues/20)  
Spec: specs/runtime-contrato-nativo/  
Pronto quando: runtime (host e/ou caminho nativo) com evidência verificável de uso do contrato `Weights`/`KvCache` e/ou phase hints; harness B atualizado honestamente (sem fingir `TOKENS_PER_S` GGUF se ainda não houver); hipótese **não** comprovada; sem GPU manager. Depende da Etapa 19 (contrato no kernel).

## Etapa 21 — Carga GGUF canônica na Linha B (mínimo honesto)

Status: feita  
Issue: [#21](https://github.com/eriksonlima/projeto-ia-livre/issues/21)  
Spec: specs/carga-gguf-linha-b/  
Pronto quando: caminho mínimo da carga canônica do harness (TinyLlama Q4_K_M) na Linha B (QEMU/IA Livre) emite métricas B em espécie comparáveis às de A, **ou** bloqueio honesto documentado; gate harness atualizado sem inventar números; hipótese **não** comprovada; sem GPU manager. Depende das Etapas 19/20.

## Etapa 22 — Harness A vs B comparável (prova ou refutação da hipótese)

Status: feita  
Issue: [#22](https://github.com/eriksonlima/projeto-ia-livre/issues/22)  
Spec: specs/harness-a-b-comparavel/  
Pronto quando: corrida lado a lado documentada (mesmo modelo/quantização/carga) com resultado comprova, refuta ou inconclusivo; sem vitória sem evidência. Depende da Etapa 21.

## Etapa 23 — Protocolo Rede IA Livre v1 (impl. em node/)

Status: feita  
Issue: [#23](https://github.com/eriksonlima/projeto-ia-livre/issues/23)  
Spec: specs/protocolo-rede-v1/  
Pronto quando: contratos do desenho ADR 0004 cobertos em `node/` — ed25519/PeerId, HELLO UDP assinado, IDENT no TCP, MSG/ACK, PING/PONG, dial `--peer`; `make verify-node` (ou extensão documentada) verde; participação **sem** exigir o SO IA Livre; sem libp2p/NAT/DHT/marketplace.

## Etapa 24 — Autonomia v1 utilizável (impl. em agent/)

Status: feita  
Issue: [#24](https://github.com/eriksonlima/projeto-ia-livre/issues/24)  
Spec: specs/autonomia-v1-impl/  
Pronto quando: implementação no host em `agent/` com `--prompt` one-shot, allowlist `note`/`recall`/`help`, política de memória N=8 no prompt, cenário de prova com ≥2 ferramentas e marcadores (`IA_LIVRE_MEMORY_POLICY_OK` + evidência de ferramentas); `make verify-agent` preservado ou estendido documentado; sem exigir SO IA Livre; sem shell/HTTP/REPL/RAG.

## Etapa 25 — GPU manager / multi-GPU (protótipo mínimo)

Status: feita  
Issue: [#25](https://github.com/eriksonlima/projeto-ia-livre/issues/25)  
Spec: specs/gpu-manager-multi-gpu-prototipo/  
Pronto quando: primeiro protótipo mínimo alinhado ao desenho ADR 0006 (enum/afinidade/placement e/ou shard documentado), com fronteira clara host vs nativo; caminho verificável documentado; gate ou skip honesto (sem fingir aceleração); sem prova A vs B via multi-GPU; sem clusters/RDMA/tensor parallel completo.

## Etapa 26 — Loader GGUF nativo mínimo na Linha B (desbloquear no_gguf_path)

Status: feita  
Issue: [#26](https://github.com/eriksonlima/projeto-ia-livre/issues/26)  
Spec: specs/loader-gguf-nativo-linha-b/  
Pronto quando: caminho verificável para o GGUF canônico (ou bytes/cabeçalho do modelo) chegar ao ambiente Linha B (QEMU/IA Livre pós-ExitBoot) com I/O mínimo documentado e evidência de progresso do loader (`GGUF_NATIVE_LOADER` ≠ `absent` ou marcadores intermediários honestos); gate harness atualizado sem inventar `TOKENS_PER_S` se ainda não houver geração; hipótese **não** comprovada; sem inferência completa obrigatória nesta etapa; sem GPU manager.

## Etapa 27 — Inferência mínima / TOKENS_PER_S na Linha B (após loader)

Status: feita  
Issue: [#27](https://github.com/eriksonlima/projeto-ia-livre/issues/27)  
Spec: specs/inferencia-minima-linha-b/  
Pronto quando: geração mínima na Linha B com a carga canônica (ou caminho intermediário documentado) emitindo `TOKENS_PER_S` / `LOAD_S` **medidos** comparáveis em espécie aos de A, **ou** bloqueio honesto novo documentado; gates harness atualizados sem inventar números; hipótese só deixa `INCONCLUSIVO` com evidência real; depende da Etapa 26 (loader).  
**Desfecho:** fatia A mínima — GGUF completo via BlockIO + stub tensores; `B_BLOCK=no_gguf_infer_engine` (sem motor/`TOKENS_PER_S`).

## Etapa 28 — Re-corrida harness A vs B quieta (COMPROVA/REFUTA ou INCONCLUSIVO limpo)

Status: feita  
Issue: [#28](https://github.com/eriksonlima/projeto-ia-livre/issues/28)  
Spec: specs/recorrida-harness-quieta/  
Pronto quando: procedimento de medição serial/quieto documentado; corrida A+B verificável sob esse protocolo; `VERDICT` honesto (`COMPROVA`/`REFUTA`/`INCONCLUSIVO`) sem contenção de benchmarks concorrentes; sem inventar `TOKENS_PER_S` em B enquanto `no_gguf_infer_engine`.  
**Desfecho:** protocolo + preflight + evidência quieta; `VERDICT=INCONCLUSIVO` (sem motor B).

## Etapa 29 — Motor de inferência GGUF mínimo na Linha B

Status: feita  
Issue: [#29](https://github.com/eriksonlima/projeto-ia-livre/issues/29)  
Spec: specs/motor-inferencia-linha-b/  
Pronto quando: geração mínima na Linha B (QEMU/IA Livre) com a carga canônica emitindo `TOKENS_PER_S` / `LOAD_S` **medidos** comparáveis em espécie aos de A; harness B + comparable atualizados sem inventar números; ADR 0001 respeitado (runtime nativo fora do kernel); ou bloqueio honesto novo documentado; depende do loader E26/E27.  
**Desfecho:** crate `runtime-native` + layout GGUF verificável; `B_BLOCK=no_gguf_forward` (sem forward/TOKENS); hipótese INCONCLUSIVO.

## Etapa 30 — Boot/imagem IA Livre em hardware real (USB/ESP)

Status: feita  
Issue: [#30](https://github.com/eriksonlima/projeto-ia-livre/issues/30)  
Spec: specs/boot-hardware-real/  
Pronto quando: caminho documentado e verificável para boot do kernel em hardware UEFI real (imagem USB/ESP ou equivalente) **ou** bloqueio honesto documentado; separado da hipótese A vs B / sem fingir `TOKENS_PER_S`; não exige motor de inferência em B.  
**Desfecho:** artefato ESP+tar + `verify-baremetal` (`IMAGE_OK`); hardware = checklist + `BAREMETAL_SKIP`; QEMU ≠ metal.

## Etapa 31 — Forward GGUF mínimo em runtime-native (TOKENS_PER_S na Linha B)

Status: feita  
Issue: [#31](https://github.com/eriksonlima/projeto-ia-livre/issues/31)  
Spec: specs/forward-gguf-linha-b/  
Pronto quando: geração canônica na Linha B (QEMU) com `LOAD_KIND=gguf` + `TOKENS_PER_S`/`LOAD_S` **medidos** (carga TinyLlama Q4_K_M, prompt/`n-predict` canônicos, CPU) **ou** bloqueio honesto novo documentado; ADR 0001; harness atualizado sem inventar números; depende do layout E29 (`no_gguf_forward`).  
**Desfecho:** mapa + dequant Q4_K + op parcial; `B_BLOCK=no_gguf_generate` (sem Prefill/Decode/sampling); hipótese INCONCLUSIVO.

## Etapa 32 — Geração canônica Prefill+Decode+sampling na Linha B (TOKENS_PER_S)

Status: feita  
Issue: [#42](https://github.com/eriksonlima/projeto-ia-livre/issues/42)  
Spec: specs/geracao-canonica-linha-b/  
Pronto quando: geração canônica no guest com `LOAD_KIND=gguf` + `TOKENS_PER_S`/`LOAD_S` medidos (TinyLlama Q4_K_M, prompt/`n-predict=32`, CPU) + `RUNTIME_NATIVE_OK`; harness atualizado; **ou** bloqueio honesto novo com avanço além de `no_gguf_generate`; ADR 0001; depende Etapa 31.  
**Desfecho:** tokenize + embed `token_embd` + camada parcial `attn_output`; `B_BLOCK=no_gguf_decode`; hipótese `INCONCLUSIVO`.

## Etapa 33 — Re-corrida harness A vs B com geração real em B

Status: feita  
Issue: [#32](https://github.com/eriksonlima/projeto-ia-livre/issues/32)  
Spec: `specs/recorrida-harness-geracao-b/`  
Pronto quando: `verify-harness-comparable` quieto com `COMPROVA`/`REFUTA` **ou** `INCONCLUSIVO` só com motivo ≠ ausência de tokens B; depende de geração real em B (além de `no_gguf_decode`) **ou** bloqueio honesto documentado se tokens ainda inviáveis sem fraude.  
**Desfecho:** attn+FFN+prefill layer0; `B_BLOCK=no_gguf_full_prefill`; comparable `INCONCLUSIVO` / `E33_no_gguf_full_prefill_22L_kv_inviable`.

## Etapa 34 — Baseline Linha A otimizada (CPU) no gate comparável

Status: feita  
Issue: [#33](https://github.com/eriksonlima/projeto-ia-livre/issues/33)  
Spec: specs/baseline-a-otimizada/  
Pronto quando: perfil `A_otimizada` documentado + corrida verificável lado a lado; ideal após geração B, mas pode avançar baseline A independentemente.  
**Desfecho:** `run-harness-line-a-optimized.sh` + `make verify-harness-a-otimizada`; comparable opt-in `IA_LIVRE_HARNESS_A_PROFILE=A_otimizada`.

## Etapa 35 — Boot UEFI em hardware real (evidência serial)

Status: feita  
Issue: [#34](https://github.com/eriksonlima/projeto-ia-livre/issues/34)  
Spec: specs/boot-uefi-hardware-real/  
Pronto quando: evidência em PC real com ≥ `BOOT_OK` (ideal `EXIT_BOOT_OK`) via serial; sem fingir CI de metal.  
**Desfecho:** contrato + gate `METAL_OK`/`SKIP`; sem log de PC nesta máquina → skip honesto na issue.

## Etapa 36 — GGUF canônico completo em mídia bare-metal (+ path I/O)

Status: feita  
Issue: [#35](https://github.com/eriksonlima/projeto-ia-livre/issues/35)  
Spec: specs/gguf-baremetal-midia/  
Pronto quando: modelo/path documentado na mídia/metal com loader verificável; deps E35.  
**Desfecho:** `FULL_GGUF=1` → `model.gguf` + `BAREMETAL_GGUF_OK`; doc modos a/b + glue SimpleFileSystem.

## Etapa 37 — Observabilidade mínima no SO (além de UART-only)

Status: feita  
Issue: [#36](https://github.com/eriksonlima/projeto-ia-livre/issues/36)  
Spec: specs/observabilidade-minima-so/  
Pronto quando: caminho mínimo (GOP text ou input) + marcador de prova; sem desktop.  
**Desfecho:** GOP fill+bitmap `IA Livre` + `GOP_OK`/`OBS_OK` pré-exit; gate aditivo; fallback input documentado.

## Etapa 38 — GPU manager nativo (mecanismos kernel ↔ runtime)

Status: feita  
Issue: [#37](https://github.com/eriksonlima/projeto-ia-livre/issues/37)  
Spec: specs/gpu-manager-nativo/  
Pronto quando: enum/afinidade/placement mínimo pós-ExitBoot verificável; sem fingir multi-GPU completo.  
**Desfecho:** `GPU_MGR=native` + enum sintética + afinidade/placement pós-`MEM_SCHED_OK`; stub E25 intacto.

## Etapa 39 — Rede IA Livre além de v1 (descoberta WAN mínima)

Status: feita  
Issue: [#38](https://github.com/eriksonlima/projeto-ia-livre/issues/38)  
Spec: specs/rede-descoberta-wan/  
Pronto quando: descoberta além de `--peer`/HELLO LAN + gate; sem exigir SO.  
**Desfecho:** `--bootstrap` + `DISC_OK` no gate; regressão `--peer`; mDNS skip honesto.

## Etapa 40 — Autonomia além de v1 (REPL ou tool sandboxed)

Status: feita  
Issue: [#39](https://github.com/eriksonlima/projeto-ia-livre/issues/39)  
Spec: specs/autonomia-alem-v1/  
Pronto quando: REPL ou ≥1 tool nova sandboxed + gate; sem shell/HTTP irrestrito.  
**Desfecho:** tool `calc` sandboxed + `TOOL_SANDBOX_OK` no gate; REPL adiado.

## Etapa 41 — Shard multi-GPU host executado (além do stub)

Status: feita  
Issue: [#40](https://github.com/eriksonlima/projeto-ia-livre/issues/40)  
Spec: specs/shard-multi-gpu-host/  
Pronto quando: placement/shard mínimo real no host com evidência ou skip honesto; ≠ manager nativo.  
**Desfecho:** `host_shard_exec` + plano pipeline; skip `need_2_devices` honesto neste host; stub E25 intacto.

## Etapa 42 — Sincronizar architecture/product + glossário pós-E30

Status: feita  
Issue: [#41](https://github.com/eriksonlima/projeto-ia-livre/issues/41)  
Spec: specs/sync-architecture-glossario/  
Pronto quando: `architecture.md` / README-AGENTS refletem estado atual sem ambiguidade.  
**Desfecho:** glossário + architecture/product/README alinhados a E30–E41; backlog Abertas vazio.

## Etapa 43 — Prefill completo 22L + KV cache viável na Linha B

Status: feita  
Issue: [#43](https://github.com/eriksonlima/projeto-ia-livre/issues/43)  
Spec: specs/prefill-22l-kv-linha-b/  
Pronto quando: prefill das 22 camadas TinyLlama (ou subset documentado equivalente) + KV alocado/viável no QEMU Linha B, com marcadores serial; **sem** fingir `TOKENS_PER_S` ainda.  
**Desfecho:** subset ADR 0014 — `PREFILL_LAYERS=2`×`KV_N_POS=2` + `KV_CACHE_OK`/`PREFILL_PARTIAL_OK`; host 2L×16; `B_BLOCK=no_gguf_prefill_22l`; comparable `E43_no_gguf_prefill_22l_subset_kv_ok`; sem `TOKENS_PER_S`.

## Etapa 44 — Decode + sampling + TOKENS_PER_S canônico na Linha B

Status: feita  
Issue: [#44](https://github.com/eriksonlima/projeto-ia-livre/issues/44)  
Spec: specs/decode-tokens-linha-b/  
Pronto quando: geração canônica em B emite `TOKENS_PER_S` (e marcadores Decode/sampling) honestos; `B_BLOCK` removido ou substituído; gate harness B atualizado.  
**Desfecho:** Decode greedy subset 2L×`n_predict=1` + `TOKENS_PER_S` medidos; `LOAD_KIND=gguf`; `PROFILE=release`; comparable `INCONCLUSIVO` (espécie ≠ A); ADR 0015; sem `B_BLOCK` no sucesso.

## Etapa 45 — Re-corrida harness A vs B com geração real (veredito limpo)

Status: feita  
Issue: [#45](https://github.com/eriksonlima/projeto-ia-livre/issues/45)  
Spec: specs/recorrida-harness-veredito-limpo/  
Pronto quando: `make verify-harness-comparable` com B gerando; veredito ∈ {COMPROVA, REFUTA, INCONCLUSIVO} **sem** reason de proxy/`no_gguf_full_prefill`/subset-espécie; metodologia quieta preservada.  
**Desfecho:** ADR 0016; B gera; comparable `INCONCLUSIVO` / `E45_perf_ceiling_below_canonical_layers=2_npredict=1` (22L×32 inviável no gate); sem COMPROVA forçado.

## Etapa 46 — Evidência de boot metal real (serial ≥ BOOT_OK em PC)

Status: feita  
Issue: [#46](https://github.com/eriksonlima/projeto-ia-livre/issues/46)  
Spec: specs/evidencia-boot-metal-real/  
Pronto quando: log serial de PC real em `docs/evidence/boot-metal/` + `IA_LIVRE_BAREMETAL_METAL_OK` no gate; Secure Boot/checklist documentados.  
**Desfecho:** caminho B — sem PC/log neste host; `SKIP=1` + `STATUS-SKIP.txt`; checklist A/B documentado; `METAL_OK` pendente de evidência real.

## Etapa 47 — One-shot gravar pendrive UEFI (script + doc)

Status: feita  
Issue: [#47](https://github.com/eriksonlima/projeto-ia-livre/issues/47)  
Spec: specs/gravar-pendrive-uefi/  
Pronto quando: script ou procedimento único (detecta device com confirmação, grava ESP/FAT ou `.img`) + README/AGENTS; **sem** gravar `/dev/sdX` sem confirmação explícita.  
**Desfecho:** `write-usb-esp.sh` + `make verify-write-usb` (`IA_LIVRE_WRITE_USB_OK`); confirmação obrigatória; ≠ METAL_OK.

## Etapa 48 — Inferência mínima no metal (GGUF ESP → geração ou bloqueio honesto)

Status: feita  
Issue: [#48](https://github.com/eriksonlima/projeto-ia-livre/issues/48)  
Spec: specs/inferencia-minima-metal/  
Pronto quando: no PC (ou QEMU espelhando path metal), após boot USB/ESP com `model.gguf`, caminho nativo emite geração mínima **ou** `B_BLOCK`/`metal` honesto documentado; sem `TOKENS_PER_S` fingido.  
**Desfecho:** ADR 0017; QEMU ESP-only → `GGUF_PATH=esp_sfs` + `B_BLOCK_METAL=no_gguf_metal_io`; `make verify-metal-infer`; sem TOKENS fingidos; ≠ METAL_OK.

## Etapa 49 — Autonomia mínima no caminho nativo (ou bridge SO↔host)

Status: feita  
Issue: [#49](https://github.com/eriksonlima/projeto-ia-livre/issues/49)  
Spec: specs/autonomia-bridge-nativo/  
Pronto quando: agente one-shot (ou bridge verificável) consome runtime nativo/metal **ou** contrato explícito host↔nativo com gate; sem shell irrestrito; ADR 0001 preservada.  
**Desfecho:** ADR 0018 (bridge B); `BRIDGE_MODE=host_native` + `blockio`/`metal_block` + `BRIDGE_OK`; `make verify-autonomia-bridge`; `verify-agent` independente do SO.

## Etapa 50 — mDNS real na Rede IA Livre (além do skip)

Status: feita  
Issue: [#50](https://github.com/eriksonlima/projeto-ia-livre/issues/50)  
Spec: specs/mdns-rede-ia-livre/  
Pronto quando: `--disc-mdns` anuncia/resolve `_ia-livre._tcp` em LAN com gate opt-in; skip honesto se multicast indisponível.  
**Desfecho:** `mdns-sd` + `_ia-livre._tcp`; `DISC_MODE=mdns` + `DISC_OK`; gate skip default / `VERIFY_NODE_MDNS_SKIP=0` prova; sem libp2p.

## Etapa 51 — Tarefa/conhecimento mínimo na Rede (além de PING)

Status: feita  
Issue: [#51](https://github.com/eriksonlima/projeto-ia-livre/issues/51)  
Spec: specs/tarefa-conhecimento-rede/  
Pronto quando: tipo de mensagem v1 (`TASK` + `TASK_ACK`) + ACK correspondente + gate de dois nós; sem marketplace; sem exigir SO.  
**Desfecho:** `TASK t1 prova-task-v1` / `TASK_ACK t1` → `IA_LIVRE_TASK_OK`; `make verify-node` exige TASK_OK; KNOW/marketplace fora.

## Etapa 52 — Nó Rede no SO nativo (pós-ExitBoot ou bridge)

Status: feita  
Issue: [#52](https://github.com/eriksonlima/projeto-ia-livre/issues/52)  
Spec: specs/no-rede-so-nativo/  
Pronto quando: stack TCP mínima no kernel/runtime-native **ou** bridge documentada UEFI↔host com marcadores; participação na Rede a partir do caminho B; ADR 0001 (host continua válido).  
**Desfecho:** ADR 0019 (bridge B); `NET_BRIDGE_MODE=host_uefi` + `serial_exit` + `NET_BRIDGE_OK` (âncora `TASK_OK`); `make verify-rede-bridge`; TCP nativo adiado; `verify-node` independente.

## Etapa 53 — REPL sandboxed no agente (host)

Status: feita  
Issue: [#53](https://github.com/eriksonlima/projeto-ia-livre/issues/53)  
Spec: specs/repl-sandboxed-agente/  
Pronto quando: `--repl` com allowlist; modo scripted para `verify-agent`; sem shell/HTTP.  
**Desfecho:** `--repl` / `--repl-script`; `REPL_MODE=scripted` + `REPL_OK`; `make verify-agent` estágio fixture; sem shell/HTTP.

## Etapa 54 — Tool `read_local` allowlisted (host)

Status: feita  
Issue: [#54](https://github.com/eriksonlima/projeto-ia-livre/issues/54)  
Spec: specs/read-local-allowlisted/  
Pronto quando: leitura só sob allowlist de paths; rejeição honesta fora; gate; sem write arbitrário.  
**Desfecho:** `read_local` roots `agent/fixtures`+`build/agent-memory`; `READ_LOCAL_OK`; rejeição honesta; prova+REPL no `verify-agent`.

## Etapa 55 — GPU real no caminho nativo (além de `synthetic`)

Status: feita  
Issue: [#55](https://github.com/eriksonlima/projeto-ia-livre/issues/55)  
Spec: specs/gpu-real-nativo/  
Pronto quando: detecção/placement com GPU real (PCI/pass-through ou host path documentado) **ou** skip `need_gpu` honesto; ≠ stub E25; sem fingir multi-GPU.  
**Desfecho:** path B `SRC=host` + `GPU_REAL_OK` (ou `NEED_GPU`); `make verify-gpu-native-real`; ≠ synthetic/E25; E38 intacto.

## Etapa 56 — Perfil harness GPU espelhado A/B (quando B gerar)

Status: feita  
Issue: [#56](https://github.com/eriksonlima/projeto-ia-livre/issues/56)  
Spec: specs/harness-perfil-gpu-ab/  
Pronto quando: corrida A/B com perfil GPU documentado e métricas honestas; skip se sem GPU; deps geração em B.  
**Desfecho:** `A_gpu` (vulkan/cuda) + B subset → `INCONCLUSIVO`; `make verify-harness-gpu`; skip sem GPU; sem ACCEL fingido em B.

## Etapa 57 — Guia “primeiro boot USB” + release de artefato

Status: feita  
Issue: [#57](https://github.com/eriksonlima/projeto-ia-livre/issues/57)  
Spec: specs/guia-primeiro-boot-usb-release/  
Pronto quando: guia passo a passo (Secure Boot, serial, o que esperar) + tag/release com ESP/tar/checksums; sem declarar hipótese comprovada.  
**Desfecho:** `docs/guia-primeiro-boot-usb.md` + `prepare-baremetal-release.sh` + `SHA256SUMS`; `make verify-boot-guide-release`; hipótese INCONCLUSIVO explícita.

## Etapa 58 — Definição verificável de “protótipo objetivo atingido”

Status: feita  
Issue: [#58](https://github.com/eriksonlima/projeto-ia-livre/issues/58)  
Spec: specs/prototipo-objetivo-atingido/  
Pronto quando: checklist em `docs/` (hipótese A/B decidível **ou** bloqueio honesto final; USB metal com boot+IA mínima; Rede+autonomia host verdes) + espelho no ROADMAP/Memory Bank; celebrar só com evidência.  
**Desfecho:** [`docs/prototipo-objetivo-atingido.md`](docs/prototipo-objetivo-atingido.md) — 3 pilares; pilar 1 `INCONCLUSIVO` (espécie subset); pilar 2 sem `METAL_OK` até log PC; pilar 3 verde (Rede+autonomia host). Gate `make verify-prototipo-objetivo` → `IA_LIVRE_PROTOTIPO_OBJETIVO_OK` (sem fingir `COMPROVA`). Celebrar só com evidência.

## Etapa 59 — Otimizar runtime-native (SIMD/teto) para espécie canônica

Status: feita  
Issue: [#59](https://github.com/eriksonlima/projeto-ia-livre/issues/59)  
Spec: specs/otimizar-runtime-native-especie/  
Pronto quando: medição documentada (passo intermediário N≥8 / n_predict≥8 **ou** 22L×32 no timeout do gate) **ou** ADR nova pós-otimização declara inviável com evidência; sem fingir `COMPROVA`; hipótese permanece aberta até B54.  
**Desfecho:** fused matvec Q4 + dispatch Q4/Q6 (~7–10% host); host N=8 ok (~2 s); guest passo intermediário **inviável** no gate 600 s → ADR [`0020`](docs/adr/0020-runtime-native-passo-intermediario-inviavel.md); `make verify-runtime-native-perf`; hipótese aberta (B54).

## Etapa 60 — Espécie canônica Linha B (22L × n_predict=32)

Status: feita  
Issue: [#60](https://github.com/eriksonlima/projeto-ia-livre/issues/60)  
Spec: specs/especie-canonica-linha-b/  
Pronto quando: `make verify-harness-comparable` com B `PREFILL_LAYERS=22` + `N_PREDICT=32` + veredito ∈ {COMPROVA,REFUTA,INCONCLUSIVO} **sem** reason de teto/subset; **ou** ADR nova (0021) declara espécie canônica inviável no gate atual (pós-E59/0020) com ponte a B58; sem fingir `COMPROVA`.  
**Desfecho:** ADR [`0021`](docs/adr/0021-especie-canonica-linha-b-inviavel.md) — canônico inviável no gate (pós 0020); comparable permanece teto/`INCONCLUSIVO`; ponte B58; sem `COMPROVA` fingido. README considerado (só docs/AGENTS).

## Etapa 61 — Bloqueio final documentado da hipótese A/B

Status: feita  
Issue: [#64](https://github.com/eriksonlima/projeto-ia-livre/issues/64)  
Spec: specs/bloqueio-final-hipotese-ab/  
Pronto quando: ADR/doc declara espécie/hipótese **terminalmente** inviável no gate atual (ou caminho reaberto explícito); instrumento comparable honesto; checklist E58 pilar 1 atualizado; sem fingir COMPROVA.  
**Desfecho:** ADR [`0022`](docs/adr/0022-bloqueio-final-hipotese-ab.md) — pilar 1 = `BLOQUEIO_FINAL`; comparable permanece teto/`INCONCLUSIVO`; `make verify-prototipo-objetivo` exige 0022; reabertura documentada; sem `COMPROVA`.

## Etapa 62 — Evidência METAL_OK em PC real

Status: feita  
Issue: [#62](https://github.com/eriksonlima/projeto-ia-livre/issues/62)  
Spec: specs/evidencia-metal-ok/  
Pronto quando: log real em `docs/evidence/boot-metal/` + `IA_LIVRE_BAREMETAL_SKIP=0` → `METAL_OK` (≥ `BOOT_OK`, sem QEMU/OVMF); **ou** bloqueio honesto documentado sem fabricar log.  
**Desfecho:** bloqueio honesto — `STATUS-SKIP` (`no_pc_serial_log_on_this_host`); **sem** `METAL_OK` fabricado; operador pode reabrir com log real (`TEMPLATE.txt`).

## Etapa 63 — I/O GGUF no path metal (além de no_gguf_metal_io)

Status: feita  
Issue: [#63](https://github.com/eriksonlima/projeto-ia-livre/issues/63)  
Spec: specs/io-gguf-path-metal/  
Pronto quando: no path metal (SFS/ESP — QEMU FAT32 ou PC), loader full **ou** geração mínima com marcadores; **ou** bloqueio/ADR honesto se I/O full continuar inviável; sem `TOKENS` fingidos; ≠ tratar BlockIO como metal; ≠ `METAL_OK` fabricado.  
**Desfecho:** ramo **A** — FAT32 `.img` + `run-qemu-esp-fat32.sh` + loader `esp_sfs_full` (GGUF ~638 MiB via SFS); `make verify-metal-infer` (auto/full); `make verify` BlockIO intacto; ≠ `METAL_OK`; bridge E49 força legacy para `metal_block`.  

## Etapa 64 — Accel GPU simétrica A/B no harness

Status: feita  
Issue: [#73](https://github.com/eriksonlima/projeto-ia-livre/issues/73)  
Spec: specs/harness-accel-simetrico-ab/  
Pronto quando: corrida A/B com o **mesmo** perfil de aceleração (ambos GPU ou ambos CPU documentado); skip sem GPU; **proibido** `ACCEL` fingido em B; veredito honesto (tipicamente `INCONCLUSIVO` até espécie/GPU guest); ≠ `COMPROVA` fabricado.  
**Desfecho:** perfil `sym_cpu` + `make verify-harness-sym-cpu`; ADR [`0023`](docs/adr/0023-simetria-gpu-harness-inviavel.md) (simetria GPU inviável até B60); E56 permanece assimétrico; sem ACCEL fingido em B; sem `COMPROVA`.  

## Etapa 65 — GPU real no guest (PCI/pass-through)

Status: feita  
Issue: [#65](https://github.com/eriksonlima/projeto-ia-livre/issues/65)  
Spec: specs/gpu-guest-passthrough/  
Pronto quando: `GPU_REAL_SRC=pci_passthrough` (ou equiv.) + `GPU_REAL_OK` **ou** skip `need_gpu`/`need_vfio`; ≠ só enum host.  
**Desfecho:** contrato [`docs/gpu-guest-passthrough.md`](docs/gpu-guest-passthrough.md) + `make verify-gpu-guest-passthrough`; neste host tipicamente `need_vfio`/`need_gpu` (sem inventar passthrough); E55 `SRC=host` intacto; ADR 0023 permanece até VFIO real.  

## Etapa 66 — Stack TCP Rede nativa no guest

Status: feita  
Issue: [#66](https://github.com/eriksonlima/projeto-ia-livre/issues/66)  
Spec: specs/tcp-rede-guest/  
Pronto quando: sessão Rede no caminho B + marcadores; `verify-node` host intacto (ADR 0001).  
**Desfecho:** ADR [`0024`](docs/adr/0024-tcp-rede-guest-inviavel.md) — TCP guest inviável (UART-only); `NET_GUEST_BLOCK=no_tcp_post_exit` + bridge E52; `make verify-rede-guest`; sem `NET_NATIVE_OK` fingido.  

## Etapa 67 — Descoberta WAN (NAT/DHT/relay)

Status: feita  
Issue: [#67](https://github.com/eriksonlima/projeto-ia-livre/issues/67)  
Spec: specs/descoberta-wan-dht-relay/  
Pronto quando: DHT **ou** relay verificável + gate/skip; sem libp2p monólito sem ADR.  
**Desfecho:** relay intro TCP (`RELAY_HINT`) + `DISC_MODE=relay` / `RELAY_OK`; `make verify-node-relay`; DHT adiado; loopback ≠ WAN pública; `verify-node` intacto.  

## Etapa 68 — Mensagem KNOW na Rede

Status: feita  
Issue: [#68](https://github.com/eriksonlima/projeto-ia-livre/issues/68)  
Spec: specs/mensagem-know-rede/  
Pronto quando: `KNOW`(+ACK) + gate dois nós; sem marketplace; sem exigir SO.  
**Desfecho:** `KNOW k1 prova-know-v1` / `KNOW_ACK` → `IA_LIVRE_KNOW_OK`; `make verify-node` exige KNOW; sem marketplace/store.  

## Etapa 69 — Multi-GPU completo além do shard host

Status: feita  
Issue: [#69](https://github.com/eriksonlima/projeto-ia-livre/issues/69)  
Spec: specs/multi-gpu-completo-host/  
Pronto quando: placement/execução multi-device real com evidência; sem fingir.  
**Desfecho:** `host_multi` + placement dual `W:0,K:1` + `make verify-gpu-multi`; neste host tipicamente `need_2_devices` (1×1050); E41 shard intacto; sem TOKENS.

## Etapa 70 — Autonomia consumindo runtime/evidência nativa

Status: feita  
Issue: [#70](https://github.com/eriksonlima/projeto-ia-livre/issues/70)  
Spec: specs/autonomia-nativa/  
Pronto quando: one-shot que consome fonte nativa **ou** contrato “bridge = máximo até X”; ADR 0001 preservada (`verify-agent` independente do SO).  
**Desfecho:** A — `host_bridge` + note/recall de `BRIDGE_NATIVE_SRC` + `make verify-autonomia-nativa`; fixture blockio; `verify-agent`/`verify-autonomia-bridge` intactos; sem agente no guest.

## Etapa 71 — ABI mínima estável kernel↔runtime-native

Status: em_andamento  
Issue: [#71](https://github.com/eriksonlima/projeto-ia-livre/issues/71)  
Spec: specs/abi-runtime-native/  
Pronto quando: contrato versionado documentado + consumidor nativo; sem puxar inferência pro kernel (ADR 0001/0003).

