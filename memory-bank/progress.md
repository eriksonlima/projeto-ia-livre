# Progress

## O que funciona

- Gates de produto; ADRs 0001–0007
- Etapas 1–20 feitas
- E20: `verify-runtime-contract` (host_shim) + harness B com `HARNESS_CONTRACT_*` + proxy
- E21 (fechando): harness B com `CONTRACT_READY=1` + `GGUF_TARGET_*` + bloqueio honesto `B_BLOCK=no_gguf_path`; `make verify` + `make verify-harness` OK

## Bloqueios

- Hipótese A vs B **não** comprovada (prova/refutação = Etapa 22 / B16)
- Carga GGUF real em B ainda ausente (`no_gguf_path` — sem loader nativo no QEMU)

## Por etapa

- 1–20: feitas
- 21: Tasks 1–4 feitas; desfecho bloqueio honesto; a marcar `feita` + merge main
- 22–25: `pendente` em branches paralelas — não duplicar
