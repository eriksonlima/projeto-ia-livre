# Active context

## Foco atual

- Etapas 1–96 **feitas**; Abertas vazio
- Live USB: hostname `ialivre`, nano/vi, Wi‑Fi (`ia-livre wifi`), firmwares comuns

## Próximo passo

- Sem item em Abertas — aguardar novo pedido / backlog

## Notas

- Guia: docs/guia-usuario-ia-livre-linux.md
- Kernel custom: ADR 0028 deferred (stock Debian)
- Rebuild live: `IA_LIVRE_REFRESH_SKIP_STAGE=1 ./scripts/refresh-distro-live-overlay.sh` + `IA_LIVRE_ISO_RESQUASH=1 ./scripts/build-distro-debian-iso.sh`
