# Spec — Boot/imagem IA Livre em hardware real (USB/ESP)

## Resultado visível

Caminho **documentado e verificável** para levar o kernel IA Livre (`BOOTX64.EFI`) a hardware UEFI real via **imagem ESP/USB (FAT)** ou equivalente, **sem** fingir que QEMU = bare-metal e **sem** misturar com a hipótese A vs B / `TOKENS_PER_S`.

A etapa fecha com:

1. **Artefato de imagem** montável (diretório ESP empacotável / imagem FAT) contendo o EFI canônico.
2. **Gate automatizado no host** que valida a **imagem** (estrutura FAT/ESP, presença de `EFI/BOOT/BOOTX64.EFI`, listagem/checksum) — **não** exige máquina física no CI.
3. **Procedimento manual** para PC UEFI real (Secure Boot, mídia, serial USB-UART ou equivalente) + checklist.
4. Se hardware real não estiver disponível: **bloqueio/skip honesto** (`IA_LIVRE_BAREMETAL_SKIP` ou equivalente documentado) — a etapa **ainda fecha** com imagem + doc + gate de artefato.

## Contexto fixo (não reinventar)

- Kernel UEFI mínimo sobe em **QEMU+OVMF** (`make run` / `make verify`): `BOOT_OK` … ExitBoot, GGUF BlockIO, layout `runtime-native`, proxy Linha B.
- Artefato de build: `target/x86_64-unknown-uefi/debug/ia-livre-kernel.efi` → ESP `build/esp/EFI/BOOT/BOOTX64.EFI` (`make esp`).
- GGUF raw `build/gguf-canon.gguf` via BlockIO no QEMU — em hardware real o path de disco / staging pode diferir; **não** é obrigatório ter TinyLlama completo na mídia nesta etapa.
- I/O pós-ExitBoot hoje: UART **COM1** (serial).
- **Não há** instalador, framebuffer nem “USB live” documentado hoje.
- Hipótese A vs B permanece **INCONCLUSIVO** (`B_BLOCK=no_gguf_forward`); motor forward **fora de escopo**.
- Contratos úteis: [`docs/kernel-alem-do-boot.md`](../../docs/kernel-alem-do-boot.md), [`docs/kernel-pos-boot-services.md`](../../docs/kernel-pos-boot-services.md), [`docs/runtime-nativo-linha-b.md`](../../docs/runtime-nativo-linha-b.md).
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`; se não precisar, registrar.

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A** | Doc + script que monta imagem/ESP FAT com `BOOTX64.EFI` (+ opcional `gguf.hdr` / instruções GGUF); gate que valida o **artefato** no host; procedimento manual bare-metal + skip honesto se sem PC | **Escolhida** |
| **B** | Exigir boot bem-sucedido em hardware físico no CI / gate fail sem máquina | **Rejeitada** — inviável e não portátil |
| **C** | Declarar `make verify` (QEMU) como prova de bare-metal | **Rejeitada** — fraude de ambiente |
| **D** | Instalador completo / live desktop / framebuffer / drivers USB complexos | **Rejeitada** — fora do mínimo |
| **E** | Só documentação sem artefato nem gate | **Rejeitada** — não verificável |
| **F** | Embutir motor/`TOKENS_PER_S` ou alterar harness para `COMPROVA` nesta etapa | **Rejeitada** — escopo errado |

### Escolha: **A — imagem ESP/USB verificável + procedimento manual + skip honesto**

| Peça | Escolha nesta etapa |
|------|---------------------|
| Mídia | Imagem FAT (arquivo `.img` ou diretório ESP empacotável) adequada a gravar em USB / partição ESP |
| Conteúdo mínimo | `EFI/BOOT/BOOTX64.EFI` = kernel buildado do workspace |
| Conteúdo opcional | Prefixo/`gguf.hdr` / `IA_LIVRE/` já usados no QEMU; instruções para GGUF completo **sem** exigir os ~638 MiB na imagem do gate |
| Gate CI | Valida **estrutura e presença** do EFI (+ checksum/listagem); **não** boot em hardware |
| Prova física | Checklist manual; evidência humana (serial) quando houver máquina |
| Sem máquina | `IA_LIVRE_BAREMETAL_SKIP` (ou equivalente) documentado; exit 0 no trecho “hardware”; gate de **imagem** continua obrigatório |
| Serial | Documentar COM1 + caminho USB-UART / adaptação típica; sem exigir driver novo no kernel |
| Secure Boot | Documentar expectativa (desligar Secure Boot / modo setup) — sem assinar EFI nesta etapa |
| Hipótese A vs B | **Intocada**; proibido `TOKENS_PER_S` fingido |
| ADR | **0011** (sugerido): QEMU ≠ bare-metal; artefato de imagem como prova CI; skip de hardware |

### Justificativa

- Avanço verificável **sem** depender de PC físico no CI.
- Reutiliza o pipeline já existente (`make build` / `make esp` / `BOOTX64.EFI`).
- Separa honestamente “imagem pronta” de “boot observado em metal”.
- Evita alargar o escopo para instalador, GPU ou motor de inferência.

### Rejeitado (explícito)

- Fingir que QEMU/OVMF = hardware real.
- Inventar `TOKENS_PER_S` / `LOAD_KIND=gguf` / `COMPROVA` nesta etapa.
- Exigir GPU, multi-GPU ou GPU manager nativo.
- Exigir forward TinyLlama / sair de `no_gguf_forward`.
- Instalador completo, desktop, framebuffer, rede no kernel.
- Gate que falha só porque não há USB/PC no runner.
- Alterar harness A vs B para forçar veredito.

## Fora de escopo

- Forward TinyLlama / `TOKENS_PER_S` na Linha B.
- Alterar harness A vs B para `COMPROVA` / `REFUTA` além do estado atual.
- Desktop, drivers complexos, instalador completo, Secure Boot signed.
- Mudança obrigatória do path BlockIO/GGUF no kernel para hardware (só documentar limites).
- Assinatura de código UEFI / Microsoft DBX.
- Boot em ARM / non-x86_64.

## Critérios de aceite

- [ ] Existe doc de contrato (ex. `docs/boot-hardware-real.md`) descrevendo: artefato, como gravar USB/ESP, procedimento manual, limites (serial, Secure Boot, GGUF), e que QEMU ≠ bare-metal.
- [ ] Existe script (e/ou alvo `make`) que, a partir do EFI buildado, produz imagem/ESP utilizável com `EFI/BOOT/BOOTX64.EFI`.
- [ ] Gate automatizado (`make verify-baremetal` ou nome equivalente) valida a imagem no host (estrutura + EFI presente + listagem/checksum) **sem** exigir hardware.
- [ ] Procedimento manual + checklist para PC UEFI real está no doc (incluindo como observar serial / o que contar como sucesso mínimo: pelo menos marcadores de boot conhecidos se serial disponível).
- [ ] Política de skip honesto documentada (`IA_LIVRE_BAREMETAL_SKIP` ou equivalente) quando não há hardware — **não** substitui o gate da imagem.
- [ ] ADR 0011 (ou seção equivalente no doc) registra a decisão A e rejeições B–F.
- [ ] `AGENTS.md` aponta Como rodar / Como verificar o caminho bare-metal (gate de artefato + skip).
- [ ] Hipótese A vs B / `TOKENS_PER_S` / harness comparable **não** são adulterados para fingir prova.
- [ ] README avaliado (`readme-por-fatia`).
- [ ] Gates existentes (`make verify`, harness, etc.) **não** regridem por causa desta etapa.

### Sucesso mínimo em hardware (quando disponível — manual)

| Evidência | Significado |
|-----------|-------------|
| Firmware UEFI carrega `BOOTX64.EFI` da mídia | Boot path real |
| Serial (se conectado) mostra marcadores conhecidos (ex. `IA_LIVRE_BOOT_OK` e/ou posteriores) | Kernel rodou além do firmware |
| Sem serial | Checklist fotográfico/firmware “bootou o EFI” ainda é evidência fraca mas honestamente documentável — preferir serial |

### Marcadores de gate de artefato (host — sugeridos)

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_BAREMETAL_IMAGE_OK` | Imagem/ESP validada (estrutura + EFI) |
| `IA_LIVRE_BAREMETAL_EFI=…` | Path ou checksum do `BOOTX64.EFI` na imagem |
| `IA_LIVRE_BAREMETAL_SKIP` | Trecho “hardware real” pulado (sem PC); **não** dispensa `IMAGE_OK` |

