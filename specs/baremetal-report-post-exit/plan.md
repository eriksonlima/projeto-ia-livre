# Plan — baremetal-report pós-ExitBoot

1. Estender `baremetal_report.rs`: slot magic + locate BlockIO + post buffer + flush
2. Wire `uart_write` → post buffer; chamar flush antes do `halt`
3. Docs + gate (`REPORT_POST_OK` no `make verify` / script) + ROADMAP
