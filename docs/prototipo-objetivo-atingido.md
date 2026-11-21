# Protótipo objetivo atingido — checklist verificável (Etapa 58)

Definição canônica do que conta como **“protótipo objetivo atingido”** no Projeto IA Livre.  
Fonte da meta: parágrafo em `BACKLOG.md` · produto: [`product-context.md`](product-context.md) · manifesto: [`manifesto.md`](manifesto.md).

> **Checklist dos 3 pilares: cumprido (2026-11-21).** Celebrar só com evidência (abaixo). A hipótese científica A vs B fica **fora do escopo de produto** daqui em diante (ADR [`0026`](adr/0026-produto-sem-comprovacao-ab.md)); instrumento lab pode permanecer `INCONCLUSIVO` sem reabrir roadmap.

## Os três pilares

| # | Pilar | “Atingido” quando… |
|---|--------|---------------------|
| 1 | Hipótese A vs B | Veredito `COMPROVA` **ou** `REFUTA` com espécie canônica **ou** bloqueio honesto **final** documentado |
| 2 | SO / USB / metal | Boot ESP/USB em hardware com caminho de IA nativo mínimo **honesto** (+ evidência quando `METAL_OK`) |
| 3 | Rede + autonomia | Utilizáveis no **host** sem exigir o SO (`verify-node` / `verify-agent`) |

Objetivo do protótipo = **os três** pilares no estado “atingido” (ou bloqueio final explícito no pilar 1).

---

## Pilar 1 — Hipótese A vs B

| Campo | Valor |
|-------|--------|
| Critério decidível | `make verify-harness-comparable` emite `IA_LIVRE_HARNESS_VERDICT=COMPROVA` **ou** `REFUTA` com espécie canônica (22L + `n_predict=32` em B) — ver [`harness-a-b-comparavel.md`](harness-a-b-comparavel.md) |
| Bloqueio honesto final | Doc/ADR declara terminalmente inviável a espécie canônica **e** o instrumento permanece honesto (`INCONCLUSIVO` ou reason terminal) — sem fingir `COMPROVA` |
| Evidência | `IA_LIVRE_HARNESS_VERDICT=` / `VERDICT_REASON=` |
| **Estado atual** | **`BLOQUEIO_FINAL`** — ADR [`0022`](adr/0022-bloqueio-final-hipotese-ab.md). **Arquivado como meta de produto** (ADR [`0026`](adr/0026-produto-sem-comprovacao-ab.md)): sem `COMPROVA`/`REFUTA` no roadmap; B55 arquivada. Instrumento comparable permanece lab/`INCONCLUSIVO` |
| Não conta | Celebrar subset / `A_gpu` / proxy como `COMPROVA`; tratar teto operacional 0020/0021 sozinhos como bloqueio final |

---

## Pilar 2 — SO / USB / caminho IA nativo

| Campo | Valor |
|-------|--------|
| Artefato | `make verify-baremetal` → `IA_LIVRE_BAREMETAL_IMAGE_OK` |
| Onboarding | Guia [`guia-primeiro-boot-usb.md`](guia-primeiro-boot-usb.md) + `make verify-boot-guide-release` |
| Writer | `make verify-write-usb` → `WRITE_USB_OK` (gravação ≠ metal) |
| Path IA mínimo | BlockIO (QEMU) e/ou path metal SFS com bloqueio honesto (`verify-metal-infer` / `B_BLOCK_METAL`) — sem `TOKENS` fingidos |
| Metal real | `METAL_OK` com **report ESP** (padrão E73) ou serial legado em `docs/evidence/boot-metal/` sem QEMU/OVMF — [`baremetal-report.md`](baremetal-report.md) |
| **Estado atual** | Artefato + guia + writer + path metal verdes; canal ESP (E73); **`METAL_OK`** com report real [`2026-11-21-eriksonlima-Nitro-AN515-51.txt`](evidence/boot-metal/2026-11-21-eriksonlima-Nitro-AN515-51.txt) (`esp_sfs_full` + GOP 1920x1080) |
| Não conta | Tratar QEMU como metal; inventar `METAL_OK`; vídeo/foto como gate |

---

## Pilar 3 — Rede + autonomia (sem exigir SO)

| Campo | Valor |
|-------|--------|
| Rede | `make verify-node` → v1 + `TASK_OK` + bootstrap (`DISC_OK`); mDNS opt-in |
| Autonomia | `make verify-agent` → E7/v1/`calc`/REPL/`read_local` |
| ADR 0001 | Participar da Rede / autonomia **não** exige o SO IA Livre |
| Bridges | E49/E52 são **extras**; **não** substituem `verify-node` / `verify-agent` |
| **Estado atual** | **Atingido** no host de referência (gates verdes; independência do SO documentada) |
| Não conta | Exigir QEMU para o nó/agente; fingir TCP nativo no guest |

---

## Celebração (só com evidência)

**Protótipo checklist = ok** quando os três pilares estão “atingidos” (pilar 1 via `BLOQUEIO_FINAL`). Isso **não** declara vitória científica `COMPROVA`.

**Proibido** declarar “hipótese comprovada” / `COMPROVA` sem espécie canônica; **proibido** reabrir ADR 0022 / B55 no roadmap sem pedido explícito (ADR 0026).

**Permitido** celebrar o checklist dos 3 pilares e seguir evolução de **produto** na Linha B (SO bare-metal / report / runtime nativo).

### Resumo dos pilares

| Pilar | Estado |
|-------|--------|
| 1 | `BLOQUEIO_FINAL` (ADR 0022) — **encerra** o pilar no protótipo; meta A/B **arquivada** (ADR 0026) |
| 2 | `METAL_OK` (report ESP real) |
| 3 | Rede + autonomia host ok |

---

## Espelho operacional

| Onde | O quê |
|------|--------|
| `ROADMAP.md` | Etapa 58 + ponte a este doc |
| `memory-bank/activeContext.md` / `progress.md` | Checklist ok; foco Linha B |
| Gate | `make verify-prototipo-objetivo` → `IA_LIVRE_PROTOTIPO_OBJETIVO_OK` (presença + greps; **não** exige `COMPROVA`) |
| Produto | ADR [`0026`](adr/0026-produto-sem-comprovacao-ab.md) |

