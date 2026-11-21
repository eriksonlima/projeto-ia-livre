# Plan — Nó Rede no SO nativo (pós-ExitBoot ou bridge)

## Abordagem

1. **Fixar B** — Documentar por que A (TCP pós-Exit) é inviável agora (sem NIC/driver/`std`) e escolher bridge UEFI↔host no padrão E49.
2. **Contrato** — `docs/rede-bridge-nativo.md` (+ ADR curto se couber): fontes nativas (serial pós-Exit / Line B), marcadores `IA_LIVRE_NET_BRIDGE_*`, âncora `ia-livre-node`, distinção vs `BRIDGE_*` E49, ADR 0001.
3. **Consumidor** — Script host que valida evidência caminho B **e** dispara prova Rede mínima (preferir `TASK_OK` / E51), emitindo `NET_BRIDGE_OK`.
4. **Gate** — `make verify-…` adicional; `verify-node` intacto; AGENTS + README avaliado.

Ordem das fatias = ordem das tasks. Uma fatia por vez.

## Arquivos prováveis

- `specs/no-rede-so-nativo/` — esta spec
- `docs/rede-bridge-nativo.md` — contrato (novo)
- `docs/adr/0019-….md` — opcional (bridge Rede host↔nativo)
- `docs/rede-ia-livre-v1.md` — ponte curta
- `docs/autonomia-bridge-nativo.md` — distinção E49 vs E52
- `scripts/run-rede-bridge.sh` (ou nome fixado na Task 1) — consumidor
- `scripts/verify-rede-bridge.sh` — gate
- `Makefile` — alvo `verify-…`
- `AGENTS.md` — Como rodar / verificar
- `node/` — **somente** como subprocesso já existente; sem portar para UEFI
- `kernel/` / `runtime-native/` — **fora** salvo se Task 1 reabilitar A com evidência (não esperado)
- `ROADMAP.md` / Memory Bank — agente principal no fim da etapa

## Dependências

- E11 + serial QEMU (`make verify` / harness B) como fonte de evidência caminho B.
- `ia-livre-node` + `make verify-node` como âncora Rede (E51 `TASK` preferível).
- Padrão E49 (`run-autonomia-bridge.sh`) como referência de forma — **não** reutilizar os mesmos marcadores.
- Sem GGUF obrigatório se a evidência nativa for só `EXIT_*` / boot; se a fonte for harness B completo, GGUF pode ser necessário — fixar na Task 1 a fonte **mínima** barata.

## Verificação

- Critérios de aceite da `spec.md`.
- Gate novo em `AGENTS.md`.
- Regressão: `make verify-node` (sem QEMU) + `make verify-autonomia-bridge` não quebrados.
- Sem TCP teatral no guest; ADR 0001 preservada.
