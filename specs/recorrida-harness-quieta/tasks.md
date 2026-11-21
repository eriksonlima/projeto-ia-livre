# Tasks — Re-corrida harness A vs B quieta

Uma task = uma fatia. Ordem: 1 → 2 → 3.

- [x] Task 1 — Protocolo de corrida quieta (doc)
  - **Feito:** `docs/harness-corrida-quieta.md` + ponte em `harness-a-b-comparavel.md`. README considerado na Task 1 (atualizado na Task 3).

- [x] Task 2 — Tooling mínimo opcional + re-corrida quieta registrada
  - **Feito:** preflight aviso (strict opcional); evidência na seção do doc (VERDICT=INCONCLUSIVO, A tok/s≈15.4, B sem TOKENS).

- [x] Task 3 — Gate sob protocolo quieto + pontes AGENTS/README
  - **Feito:** `make verify-harness-comparable` → GATE_OK + INCONCLUSIVO; AGENTS + README com ponte quieta.
