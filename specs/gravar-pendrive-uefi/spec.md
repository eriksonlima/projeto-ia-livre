# Spec — One-shot gravar pendrive UEFI (script + doc)

Etapa 47 · Issue [#47](https://github.com/eriksonlima/projeto-ia-livre/issues/47) (ex-B41)  
Depende: E30 (artefato ESP / `make baremetal-esp` / ADR 0011).

---

## Resultado visível

Procedimento **único e seguro** para contribuidores gravarem a ESP/imagem bare-metal num pendrive UEFI: um script bash em `scripts/` que lista candidatos removíveis, exige confirmação explícita do path do device, recusa discos de sistema óbvios, e grava a partir de `build/ia-livre-esp.img` (ou fallback documentado/geração com mtools) — com dry-run / `--help` / list-only e gate automatizado **sem** USB físico no CI.

A etapa **não** prova boot em PC (`METAL_OK` permanece caminho E35/E46). Só entrega o *writer* seguro + docs.

## Contexto fixo (não reinventar)

- **E30 (feita):** `make baremetal-esp` → árvore `build/baremetal-esp/` + tar; FAT `.img` (`build/ia-livre-esp.img`) **só se** `mtools`; gate `IA_LIVRE_BAREMETAL_IMAGE_OK`. Contrato [`docs/boot-hardware-real.md`](../../docs/boot-hardware-real.md); ADR [`0011`](../../docs/adr/0011-boot-imagem-esp-baremetal.md).
- **E46 (feita):** fechou com SKIP metal (sem PC); checklist Secure Boot/serial permanece. Esta etapa **não** inventa `METAL_OK`.
- Seção atual “Gravar USB / ESP (manual)” no contrato: `dd` / `cp` com aviso — esta etapa **substitui** por one-shot com confirmação obrigatória.
- QEMU ≠ metal; hipótese A vs B / harness / `TOKENS_PER_S` intocados.
- Rule `readme-por-fatia`: avaliar `README.md` em cada fatia.

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A** | Script bash `scripts/write-usb-esp.sh`: lista USB/removíveis; confirmação explícita (digitar path ou `YES`+path); checks anti-sistema; grava `.img` se existir, senão fallback árvore FAT / gera `.img` com mtools; dry-run/help/list-only; docs + gate sem USB no CI | **Escolhida** |
| **B** | Só documentação do `dd` manual (status quo E30) | **Rejeitada** — não cumpre “one-shot” / confirmação estruturada |
| **C** | `dd` cego / grava sem confirmação / default no primeiro USB | **Rejeitada** — destrutivo |
| **D** | Exigir USB físico no CI para fechar a etapa | **Rejeitada** — inviável; gate = dry-run/recusa |
| **E** | Assinar EFI / Secure Boot | **Rejeitada** — fora; checklist E46 permanece |

### Escolha: **A — writer bash com confirmação explícita + gate dry-run**

| Peça | Nesta etapa |
|------|-------------|
| Script | `scripts/write-usb-esp.sh` (nome canônico; Makefile alvo opcional) |
| Listagem | Candidatos removíveis/USB legíveis (`lsblk` ou equivalente documentado) |
| Confirmação | Operador digita o path do device (ex. `/dev/sdX`) **ou** `YES`+path — **nunca** grava sem isso |
| Anti-sistema | Recusa se device monta `/`, `/boot`, `/home` etc.; checks honestos (não “prova” absoluta) |
| Fonte | Preferir `build/ia-livre-esp.img`; se ausente: gerar via mtools **ou** fallback `cp` árvore ESP → partição FAT já formatada (documentado) |
| Modos seguros | `--help`, dry-run, list-only — sem I/O destrutivo |
| Docs | Atualizar `docs/boot-hardware-real.md`; ponte curta AGENTS (+ README se capa enganosa) |
| Gate | Dry-run / help / exit ≠ 0 sem confirmação — **não** exige pendrive no CI |
| Marcador sugerido | `IA_LIVRE_WRITE_USB_OK` (dry-run/gate) ou equivalente honesto documentado |

### Justificativa

- Cumpre o Pronto quando do roadmap (procedimento único + confirmação) sem destruir discos por omissão.
- Reaproveita artefato E30; não reabre metal/METAL_OK.
- Gate CI-friendly: prova o *contrato de segurança* do script, não o hardware.

### Rejeitado (explícito)

- Gravar `/dev/sdX` (ou qualquer device) sem confirmação explícita digitada.
- `dd` cego / auto-seleção do “primeiro USB”.
- Inventar ou emitir `IA_LIVRE_BAREMETAL_METAL_OK`.
- Secure Boot assinatura / MokManager.
- Exigir USB físico no CI.
- Alterar kernel, runtime, harness A vs B ou veredito.

## Fora de escopo

- Boot em PC físico / captura serial / `METAL_OK`.
- Assinatura Secure Boot.
- Particionamento automático agressivo sem confirmação; wipe de discos internos.
- GGUF full obrigatório na gravação (E36 permanece opt-in no artefato).
- Prova da hipótese A vs B / `TOKENS_PER_S`.
- Mudança de layout ESP ou kernel.

## Critérios de aceite

- [ ] Existe `scripts/write-usb-esp.sh` (ou nome equivalente documentado) com: listagem de candidatos; confirmação explícita; recusa de discos de sistema óbvios; dry-run / `--help` / list-only.
- [ ] Sem confirmação válida → exit ≠ 0 e **nenhuma** escrita no device.
- [ ] Com `.img` presente: caminho de gravação documentado e implementado; sem `.img`: fallback (gerar com mtools **ou** `cp` árvore FAT) documentado e honesto.
- [ ] `docs/boot-hardware-real.md` descreve o one-shot (substitui/atualiza a seção manual `dd`).
- [ ] Ponte em `AGENTS.md` (Como rodar / verificar); `README.md` avaliado (`readme-por-fatia`).
- [ ] Gate automatizado (script/`make`) cobre help + dry-run/list-only + recusa sem confirmação — **sem** USB físico; CI-friendly.
- [ ] Gates existentes (`make verify-baremetal` IMAGE_OK, `make verify`, etc.) **não** regridem.
- [ ] **Não** emite `METAL_OK` nem finge boot metal.

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| Operador confirma device errado | Listagem legível + digitar path completo; avisos; checks anti-sistema |
| Checks anti-sistema incompletos | Documentar como “honestos, não absolutos”; preferir dry-run primeiro |
| Sem mtools e sem `.img` | Fallback `cp` para FAT montada + docs claros |
| Confundir writer com prova metal | Docs: gravação ≠ `METAL_OK`; E46 permanece |
| Gate exige USB | Proibido; só dry-run/recusa/help |

Rollback: remover script/alvo de gate; restaurar seção manual em `docs/boot-hardware-real.md`; artefato E30 intacto.

## Etapa do roadmap

- Etapa 47 `em_andamento` — One-shot gravar pendrive UEFI (script + doc)
- Issue: [#47](https://github.com/eriksonlima/projeto-ia-livre/issues/47)
- Pronto quando (roadmap): script ou procedimento único (detecta device com confirmação, grava ESP/FAT ou `.img`) + README/AGENTS; **sem** gravar `/dev/sdX` sem confirmação explícita.
