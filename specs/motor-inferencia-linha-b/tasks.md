# Tasks — Motor de inferência GGUF mínimo na Linha B

Uma task = uma fatia. Ordem: 1 → 2 → 3 → 4.

- [x] Task 1 — ADR 0010 + desenho
  - **Feito:** ADR 0010; `desenho-motor-inferencia-linha-b.md`; pontes. README considerado (sem mudança na Task 1).

- [x] Task 2 — Crate `no_std` + wire + parse/layout
  - **Feito:** `runtime-native/` (`ia-livre-runtime-native`); `prepare()` atravessa metadata+tensor infos; kernel emite `NATIVE_INFER_BEGIN` / `LAYOUT_OK`; unit test no GGUF canônico; `make build` ok.

- [x] Task 3 — Geração mínima **ou** bloqueio honesto novo
  - **Feito (fallback):** `try_forward_canonical` → `NoForwardImpl`; serial `FORWARD_FAIL=no_impl`; `B_BLOCK=no_gguf_forward`. Sem tokens inventados. ADR 0001 intacta.

- [x] Task 4 — Métricas/harness/comparable
  - **Feito:** gates exigem `layout_ok` + `no_gguf_forward`; comparable `INCONCLUSIVO` reason E29; AGENTS atualizado; README avaliado (estrutura/capa — menção runtime-native via AGENTS).
