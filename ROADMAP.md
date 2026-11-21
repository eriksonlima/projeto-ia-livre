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

Status: em_andamento  
Issue: [#21](https://github.com/eriksonlima/projeto-ia-livre/issues/21)  
Spec: specs/carga-gguf-linha-b/  
Pronto quando: caminho mínimo da carga canônica do harness (TinyLlama Q4_K_M) na Linha B (QEMU/IA Livre) emite métricas B em espécie comparáveis às de A, **ou** bloqueio honesto documentado; gate harness atualizado sem inventar números; hipótese **não** comprovada; sem GPU manager. Depende das Etapas 19/20.

## Etapa 22 — Harness A vs B comparável (prova ou refutação da hipótese)

Status: pendente  
Issue: [#22](https://github.com/eriksonlima/projeto-ia-livre/issues/22)  
Spec: specs/harness-a-b-comparavel/  
Pronto quando: corrida lado a lado documentada (mesmo modelo/quantização/carga) com resultado comprova, refuta ou inconclusivo; sem vitória sem evidência. Depende da Etapa 21.

## Etapa 23 — Protocolo Rede IA Livre v1 (impl. em node/)

Status: pendente  
Issue: [#23](https://github.com/eriksonlima/projeto-ia-livre/issues/23)  
Spec: specs/protocolo-rede-v1/  
Pronto quando: contratos do desenho Rede v1 em `node/` + gate `verify-node` (ou extensão); sem marketplace; independente do SO.

## Etapa 24 — Autonomia v1 utilizável (impl. em agent/)

Status: pendente  
Issue: [#24](https://github.com/eriksonlima/projeto-ia-livre/issues/24)  
Spec: specs/autonomia-v1-impl/  
Pronto quando: prova v1 com ≥2 ferramentas + marcadores de política; `verify-agent` preservado/estendido; host only.

## Etapa 25 — GPU manager / multi-GPU (protótipo mínimo)

Status: pendente  
Issue: [#25](https://github.com/eriksonlima/projeto-ia-livre/issues/25)  
Spec: specs/gpu-manager-prototipo/  
Pronto quando: caminho verificável de manager/afinidade/placement e/ou shard documentado; skip/gate honesto; sem prova A vs B via multi-GPU.
