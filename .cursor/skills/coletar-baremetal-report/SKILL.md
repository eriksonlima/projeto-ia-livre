---
name: coletar-baremetal-report
description: >-
  Coleta baremetal-report.txt de um pendrive montado (IALIVRE) para
  docs/evidence/boot-metal/ e opcionalmente roda verify-baremetal SKIP=0.
  Use após boot USB/metal ou quando o operador pedir METAL_OK via report ESP.
disable-model-invocation: true
---

# Coletar baremetal-report

## Quando usar

- Operador bootou o pendrive e montou o volume no Linux
- Precisa versionar evidência / validar `METAL_OK` sem COM1

## Passos

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
./scripts/collect-baremetal-report.sh --mount /media/$USER/IALIVRE
# ou com validação:
./scripts/collect-baremetal-report.sh --mount /media/$USER/IALIVRE --verify
```

Gate smoke (sem USB): `make verify-collect-baremetal-report`.

Contrato: `docs/baremetal-report.md`.
