# Tasks — Bootstrap do kernel IA Livre

Uma task = uma fatia.

- [x] Task 1 — Scaffold do crate `kernel/` (Rust freestanding + uefi-rs, target `x86_64-unknown-uefi`), Makefile/scripts de build e QEMU+OVMF, `.gitignore` para `target/`, layout e **Como rodar** documentados em `AGENTS.md`
- [x] Task 2 — Mensagem serial canônica `IA_LIVRE_BOOT_OK` no boot UEFI em QEMU e gate em `AGENTS.md` → **Como verificar** que falha se a string não aparecer
