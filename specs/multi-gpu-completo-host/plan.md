# Plan — Multi-GPU completo além do shard host

## Abordagem

Fechar «multi-GPU completo» no **host** como **placement/execução além do shard E41**, sem inferência multi-GPU fingida.

1. **Contrato + decisão A (Task 1)** — `docs/multi-gpu-completo-host.md`: o que é «além de E41» (dual Weights+Kv e/ou N-device); identidade `host_multi` (ou nome fixado); marcadores `GPU_MULTI_*`; política de skip `need_2_devices`; anti-fraude. Pontes no desenho/E41. Confirmar que A **não** exige llama multi-GPU full; se exigir → pivot B (ADR 0025) e reescrever o restante do plano para gate de inviabilidade. **Sem** gate novo ainda (esqueleto opcional).
2. **Executor (Task 2)** — Entrypoint host (`scripts/run-gpu-multi-host.sh` ou extensão documentada): detecta N; se N≥2, emite plano dual/N-device + por device `MULTI_DEVICE`/`MULTI_PLACE` + query mínima; se N&lt;2, só `MULTI_SKIP`. **Não** emitir `TOKENS_PER_S`. Não alterar semântica de `run-gpu-shard-host.sh` (E41).
3. **Gate + pontes (Task 3)** — `scripts/verify-gpu-multi.sh` + `make verify-gpu-multi`; `AGENTS.md`; README avaliado; regressão E41/E25/E8.

Ordem: 1 → 2 → 3. Se Task 1 pivota B: Task 2 = ADR 0025 + marcador de bloqueio; Task 3 = gate que prova ADR/skip (sem `MULTI_EXEC_OK` falso).

## Arquivos prováveis

- `docs/multi-gpu-completo-host.md` (novo)
- `docs/desenho-gpu-manager-multi-gpu.md`, `docs/shard-multi-gpu-host.md` (pontes)
- `docs/adr/0025-….md` (**só** se pivot B)
- `scripts/run-gpu-multi-host.sh` (ou nome fixado) — executor A
- `scripts/verify-gpu-multi.sh`, `Makefile` (`verify-gpu-multi`)
- `AGENTS.md`; opcionalmente `README.md`, `docs/architecture.md` (lacuna)
- **Intocados salvo ponte:** `scripts/run-gpu-shard-host.sh`, `scripts/verify-gpu-shard-host.sh`, `scripts/gpu-manager-stub.sh`, `kernel/`

## Dependências

- E41 feita — baseline shard + skip.
- E8 — política GPU skip single-device; não regressir.
- Hardware ≥2 GPUs **somente** para `MULTI_EXEC_OK`; host 1×1050 / CI → skip.
- GGUF **não** obrigatório; llama multi-GPU full **fora** (senão B).

## Verificação

- **Skip path:** `VERIFY_GPU_MULTI_SKIP=1 make verify-gpu-multi` → `MULTI_SKIP`, exit 0.
- **Host 1 GPU:** `need_2_devices` (ou equiv.), exit 0; **ausência** de `MULTI_EXEC_OK`.
- **Host ≥2 GPUs (A):** plano dual/N-device + `MULTI_EXEC_OK` + ≥2 evidências de device/place.
- **Regressão:** `make verify-gpu-shard-host`, `make verify-gpu-manager`, `make verify-runtime-gpu` (skips canônicos ok).
- **Negativo:** sem exigir `TOKENS_PER_S`; sem `GPU_MGR=native` no executor; falha se `MULTI_EXEC_OK` com 1 device.
- **Se B:** gate exige ADR 0025 + bloqueio/skip honesto; sem `MULTI_EXEC_OK` de sucesso.
- Checklist `AGENTS.md` → Como verificar (Task 3).
