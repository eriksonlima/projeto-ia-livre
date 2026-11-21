# Spec — Guia “primeiro boot USB” + release de artefato (Etapa 57)

Etapa 57 · Issue [#57](https://github.com/eriksonlima/projeto-ia-livre/issues/57) (ex-B51)  
Deps: E30/E35/E46 (artefato + evidência metal); E47 (writer USB) — **feitas**.

---

## Resultado visível

Contribuidores têm um **guia passo a passo** (“primeiro boot USB”) cobrindo Secure Boot, serial, o que esperar no boot e limites honestos — e um **processo de release** que publica (ou prepara) artefato ESP/tar + checksums via tag/GitHub Release (ou script documentado). Gate CI verifica presença do guia + checksums/artefato de release **sem** exigir USB nem PC físico.

A etapa **não** declara hipótese A vs B comprovada; **não** inventa `METAL_OK`; QEMU ≠ metal permanece explícito.

## Contexto fixo (não reinventar)

- **E30 / ADR 0011:** `make baremetal-esp` → `build/baremetal-esp/` + `build/ia-livre-esp.tar.gz` (+ `.img` se mtools); gate `IA_LIVRE_BAREMETAL_IMAGE_OK`. Contrato [`docs/boot-hardware-real.md`](../../docs/boot-hardware-real.md).
- **E35/E46:** captura serial + evidência em `docs/evidence/boot-metal/`; `METAL_OK` só com log real; default `BAREMETAL_SKIP=1`.
- **E47:** `scripts/write-usb-esp.sh` + `make verify-write-usb` → `IA_LIVRE_WRITE_USB_OK`; gravação ≠ `METAL_OK`.
- **Harness:** veredito A vs B permanece **INCONCLUSIVO** (espécie subset em B); guia **proibido** de dizer “hipótese comprovada”.
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: avaliar `README.md` em cada fatia.

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A** | Guia dedicado em `docs/` (passo a passo Secure Boot/serial/expectativa) + script de empacote/checksums + procedimento GitHub Release/tag documentado; gate CI sem USB; honestidade METAL/QEMU/hipótese | **Escolhida** |
| **B** | Só expandir `boot-hardware-real.md` sem release/checksums versionáveis | **Rejeitada** — não cumpre “tag/release com ESP/tar/checksums” |
| **C** | Exigir USB/PC no CI para fechar | **Rejeitada** — inviável |
| **D** | Declarar boot USB = hipótese A vs B comprovada | **Rejeitada** — fraude de critério |
| **E** | Assinar EFI / Secure Boot enrolled | **Rejeitada** — fora; guia orienta Secure Boot **off**/setup |

### Escolha: **A — guia + artefato de release com checksums + gate documental/artefato**

| Peça | Nesta etapa |
|------|-------------|
| Guia | Doc canônico novo (ex. `docs/guia-primeiro-boot-usb.md`) **ou** seção top-level clara linkada a partir de `boot-hardware-real.md` / README — fluxo: baixar/build → gravar USB → firmware → serial → o que esperar / o que **não** esperar |
| Secure Boot | Instrução: desligar ou setup mode; **sem** assinatura de EFI |
| Serial | 115200 8N1 COM1; ponte para evidência E35/E46 |
| O que esperar | Marcadores mín. `BOOT_OK` (ideal `EXIT_*`); limites GGUF/metal/path BlockIO ≠ SFS |
| Release | Script (ex. `scripts/prepare-baremetal-release.sh`) gera/copia tar (+ opcional `.img`) + `SHA256SUMS` (ou equivalente); doc: criar tag + GitHub Release anexando artefatos |
| Gate | `make verify-…` (novo ou extensão) exige: guia presente + checksums/arquivo de release (após prepare **ou** fixture mínima) — **sem** USB; **sem** inventar `METAL_OK` |
| Hipótese | Texto explícito: A vs B **INCONCLUSIVO**; boot USB ≠ `COMPROVA` |

### Justificativa

- Fecha onboarding comunitário (B51) reusando writer/artefato já feitos.
- Release com checksums torna o artefato auditável sem CI de hardware.
- Honestidade explícita evita celebrar meta de pesquisa indevida.

### Rejeitado (explícito)

- Declarar hipótese A vs B comprovada / `COMPROVA` por causa do guia ou do release.
- Inventar `IA_LIVRE_BAREMETAL_METAL_OK` ou tratar QEMU como metal.
- Exigir pendrive/PC no CI.
- Secure Boot assinado / MokManager / instalador desktop.
- Embutir GGUF 638 MiB obrigatório no release default (E36 permanece opt-in documentado).
- Alterar kernel / harness comparable / veredito.

## Fora de escopo

- Boot físico obrigatório nesta máquina / nova evidência `METAL_OK`.
- Assinatura Secure Boot / SBAT / Microsoft keys.
- Marketplace, Rede, autonomia além de pontes já existentes.
- Prova ou mudança do veredito harness A vs B.
- Mudança de layout ESP ou do kernel (salvo nota no guia).

## Critérios de aceite

- [ ] Existe guia passo a passo (doc dedicado ou seção canônica) cobrindo: pré-requisitos; build/`baremetal-esp` **ou** download do release; gravação via `write-usb-esp.sh`; Secure Boot; Boot Menu; serial 115200; o que esperar na serial; o que **não** esperar (QEMU≠metal; gravação≠`METAL_OK`; hipótese INCONCLUSIVO).
- [ ] Ponte clara a partir de `docs/boot-hardware-real.md` (e AGENTS; README se capa enganosa).
- [ ] Processo de release documentado: gerar ESP/tar (+ `.img` se disponível) + arquivo de checksums (SHA256); criar tag/GitHub Release **ou** script que prepara anexos — operador/CI de release **não** exige USB.
- [ ] Script (ou procedimento único versionado) produz artefatos reproduzíveis apontando para `make baremetal-esp` / tar existente.
- [ ] Gate automatizado verifica: guia presente + checksums/artefato de release (ou saída do prepare) — exit 0 sem USB; marcador sugerido ex. `IA_LIVRE_BOOT_GUIDE_OK` / `IA_LIVRE_RELEASE_ARTIFACT_OK` (nome final na impl.).
- [ ] Texto do guia **não** afirma hipótese comprovada nem confunde ambientes (tabela QEMU / artefato / metal).
- [ ] Gates existentes (`verify-baremetal`, `verify-write-usb`, `verify`) **não** regridem.
- [ ] README avaliado (`readme-por-fatia`).

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| Guia celebrar hipótese | Critério escrito + review; frase canônica INCONCLUSIVO |
| Release com GGUF 638 MiB por default | Default = artefato E30 (hdr/prefixo); FULL_GGUF só opt-in documentado |
| Gate exigir USB | Proibido; só docs + checksums/prepare |
| Checksums desatualizados vs EFI | Prepare regenera SHA a partir do build atual; gate confere consistência |
| Duplicar checklist E46 | Guia referencia `boot-hardware-real.md`; não contradiz |

Rollback: remover guia/script/gate novos; E30–E47 intactos.

## Etapa do roadmap

- Etapa 57 `em_andamento` — Guia “primeiro boot USB” + release de artefato
- Issue: [#57](https://github.com/eriksonlima/projeto-ia-livre/issues/57)
- Pronto quando (roadmap): guia passo a passo (Secure Boot, serial, o que esperar) + tag/release com ESP/tar/checksums; sem declarar hipótese comprovada.
