# Tasks — Harness da hipótese Linha A vs Linha B

Uma task = uma fatia.

- [x] Task 1 — Metodologia documentada + contrato do slot Linha B + ponte em architecture (e avisos vs métricas E5/E8)
  - **Pronto quando:** `docs/harness-linha-a-b.md` existe com carga canônica, métricas/`IA_LIVRE_HARNESS_*`, definição A vs B nesta etapa, limitação da referência A, contrato do stub B e aviso de que E5/E8 não são o harness; `docs/architecture.md` aponta o harness; README avaliado (`readme-por-fatia`).

- [x] Task 2 — Harness Linha A executável (wrapper do runtime) + stub Linha B com skip canônico
  - **Pronto quando:** comando/script documentado roda A no host e emite `IA_LIVRE_HARNESS_LINE=A` + `IA_LIVRE_HARNESS_OK` + load/tokens (mesma carga canônica); stub B emite `IA_LIVRE_HARNESS_B_SKIP` sem números inventados; baseline A de exemplo na doc do harness; Como rodar parcial/completo em `AGENTS.md`; README reavaliado.

- [x] Task 3 — Gate `make verify-harness` + política A obrigatória / B skip + `AGENTS.md` → Como verificar
  - **Pronto quando:** `make verify-harness` passa com A ok e B skip; timeout documentado; não exige QEMU/GPU; `AGENTS.md` cobre verificar; gates existentes não regridem por mudanças acidentais; README reavaliado; etapa pronta para revisão (não marcar `feita` aqui).
