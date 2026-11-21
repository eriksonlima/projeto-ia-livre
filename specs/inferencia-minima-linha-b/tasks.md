# Tasks — Inferência mínima / TOKENS_PER_S na Linha B

Uma task = uma fatia.

- [ ] Task 1 — Contrato documental + decisão A (fatia mínima); rejeitar B; nomear `no_gguf_infer_engine`
  - **Pronto quando:** `docs/runtime-nativo-linha-b.md` + harness (+ comparable se preciso) descrevem: escolha A fatiada; alvo de `-m`; path do GGUF completo no ESP; evolução `GGUF_NATIVE_LOADER` / `GGUF_STATUS`; `B_BLOCK=no_gguf_infer_engine`; proibição de `TOKENS_PER_S`/microbench-como-tokens; ADR 0009; `AGENTS.md` atualizado; README avaliado. Sem implementação de carga além do necessário para docs.

- [ ] Task 2 — Infra: `-m` QEMU + GGUF completo no ESP + carga guest além do prefixo 4 KiB
  - **Deps:** Task 1.
  - **Pronto quando:** scripts/`Makefile` aplicam `-m` documentado; staging coloca o GGUF canônico completo no ESP; guest lê (chunked ok) em Boot Services e emite marcadores de progresso/bytes; `make verify` (ou evidência serial equivalente) cobre o caminho; **sem** geração/`TOKENS_PER_S`.

- [ ] Task 3 — Parse stub de tensores/metadados GGUF (honesto, sem motor)
  - **Deps:** Task 2.
  - **Pronto quando:** parse mínimo (contagem/tabela/metadados documentados) com marcador serial (ex. `GGUF_TENSORS_STUB_OK`); ponte tipada `Weights` se couber; **sem** matmul/decode/sampling; hipótese não comprovada.

- [ ] Task 4 — Harness + gate: `B_BLOCK=no_gguf_infer_engine`; sem inventar tokens
  - **Deps:** Task 3.
  - **Pronto quando:** `run-harness-line-b.sh` reemite loader/status/`B_BLOCK=no_gguf_infer_engine`; `make verify-harness` (e boot/comparable) alinhados; timeout documentado se necessário; **ausência** de `TOKENS_PER_S`/`LOAD_KIND=gguf` fingido; comparable `INCONCLUSIVO`; docs/`AGENTS.md` finais; README reavaliado.
