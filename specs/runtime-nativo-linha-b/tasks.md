# Tasks — Runtime nativo / Linha B real (mínimo)

Uma task = uma fatia.

- [x] Task 1 — Contrato documental (proxy pós-ExitBoot + marcadores B + limites vs carga canônica)
  - **Pronto quando:** `docs/harness-linha-a-b.md` (e doc curto opcional `docs/runtime-nativo-linha-b.md`) descrevem o desenho único: execução real mínima no IA Livre via microbenchmark pós-`ExitBoot`; tabela do que B emite (`LINE=B`, `HARNESS_OK`, `PROXY=post_exit_microbench`, `LOAD_KIND=proxy`, `PROXY_MS`/`PROXY_OPS`, `MODEL=proxy-post-exit-v1`, `N_PREDICT=0`); proibição de `TOKENS_PER_S` / fingir TinyLlama; aviso explícito de que a hipótese **não** está comprovada e A/B **não** são comparáveis nesta etapa; marcadores kernel `NATIVE_BENCH_*` nomeados; pontes em `docs/kernel-pos-boot-services.md` e `docs/architecture.md`; `AGENTS.md` menciona a intenção; README avaliado (`readme-por-fatia`). Sem código de produto além do necessário para docs.
  - **Feito:** docs + pontes; README considerado (sem mudança).

- [x] Task 2 — Microbenchmark real pós-ExitBoot no `kernel/` (marcadores `NATIVE_BENCH_*`)
  - **Pronto quando:** após a cadeia Etapa 11 (`EXIT_BOOT_OK`), o kernel em QEMU executa trabalho real mínimo (CPU/memória) e emite na serial COM1 `IA_LIVRE_NATIVE_BENCH_BEGIN`, `IA_LIVRE_NATIVE_BENCH_OPS=`, `IA_LIVRE_NATIVE_BENCH_MS=` (ou política de tempo documentada na Task 1) e `IA_LIVRE_NATIVE_BENCH_OK` com valores **medidos**; `make verify` do kernel **não** regride (marcadores EXIT_* continuam); doc com exemplo de serial; Como rodar em `AGENTS.md` reflete os novos marcadores; README reavaliado. Sem alterar ainda o stub do harness B (isso é Task 3).
  - **Feito:** RDTSC + touch memória; `make verify` inclui NATIVE_BENCH_OK.

- [x] Task 3 — Substituir stub B + gate `verify-harness` coerente
  - **Pronto quando:** `scripts/run-harness-line-b.sh` sobe build/ESP/QEMU, captura serial e, só com `EXIT_BOOT_OK` + `NATIVE_BENCH_OK` (+ métricas), emite `IA_LIVRE_HARNESS_LINE=B` + `HARNESS_OK` + marcadores proxy do contrato — **sem** `HARNESS_B_SKIP` no sucesso e **sem** `TOKENS_PER_S`; `scripts/verify-harness.sh` / `make verify-harness` exige A (GGUF, como hoje) **e** B (OK proxy); falha se B inventar tokens ou se faltar proxy; mensagem de gate deixa claro “hipótese não comprovada”; `AGENTS.md` → Como verificar atualizado; README reavaliado; etapa pronta para revisão (não marcar `feita` aqui).
  - **Feito:** `GATE_OK: harness — A ok + B proxy`; README considerado.
