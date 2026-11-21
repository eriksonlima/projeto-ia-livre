# Spec — Runtime falando o contrato nativo (além do proxy Linha B)

## Resultado visível

Runtime (host via shim e, opcionalmente após Etapa 19, caminho nativo) que **exerce** o contrato candidato ADR 0003 — classes `Weights`/`KvCache` e hints Prefill/Decode — com evidência verificável (marcadores stdout/serial). O harness B permanece **honesto**: o proxy E12 continua sendo proxy; evidência de contrato **não** finge `TOKENS_PER_S` GGUF nem comprova a hipótese A vs B.

## Fora de escopo

- Editar `kernel/` enquanto a Etapa 19 estiver `em_andamento` (contrato B13 é do outro agente)
- Inventar ABI incompatível com [`docs/desenho-memoria-scheduler-nativo.md`](../../docs/desenho-memoria-scheduler-nativo.md) / ADR 0003
- Carga GGUF canônica na Linha B (B15)
- Prova/refutação da hipótese (B16)
- GPU manager / multi-GPU (ADR 0006 / B19)
- Declarar hipótese comprovada; emitir `TOKENS_PER_S` em B

## Critérios de aceite

- [ ] Doc canônico do consumidor do contrato (`docs/runtime-contrato-nativo.md`) + pontes nos docs E12/harness/desenho
- [ ] Shim/stub host verificável sem QEMU e sem kernel E19 mergeado; marcadores `IA_LIVRE_CONTRACT_*` + `IA_LIVRE_RUNTIME_CONTRACT_OK`
- [ ] Gate host documentado (`make verify-runtime-contract`); `make verify-harness` não regride
- [ ] Integração QEMU contra contrato real E19 só quando desbloqueada; caso contrário task marcada bloqueada
- [ ] Hipótese **não** comprovada; shim host **≠** Linha B

## Riscos e rollback

- Colisão com agente E19 em `kernel/` / `AGENTS.md` / `Makefile` → mudanças aditivas na branch `etapa-b14-runtime-contrato`; sem claim do lease global
- Marcadores E19 ainda não mergeados → documentar nomes **candidatos** do Pronto quando E19; shim usa namespace `CONTRACT_*` próprio
- Confundir evidência de contrato com prova A vs B → docs explícitos

## Etapa do roadmap

Etapa 20 — Runtime falando o contrato nativo (além do proxy Linha B) — Issue [#20](https://github.com/eriksonlima/projeto-ia-livre/issues/20) — Status: `pendente` (E19 permanece `em_andamento`)