Nomes finais podem ajustar na implementação desde que estáveis e documentados.

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| Confundir gate de imagem com prova bare-metal | Doc + marcadores distintos; proibir linguagem “provado em metal” só com `IMAGE_OK` |
| Imagem FAT frágil (alinhamento, MBR/GPT) | Preferir caminho mínimo documentado (ex. `mtools`/`mkfs.vfat` + layout ESP clássico); falhar o gate se estrutura inválida |
| Secure Boot impede boot | Documentar desligar SB; não assinar nesta etapa |
| Serial inexistente no PC alvo | Checklist + skip; não inventar saída |
| Escopo vazar para motor/GGUF completo na USB | Opcional só header/instruções; GGUF completo fora do critério de fecho |
| Quebrar `make esp` / QEMU | Script bare-metal **empacota** o que `make esp`/`build` já gera; não substituir o fluxo QEMU |

Rollback: remover script/gate/doc novos; `make esp` + `make verify` QEMU permanecem como antes.

## Etapa do roadmap

Etapa 30 — Boot/imagem IA Livre em hardware real (USB/ESP)  
Issue: [#30](https://github.com/eriksonlima/projeto-ia-livre/issues/30)  
Status roadmap: `em_andamento`  
Pronto quando (roadmap): caminho documentado e verificável para boot do kernel em hardware UEFI real (imagem USB/ESP ou equivalente) **ou** bloqueio honesto documentado; separado da hipótese A vs B / sem fingir `TOKENS_PER_S`; não exige motor de inferência em B.
