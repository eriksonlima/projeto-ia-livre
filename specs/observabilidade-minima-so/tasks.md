# Tasks — Observabilidade mínima no SO (além de UART-only)

Etapa 37 · Spec: `specs/observabilidade-minima-so/`

Uma task = uma fatia.

- [x] Task 1 — Criar `docs/observabilidade-minima-so.md` (GOP primário, fallback SimpleTextInput, marcadores, limites sem desktop) + atualizar `docs/boot-hardware-real.md` e ponte em doc do kernel
- [x] Task 2 — Implementar GOP fill+texto mínimo e fallback SimpleTextInput em `kernel/` (antes de `EXIT_BOOT_BEGIN`) com `IA_LIVRE_GOP_OK` / `IA_LIVRE_INPUT_OK` / `IA_LIVRE_OBS_OK` na serial UEFI
- [x] Task 3 — Estender `scripts/verify-boot.sh` + `AGENTS.md` (gate aditivo, `VERIFY_TIMEOUT` se necessário) e confirmar que `make verify` permanece verde sem afetar harness/hypothesis