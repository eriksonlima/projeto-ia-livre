# Tasks — Guia “primeiro boot USB” + release de artefato (Etapa 57)

Uma task = uma fatia. Etapa 57 · Issue [#57](https://github.com/eriksonlima/projeto-ia-livre/issues/57).

- [ ] Task 1 — Guia passo a passo `docs/guia-primeiro-boot-usb.md` (Secure Boot, serial, o que esperar/não esperar; hipótese INCONCLUSIVO) + ponte em `docs/boot-hardware-real.md` (+ AGENTS/README se couber)
- [ ] Task 2 — Script `scripts/prepare-baremetal-release.sh`: staging ESP/tar (+ img opcional) + `SHA256SUMS` + procedimento documentado de tag/GitHub Release (sem USB; sem GGUF full default)
- [ ] Task 3 — Gate `make verify-boot-guide-release` (guia + checksums consistentes; marcadores; sem USB) + fechamento AGENTS / README (`readme-por-fatia`)
