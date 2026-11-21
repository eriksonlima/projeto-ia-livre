# ADR 0009 — Inferência Linha B: fatia mínima A (RAM + arquivo + stub)

- Status: aceita
- Data: 2026-11-20

## Contexto

Etapa 26 entrega loader ESP de **prefixo 4 KiB** (`esp_header`) com QEMU `-m 256M`. O GGUF canônico (~638 MiB) não cabe; não há motor de geração no guest. Inventar `TOKENS_PER_S` (microbench rotulado como TinyLlama) quebraria a hipótese.

## Decisão

1. **Via A fatiada:** nesta etapa (27) — aumentar `-m` QEMU; GGUF **completo** no guest via **disco raw + BlockIO** (não via `fat:rw` ESP — QEMU FAT16 ~516 MiB < ~638 MiB); ESP só com `gguf.hdr` + `model.gguf.sz`; parse stub de metadados/tensores.
2. **Motor / geração / `TOKENS_PER_S`:** fora do mínimo obrigatório; desfecho residual `B_BLOCK=no_gguf_infer_engine`.
3. **Rejeitado:** opção B (tokens de microbench não canônico); fingir `LOAD_KIND=gguf` com geração; rotular host runtime como B; fingir arquivo completo no ESP `fat:rw`.

## Consequências

- `GGUF_NATIVE_LOADER=esp_full` (ou equivalente); `GGUF_STATUS=tensors_stub_ok`.
- Gates exigem avanço de arquivo/parse e **proíbem** tokens inventados.
- Etapas futuras: motor mínimo + `TOKENS_PER_S` medidos em B.
