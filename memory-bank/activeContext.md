# Active context

## Foco atual

- Etapa **32** `em_andamento` (#42)
- Tasks 1–2 **feitas**; Task 3 próxima (camada parcial → tokens ou B_BLOCK novo)

## Mudanças recentes

- Task 2: tokenize ids fixos + embed `token_embd` Q4_K (unit tests ok)
- `IA_LIVRE_DUMP_TOKEN_IDS=1` no runtime host para regenerar ids

## Próximo passo

- Task 3: camada transformer parcial + Prefill/Decode ou `B_BLOCK=no_gguf_decode`

## Notas

- README: Task 2 interna — capa não precisa mudar
