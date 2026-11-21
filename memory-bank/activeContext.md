# Active context

## Foco atual

- Etapas **1–27 feitas**
- E27: `blockio_full` + `tensors_stub_ok` + `B_BLOCK=no_gguf_infer_engine`
- Backlog Abertas: **B22** (re-corrida quieta)
- Lease: livre

## Mudanças recentes

- Métricas CPU serial (~13,4 tok/s mediana)
- E26 loader ESP header; E27 GGUF completo via BlockIO (FAT16 cap documentada)
- Hipótese ainda INCONCLUSIVO (sem TOKENS_PER_S em B)

## Próximo passo

- Promover B22 ou etapa de **motor de inferência** em B (novo item) para sair de `no_gguf_infer_engine`

## Notas

- Medições T/s: um gate por vez
- `build/gguf-canon.gguf` gitignored via `build/`
