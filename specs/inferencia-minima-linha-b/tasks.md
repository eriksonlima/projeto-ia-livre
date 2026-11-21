# Tasks — Inferência mínima / TOKENS_PER_S na Linha B

Uma task = uma fatia.

- [x] Task 1 — Contrato documental + decisão A (fatia mínima); rejeitar B; nomear `no_gguf_infer_engine`
  - **Feito:** ADR 0009; pivô BlockIO documentado (FAT16 cap); docs/runtime-nativo atualizado. README considerado (sem mudança).

- [x] Task 2 — Infra: `-m` QEMU + GGUF completo + carga guest
  - **Feito:** `QEMU_MEM=1536M`; `build/gguf-canon.gguf` + `-blockdev`/`ide-hd`; kernel BlockIO lê tamanho de `model.gguf.sz`.

- [x] Task 3 — Parse stub de tensores/metadados GGUF
  - **Feito:** `GGUF_TENSOR_COUNT=` + `GGUF_TENSORS_STUB_OK`; sem motor.

- [x] Task 4 — Harness + gate: `B_BLOCK=no_gguf_infer_engine`
  - **Feito:** verify / verify-harness / comparable OK; `INCONCLUSIVO`; sem TOKENS inventados.
