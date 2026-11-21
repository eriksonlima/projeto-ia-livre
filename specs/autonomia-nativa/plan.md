# Plan — Autonomia consumindo runtime/evidência nativa

## Abordagem

Fechar B65/E70 no **host**: autonomia **usa** evidência já validada pela bridge E49 — sem agente no guest e sem enfraquecer ADR 0001.

1. **Contrato + decisão A (Task 1)** — Doc de consumo (`docs/autonomia-nativa.md` **ou** seção em `autonomia-bridge-nativo.md`): diferença E49 (validar) vs E70 (consumir); marcadores `IA_LIVRE_NATIVE_CONSUME_*`; mecanismo mínimo de injeção (memória / `--prompt` / tool allowlist); nome do runner e do `make` target; critérios de pivot B. Pontes ADR 0001 / 0018. **Sem** gate novo ainda (esqueleto opcional).
2. **Consumidor host (Task 2)** — `scripts/run-autonomia-nativa.sh` (ou nome fixado) + extensão mínima de `agent/` **só se** necessária: obter `BRIDGE_OK` → injetar SRC/resumo → one-shot/autonomia → emitir `NATIVE_CONSUME_*`. Prova de uso ≠ eco de bridge. **Proibido** shell irrestrito / `TOKENS_PER_S` inventado / agente no kernel.
3. **Gate + pontes (Task 3)** — `scripts/verify-autonomia-nativa.sh` + `Makefile`; `AGENTS.md`; README avaliado; regressão `verify-agent` (sem QEMU) + `verify-autonomia-bridge`.

Ordem: 1 → 2 → 3. Se Task 1 pivota B: Task 2 = contrato/ADR «bridge = máximo até X» + marcador de teto; Task 3 = gate que prova o contrato (sem `NATIVE_CONSUME_OK` falso).

## Arquivos prováveis

- `docs/autonomia-nativa.md` (novo) **ou** extensão de `docs/autonomia-bridge-nativo.md`
- Pontes: `docs/desenho-autonomia-v1.md` / `docs/autonomia-alem-v1.md` (curtas); ADR 0018 (ponte, sem reescrever decisão E49)
- `docs/adr/00XX-….md` (**só** se pivot B)
- `scripts/run-autonomia-nativa.sh` (runner A)
- `agent/src/main.rs` (opcional — flag/entrada de evidência nativa; allowlist intacta)
- `scripts/verify-autonomia-nativa.sh`, `Makefile` (`verify-autonomia-nativa`)
- `AGENTS.md`; opcionalmente `README.md`
- Fixture/log: reusar evidência E49 (`docs/evidence/bridge/…` ou equivalente) — **sem** exigir QEMU no default do gate
- **Intocados salvo ponte:** `scripts/run-autonomia-bridge.sh` (semântica E49), `scripts/verify-agent.sh`, `kernel/`, harness comparable

## Dependências

- E49 feita — `BRIDGE_*` + `verify-autonomia-bridge`.
- `agent/` E7/E24/E40 — one-shot/allowlist; GGUF **só** se o mecanismo de consumo exigir inferência (preferir path que prove uso via memória/tool mesmo quando runtime for necessário no one-shot completo).
- QEMU **não** obrigatório no default do gate E70 (fixture/log).
- PC físico / `METAL_OK` / espécie canônica / `COMPROVA` — **fora**.

## Verificação

- **A — sucesso:** runner emite `NATIVE_CONSUME_OK` + `SRC=` coerente + evidência de uso da fonte nativa (além de `BRIDGE_OK`).
- **Gate:** `make verify-autonomia-nativa` exit 0 no host de referência (fixture/log).
- **Regressão ADR 0001:** `make verify-agent` **sem** QEMU/UEFI; não passa a exigir bridge/nativo.
- **Regressão E49:** `make verify-autonomia-bridge` intacto.
- **Negativo:** falha se só ecoar `BRIDGE_OK` sem consumo; falha se `SRC` for host-llama/`INFER_OK` sem bridge; ausência de `TOKENS_PER_S`/`METAL_OK`/`COMPROVA` inventados.
- **Se B:** gate exige contrato/ADR + marcador de teto; sem `NATIVE_CONSUME_OK` de sucesso.
- Checklist `AGENTS.md` → Como verificar (Task 3).
