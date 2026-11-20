# Tasks — Kernel além do boot

Uma task = uma fatia.

- [x] Task 1 — Contrato documental (mapa UEFI + alocação/bump sob Boot Services) + marcadores canônicos
  - **Pronto quando:** `docs/kernel-alem-do-boot.md` existe com decisão de desenho, tabela `IA_LIVRE_MEM_MAP_OK` / `IA_LIVRE_ALLOC_OK` (+ campos numéricos), fora de escopo (sem ExitBoot, sem inferência) e como observar na serial; ponte mínima em `docs/architecture.md` se couber; `AGENTS.md` menciona a doc/intenção; README avaliado (`readme-por-fatia`).
  - **Feito:** doc + ponte architecture + AGENTS; README considerado (capa já aponta AGENTS — sem mudança).

- [x] Task 2 — Mapa de memória + `AllocatePages` + bump no `kernel/` com marcadores na serial
  - **Pronto quando:** `make run` em QEMU UEFI emite `IA_LIVRE_BOOT_OK`, `IA_LIVRE_MEM_CONVENTIONAL_PAGES=` (ou equivalente documentado), `IA_LIVRE_MEM_MAP_OK`, `IA_LIVRE_ALLOC_BYTES=` (> 0) e `IA_LIVRE_ALLOC_OK`; bump exercita o buffer (write/read); doc atualizada com N de páginas e exemplo; Como rodar em `AGENTS.md` reflete os marcadores; README reavaliado.
  - **Feito:** `PROOF_PAGES=2`, bump 64 B; serial completa no QEMU; README considerado (sem mudança).

- [ ] Task 3 — Gate do kernel estendido (`make verify`) + `AGENTS.md` → Como verificar
  - **Pronto quando:** `scripts/verify-boot.sh` (ou equivalente documentado) exige `BOOT_OK` + `MEM_MAP_OK` + `ALLOC_OK` e falha se faltar algum; `make verify` passa no ambiente de referência; timeout documentado; outros gates não regridem; README reavaliado; etapa pronta para revisão (não marcar `feita` aqui).
