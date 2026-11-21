# Plan — Autonomia mínima no caminho nativo (ou bridge SO↔host)

## Abordagem

1. **Fixar B** — Documentar por que A (agente no guest) é inviável agora (sem shell/rede/FS; ADR 0001) e escolher bridge host↔nativo.
2. **Contrato** — `docs/autonomia-bridge-nativo.md` (+ ADR curto se a fronteira for estável): fontes `blockio` (geração E44) e `metal_block` (E48); marcadores `IA_LIVRE_BRIDGE_*`; o que não prova.
3. **Consumidor** — Script ou extensão mínima no host que valida log/serial nativo **ou** chama um entrypoint já existente do repo (harness B / metal-infer) e emite `BRIDGE_OK`.
4. **Gate** — `make verify-…` adicional; `verify-agent` intacto; AGENTS + README avaliado.

Ordem das fatias = ordem das tasks. Uma fatia por vez.

## Arquivos prováveis

- `specs/autonomia-bridge-nativo/` — esta spec (já gerada)
- `docs/autonomia-bridge-nativo.md` — contrato (novo)
- `docs/adr/0018-….md` — opcional (bridge host↔nativo)
- `docs/desenho-autonomia-v1.md` / `docs/autonomia-alem-v1.md` — pontes
- `docs/runtime-nativo-linha-b.md` / `docs/gguf-baremetal-midia.md` — pontes curtas
- `scripts/run-agent-bridge-nativo.sh` (ou nome fixado na Task 1) — consumidor
- `scripts/verify-agent-bridge.sh` (ou equivalente) — gate
- `Makefile` — alvo `verify-…`
- `AGENTS.md` — Como rodar / verificar
- `agent/` — **só se** one-shot integrar bridge; preferir script fino se evitar acoplar QEMU ao crate
- `ROADMAP.md` / Memory Bank — agente principal no fim da etapa

## Dependências

- Gates existentes: `make verify-agent`, harness B / `verify-metal-infer` como **fontes** de evidência (não reimplementar motor).
- GGUF local se a fonte escolhida for corrida B com modelo; metal-infer pode bastar para ramo `metal_block` sem geração.
- QEMU/OVMF se a bridge invocar QEMU ao vivo; alternativa: log capturado por script do repo (documentar regeneração).

## Verificação

- Critérios de aceite da `spec.md`.
- Gate novo documentado em `AGENTS.md`.
- Regressão: `make verify-agent` (sem QEMU) + gates nativos relevantes não quebrados.
- Sem shell irrestrito; sem `METAL_OK` / tokens fingidos.
