# ADR 0022 — Bloqueio final do pilar 1 (hipótese A vs B) no gate atual

- Status: aceita
- Data: 2026-11-21

## Contexto

Pilares do protótipo: [`prototipo-objetivo-atingido.md`](../prototipo-objetivo-atingido.md).

| ADR | Papel |
|-----|--------|
| [`0016`](0016-veredito-limpo-harness-a-b.md) | Veredito limpo; teto E45 |
| [`0020`](0020-runtime-native-passo-intermediario-inviavel.md) | Passo N≥8 inviável **operacional** (pós-otimização E59) |
| [`0021`](0021-especie-canonica-linha-b-inviavel.md) | Espécie canônica 22L×32 inviável **operacional** (E60) |

0020/0021 são tetos **operacionais** (gate 600 s / motor atual). O checklist E58 ainda tratava o pilar 1 como “INCONCLUSIVO aberto”, sem marcar **bloqueio final**.

## Decisão

1. **Bloqueio final (terminal) do pilar 1 no escopo do protótipo atual:** com o motor freestanding + QEMU guest + timeout de gate vigentes, **não** é possível obter veredito `COMPROVA`/`REFUTA` por espécie canônica. O estado canônico do pilar 1 passa a **`BLOQUEIO_FINAL`** (não “ainda vamos tentar 22L×32 no mesmo caminho”).
2. Instrumento comparable permanece **honesto**: `INCONCLUSIVO` + reason de teto (`E45_perf_ceiling_*`); **proibido** `COMPROVA`/`REFUTA` com subset.
3. **Critérios de reabertura** (qualquer um, com evidência + nova etapa/ADR):
   - Ganho medido ≫10× no guest (SIMD/GPU guest / redesign) cabendo 22L×32 no timeout; **ou**
   - Methodology nova documentada (timeout/hardware dedicado) **sem** fraudar espécie; **ou**
   - Aceitar espécie intermediária como nova “canônica” via ADR explícita (mudança de contrato A vs B) — **não** feito aqui.
4. Esta ADR **não** prova nem refuta a hipótese científica em abstrato — só declara o **protótipo atual** sem caminho decidível no pilar 1.
5. Pilares 2–3 **independentes**: metal/`METAL_OK` e Rede/autonomia host seguem.

## Consequências

- Checklist E58 pilar 1: estado **`BLOQUEIO_FINAL`** (ADR 0022), celebrar parcial ok; vitória global **não**.
- B55 (re-corrida quieta pós-canônico) permanece adiada até reabertura.
- Próximo foco produto sensato: pilar 2 (B56/B57 metal) ou sync docs.
