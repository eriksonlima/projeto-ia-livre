# Tasks — Loader GGUF nativo mínimo na Linha B

Uma task = uma fatia.

- [x] Task 1 — Contrato documental + decisão de I/O (ESP canônico; desbloquear `no_gguf_path` no papel)
  - **Pronto quando:** docs + ADR 0008 + pontes; sem implementação além do necessário para docs.
  - **Feito:** `docs/adr/0008-loader-gguf-esp-pre-exitboot.md`, `docs/runtime-nativo-linha-b.md`, `docs/harness-linha-a-b.md`, `docs/architecture.md`, `AGENTS.md`. README considerado (sem mudança — capa já aponta harness/AGENTS).

- [x] Task 2 — I/O guest mínimo (artefato no ESP + leitura UEFI + cópia para buffer/`Weights`)
  - **Deps:** Task 1.
  - **Feito:** `scripts/esp-stage-gguf-prefix.sh` + `make esp`; `kernel/src/main.rs` lê `\IA_LIVRE\gguf.hdr`, magic GGUF, seed Weights; marcadores serial. `make verify` OK.

- [x] Task 3 — Marcadores + harness B (reemissão; `GGUF_NATIVE_LOADER` ≠ `absent`)
  - **Deps:** Task 2.
  - **Feito:** `run-harness-line-b.sh` → `esp_header` / `header_ok` / `no_gguf_infer`; sem TOKENS_PER_S.

- [x] Task 4 — Gate atualizado (verify-harness / verify; sem inventar tokens)
  - **Deps:** Task 3.
  - **Feito:** `verify-boot.sh` + `verify-harness.sh` + `run-harness-a-b-comparable.sh`; gates OK; hipótese não comprovada.
