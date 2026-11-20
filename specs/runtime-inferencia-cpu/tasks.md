# Tasks — Runtime mínimo de inferência (CPU)

Uma task = uma fatia.

- [x] Task 1 — Scaffold do crate `runtime/` (Rust host no workspace, binding llama.cpp ou esqueleto com fallback CLI documentado), script/instrução para baixar um GGUF pequeno em path gitignored, layout e **Como rodar** parcial em `AGENTS.md`; sem regressão do `make verify` do kernel
  - **Pronto quando:** `cargo build` do runtime sucede; modelo obtível por doc/script; pesos fora do git; AGENTS lista pré-requisitos e path do modelo.

- [x] Task 2 — Load + inferência CPU com prompt fixo documentado, gerando texto na stdout via comando único em **Como rodar**
  - **Pronto quando:** no host de referência, o comando documentado carrega o GGUF em CPU e imprime texto gerado; erros de modelo ausente falham de forma clara.

- [x] Task 3 — Métricas básicas (tempo de load + tokens/s ou latência) emitidas de forma verificável, documentadas em `docs/runtime-inferencia-cpu-metricas.md`, e gate adicional em `AGENTS.md` → **Como verificar**
  - **Pronto quando:** marcadores/métricas aparecem na execução; doc de métricas preenchida no host de referência; gate do runtime passa; gate do kernel permanece verde.
