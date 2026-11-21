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
| **Estado atual** | **`INCONCLUSIVO`** — geração B **subset** (E44); E60/ADR [`0021`](adr/0021-especie-canonica-linha-b-inviavel.md) declara 22L×32 inviável no gate atual; perfil GPU E56 também `INCONCLUSIVO`. Hipótese **não** comprovada nem refutada (bloqueio **final** = B58) |
| Não conta | Celebrar subset / `A_gpu` / proxy como `COMPROVA` |

---

## Pilar 2 — SO / USB / caminho IA nativo

| Campo | Valor |
|-------|--------|
| Artefato | `make verify-baremetal` → `IA_LIVRE_BAREMETAL_IMAGE_OK` |
| Onboarding | Guia [`guia-primeiro-boot-usb.md`](guia-primeiro-boot-usb.md) + `make verify-boot-guide-release` |
| Writer | `make verify-write-usb` → `WRITE_USB_OK` (gravação ≠ metal) |
| Path IA mínimo | BlockIO (QEMU) e/ou path metal SFS com bloqueio honesto (`verify-metal-infer` / `B_BLOCK_METAL`) — sem `TOKENS` fingidos |
| Metal real | `METAL_OK` **somente** com log em `docs/evidence/boot-metal/` sem QEMU/OVMF |
| **Estado atual** | Artefato + guia + writer + path metal **honestos** verdes no CI; **`METAL_OK`** depende de evidência de PC (opt-in; default skip) |
| Não conta | Tratar QEMU como metal; inventar `METAL_OK` |

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

1. Pilar 1 estiver `INCONCLUSIVO` **sem** bloqueio final documentado, **ou**
2. Pilar 2 carecer de caminho honesto **e** (quando celebrar metal) de `METAL_OK` real, **ou**
3. Pilar 3 falhar `verify-node` / `verify-agent`.

**Permitido** celebrar **parciais** (ex.: “pilar 3 verde”; “artefato USB + guia publicados”) citando o gate correspondente.

### O que falta para o objetivo global (resumo)

| Pilar | Falta |
|-------|--------|
| 1 | Espécie canônica em B **ou** bloqueio final explícito |
| 2 | Evidência `METAL_OK` em PC (quando quiser fechar metal) — artefato/guia já ok |
| 3 | — (critério host satisfeito) |

---

## Espelho operacional

| Onde | O quê |
|------|--------|
| `ROADMAP.md` | Etapa 58 + ponte a este doc |
| `memory-bank/activeContext.md` / `progress.md` | Estado dos pilares + residual |
| Gate | `make verify-prototipo-objetivo` → `IA_LIVRE_PROTOTIPO_OBJETIVO_OK` (presença + greps; **não** exige `COMPROVA`) |
