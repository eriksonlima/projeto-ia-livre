# Tasks — Boot UEFI em hardware real (evidência serial) (Etapa 35)

Uma task = uma fatia.

- [x] Task 1 — Contrato operacional: expandir `docs/boot-hardware-real.md` com procedimento de captura serial (COM1 115200 8N1, ferramentas host, checklist Secure Boot/mídia), formato de evidência (cabeçalho + SHA256 do EFI + trecho serial), tabela QEMU vs artefato vs metal; criar `docs/evidence/boot-metal/README.md` (+ template/example honesto)
- [x] Task 2 — Gate de evidência: estender `scripts/verify-baremetal.sh` — `SKIP=0` valida `IA_LIVRE_BAREMETAL_EVIDENCE` (≥ `IA_LIVRE_BOOT_OK`, rejeita indicadores QEMU/OVMF, opcional checagem SHA do EFI); `SKIP=1` preserva E30; emitir `IA_LIVRE_BAREMETAL_METAL_OK` ou equivalente documentado; script auxiliar de cabeçalho/evidência opcional
- [x] Task 3 — Pontes e fecho: atualizar `AGENTS.md` (Como verificar metal); anexar evidência real em `docs/evidence/boot-metal/` **ou** registrar skip honesto na issue #34; `make verify-baremetal` verde nos dois modos; avaliar `README.md`; confirmar critérios da spec
