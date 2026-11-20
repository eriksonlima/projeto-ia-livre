# Tasks — Kernel pós-Boot Services

Uma task = uma fatia.

- [x] Task 1 — Contrato documental (ExitBoot + dual-phase + UART COM1) + marcadores canônicos
  - **Pronto quando:** `docs/kernel-pos-boot-services.md` existe com decisão de desenho (pré-exit UEFI → `exit_boot_services` → pós-exit COM1 `0x3F8`), tabela de marcadores (`EXIT_BOOT_BEGIN`, `EXIT_MAP_*`, `EXIT_MEM_OK`, `EXIT_BOOT_OK`), fora de escopo (sem inferência, sem MMU completa) e como observar na serial; ponte em `docs/kernel-alem-do-boot.md` e mínima em `docs/architecture.md`; `AGENTS.md` menciona a doc/intenção; README avaliado (`readme-por-fatia`).
  - **Feito:** doc + pontes; README considerado (sem mudança).

- [x] Task 2 — `exit_boot_services` + UART COM1 + mapa/memória pós-exit no `kernel/`
  - **Pronto quando:** `make run` em QEMU UEFI emite marcadores Etapa 10, `IA_LIVRE_EXIT_BOOT_BEGIN`, e pós-exit (via COM1) `IA_LIVRE_EXIT_MAP_PAGES=` / `IA_LIVRE_EXIT_MAP_OK`, `IA_LIVRE_EXIT_MEM_OK` e `IA_LIVRE_EXIT_BOOT_OK`; bump reprovado **após** o exit no bloco pré-alocado; doc com exemplo de serial; Como rodar em `AGENTS.md` reflete os marcadores; README reavaliado.
  - **Feito:** serial QEMU completa; README considerado (sem mudança).

- [ ] Task 3 — Gate do kernel estendido (`make verify`) + `AGENTS.md` → Como verificar
  - **Pronto quando:** `scripts/verify-boot.sh` exige marcadores Etapa 4/10 **e** `IA_LIVRE_EXIT_BOOT_OK` (e, se barato, `EXIT_MAP_OK` + `EXIT_MEM_OK`) e falha se faltar algum; `make verify` passa no ambiente de referência; timeout documentado; outros gates não regridem; README reavaliado; etapa pronta para revisão (não marcar `feita` aqui).
