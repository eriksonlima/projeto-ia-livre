# Protótipo objetivo atingido — checklist verificável (Etapa 58)

Definição canônica do que conta como **“protótipo objetivo atingido”** no Projeto IA Livre.  
Fonte da meta: parágrafo em `BACKLOG.md` · produto: [`product-context.md`](product-context.md) · manifesto: [`manifesto.md`](manifesto.md).

> **Celebrar só com evidência.** Esta página **define** o critério; **não** declara que o objetivo já foi atingido em todas as frentes. Hipótese A vs B hoje = **`INCONCLUSIVO`**.

## Os três pilares

| # | Pilar | “Atingido” quando… |
|---|--------|---------------------|
| 1 | Hipótese A vs B | Veredito `COMPROVA` **ou** `REFUTA` com espécie canônica **ou** bloqueio honesto **final** documentado |
| 2 | SO / USB / metal | Boot ESP/USB em hardware com caminho de IA nativo mínimo **honesto** (+ evidência quando `METAL_OK`) |
| 3 | Rede + autonomia | Utilizáveis no **host** sem exigir o SO (`verify-node` / `verify-agent`) |

Objetivo do protótipo = **os três** pilares no estado “atingido” (ou bloqueio final explícito no pilar 1). Até lá: verdades parciais ok; vitória global **não**.

---

## Pilar 1 — Hipótese A vs B

| Campo | Valor |
|-------|--------|
| Critério decidível | `make verify-harness-comparable` emite `IA_LIVRE_HARNESS_VERDICT=COMPROVA` **ou** `REFUTA` com espécie canônica (22L + `n_predict=32` em B) — ver [`harness-a-b-comparavel.md`](harness-a-b-comparavel.md) |
| Bloqueio honesto final | Doc/ADR declara terminalmente inviável a espécie canônica **e** o instrumento permanece honesto (`INCONCLUSIVO` ou reason terminal) — sem fingir `COMPROVA` |
| Evidência | `IA_LIVRE_HARNESS_VERDICT=` / `VERDICT_REASON=` |
| **Estado atual** | **`BLOQUEIO_FINAL`** — ADR [`0022`](adr/0022-bloqueio-final-hipotese-ab.md) (terminal no gate/motor atuais; encadeia 0020/0021). Instrumento comparable permanece `INCONCLUSIVO`/teto (sem `COMPROVA`). Reabertura: critérios na 0022 |
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

**Proibido** declarar “protótipo objetivo atingido” / vitória da hipótese enquanto:

1. Pilar 1 estiver `INCONCLUSIVO` **sem** bloqueio final documentado (hoje: **`BLOQUEIO_FINAL`** via ADR 0022 — este item cumprido), **ou**
2. Pilar 2 carecer de caminho honesto **e** (quando celebrar metal) de `METAL_OK` real, **ou**
3. Pilar 3 falhar `verify-node` / `verify-agent`.

**Permitido** celebrar **parciais** (ex.: “pilar 3 verde”; “pilar 1 com bloqueio final documentado”; “artefato USB + guia”) citando o gate/ADR correspondente.

### O que falta para o objetivo global (resumo)

| Pilar | Falta |
|-------|--------|
| 1 | — (bloqueio **final** ADR 0022; reabertura só com critérios da ADR) |
| 2 | — (`METAL_OK` via report ESP E73; evidência versionada) |
| 3 | — (critério host satisfeito) |

---

## Espelho operacional

| Onde | O quê |
|------|--------|
| `ROADMAP.md` | Etapa 58 + ponte a este doc |
| `memory-bank/activeContext.md` / `progress.md` | Estado dos pilares + residual |
| Gate | `make verify-prototipo-objetivo` → `IA_LIVRE_PROTOTIPO_OBJETIVO_OK` (presença + greps; **não** exige `COMPROVA`) |
