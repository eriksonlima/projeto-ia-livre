# Progress

## O que funciona

- Etapas 1–74 feitas
- Checklist 3 pilares **ok** (E58); `METAL_OK` via report ESP; Rede/autonomia host
- E74: `REPORT_POST_OK` no `make verify` (slot BlockIO + buffer pós-exit)
- Hipótese A/B **arquivada** como meta de produto (ADR 0026); B55 arquivada

## Bloqueios

- Lab: COMPROVA / espécie (não meta de produto)
- Simetria GPU (VFIO); TCP guest (ADR 0024)
- BlockIO rewrite pós-exit: best-effort (QEMU fat:rw pode hang após `POST_OK`)

## Roadmap

- Sem `em_andamento`; Abertas: B70 (tokens metal no report), B71 (collect script)

## Etapa 74 — baremetal-report pós-ExitBoot (feita)

- Slot `IALVPST1`; `uart_write` → post buffer; `flush_post_exit` + `REPORT_POST_OK`
- Gate: `verify-boot` exige POST_OK|POST_FAIL
- ADR 0026 + B55 arquivada; B69–B71 criadas

## Etapa 73 — baremetal-report ESP (feita)

- ADR 0025; flush SFS pré-exit; METAL_OK via report
