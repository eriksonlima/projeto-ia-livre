# Spec — Persistência pós-ExitBoot no baremetal-report (Etapa 74)

## Resultado visível

Marcadores pós-ExitBoot (`EXIT_*`, `MEM_SCHED_*`, métricas subset) persistem no canal bare-metal **sem UART**, via slot BlockIO no mesmo arquivo report (ou região documentada), com `IA_LIVRE_BAREMETAL_REPORT_POST_OK`.

## Fora de escopo

- `COMPROVA` / harness comparable / espécie canônica
- Vídeo como gate
- DHT / GPU VFIO / autonomia UX
- B70 (tokens no report) / B71 (collect script)

## Critérios de aceite

- [x] Pré-exit: report V1 + slot pós-exit reservado (magic) na ESP via SFS
- [x] Pós-exit: buffer alimentado por `uart_write`; flush BlockIO no slot
- [x] Marcadores `REPORT_POST_OK` (sucesso) ou `REPORT_POST_FAIL=…` (honesto)
- [x] Docs `baremetal-report.md` + ADR 0025 addendum / ponte
- [x] Gate: serial (`make verify`) vê `REPORT_POST_OK` **ou** script dedicado; `verify-baremetal` artefato intacto
- [x] Sem inventar `METAL_OK` / `TOKENS` / `COMPROVA`

## Riscos e rollback

- BlockIO após ExitBoot é best-effort em firmware; falha → `POST_FAIL` sem travar boot
- Rollback: remover flush pós-exit; pré-exit E73 permanece

## Etapa do roadmap

Etapa 74 · Issue #75 · B69
