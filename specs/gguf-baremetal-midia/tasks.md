# Tasks — GGUF canônico completo em mídia bare-metal (+ path I/O)

Etapa 36 · Spec: `specs/gguf-baremetal-midia/`

Uma task = uma fatia.

- [ ] Task 1 — Criar `docs/gguf-baremetal-midia.md` (modos a/b, path UEFI SimpleFileSystem, limites honestos) + atualizar `docs/boot-hardware-real.md` com seção "GGUF na mídia"
- [ ] Task 2 — Estender `scripts/make-baremetal-esp.sh` com flag `IA_LIVRE_BAREMETAL_FULL_GGUF=1` (copia GGUF, emite SHA/tamanho) + estender `scripts/verify-baremetal.sh` com gate `BAREMETAL_GGUF_OK` + atualizar `AGENTS.md`
- [ ] Task 3 — Adicionar seção "Glue loader" em `docs/gguf-baremetal-midia.md` (pseudocódigo/Rust do loader UEFI: discovery → open → header read → fallback honesto) + atualização final de `AGENTS.md` e docs de evidência
