# Spec — Linux IA-nativo produto (config, tune, smoke, USB)

## Objetivo

Completar o caminho de produto ADR 0027 após o scaffold (E77): config/qualquer GGUF, tuning nativo, smoke rootfs, artefato USB Linux (≠ ESP UEFI).

## Escopo

- E78/B73: `model list|set|show` + `/var/lib/ia-livre/models` + docs
- E79/B74: sysctl + `ia-livre-native-tune` (SKIP honesto sem root)
- E80/B75: pack rootfs + `verify-distro-smoke` (userspace; QEMU best-effort/skip)
- E81/B76: guia + prepare/write Linux USB + gate de artefato (sem device no CI)

## Fora de escopo

- ISO Debian live completa
- COMPROVA / Linha B / METAL_OK
- TCP no guest UEFI

## Pronto quando

Gates `verify-distro-config-models`, `verify-distro-native-tune`, `verify-distro-smoke`, `verify-linux-usb-artifact` passam; docs alinhados.
