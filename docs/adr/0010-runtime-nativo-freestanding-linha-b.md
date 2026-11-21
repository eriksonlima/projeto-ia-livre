# ADR 0010 — Runtime nativo freestanding na Linha B

- Status: aceita
- Data: 2026-11-21

## Contexto

Etapa 27 deixou o GGUF canônico na RAM do guest (`blockio_full` + stub) com `B_BLOCK=no_gguf_infer_engine`. A hipótese A vs B permanece `INCONCLUSIVO` até existir geração medida em B. ADR 0001 exige inferência **fora** do kernel. Embutir llama.cpp (ou motor completo) em `kernel/src/main.rs` como produto viola essa fronteira e ADR 0009 já excluiu inventar `TOKENS_PER_S`.

## Decisão

1. **Crate** `ia-livre-runtime-native` em `runtime-native/` — `no_std` / freestanding, membro do workspace; **não** depende de `std` nem de llama-cpp-2.
2. **Kernel** orquestra: loader BlockIO (E26/E27), alloc tipado E19, serial; **chama** a API mínima da crate pós-ExitBoot. Glue fino em `main.rs` é permitido; o motor **não** vive como produto monolítico no kernel.
3. **Escopo alvo:** TinyLlama 1.1B Chat v1.0 Q4_K_M; prompt `Complete em uma frase: O Projeto IA Livre é`; `n-predict=32`; CPU.
4. **Sucesso:** `LOAD_KIND=gguf` + `LOAD_S` / `TOKENS_PER_S` **medidos** no guest + `MODEL` / `N_PREDICT` canônicos.
5. **Fallback honesto (esta etapa se forward inviável):** `B_BLOCK=no_gguf_forward` após avanço verificável (crate + layout/tensores além do stub E27); **proibido** inventar tokens; proxy E12 pode permanecer.

## Rejeitado

- Motor completo / llama.cpp como produto em `kernel/src/main.rs`
- Microbench E12 ou tipado E19 rotulado como `TOKENS_PER_S` TinyLlama
- Contar `ia-livre-runtime` (host) como evidência de B
- Renomear `no_gguf_infer_engine` sem crate/intermediários

## Consequências

- Workspace ganha `runtime-native/`; `kernel` depende via path.
- Marcadores: `IA_LIVRE_NATIVE_INFER_*` / `RUNTIME_NATIVE_*` (ver desenho).
- Gates passam a exigir layout/motor intermediário e o `B_BLOCK` atualizado (ou métricas reais se geração existir).
- Hipótese só deixa `INCONCLUSIVO` com tokens B reais em espécie.
- Etapa 71: superfície mínima versionada (`ABI_VERSION` / `ABI_OK`) — [`abi-runtime-native.md`](../abi-runtime-native.md).
