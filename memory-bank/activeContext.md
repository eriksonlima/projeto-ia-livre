# Active context

## Foco atual

- Processo: backlog → roadmap (mínima interrupção)
- Etapa do roadmap: **Etapa 10 — Kernel além do boot** (`em_andamento`, Issue #10)
- Spec ativa: `specs/kernel-alem-do-boot/` (Tasks 1–2 feitas; Task 3 aberta)

## Mudanças recentes

- Seed backlog B4–B6 (#10–#12); B4 promovido a Etapa 10
- Task 1: contrato `docs/kernel-alem-do-boot.md`
- Task 2: mapa + AllocatePages(2) + bump 64 B → marcadores na serial QEMU

## Próximo passo

- Task 3: estender `make verify` / `verify-boot.sh` para MEM_MAP_OK + ALLOC_OK

## Notas

- B5 (Linha B real) e B6 (desenho scheduler/memória) permanecem em Abertas
- Sem ExitBootServices / inferência no kernel nesta etapa
