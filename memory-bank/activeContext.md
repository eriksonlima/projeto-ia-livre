# Active context

## Foco atual

- Etapas 43–44 **feitas** (Prefill subset + Decode/`TOKENS_PER_S` subset)
- Hipótese A vs B: ainda **INCONCLUSIVO** (espécie B ≠ A plena)
- Próximo backlog: **B39** (re-corrida comparável com geração “limpa”) — pode exigir Prefill 22L / n_predict=32

## Mudanças recentes

- E43: ADR 0014, KV + Prefill 2×2 guest
- E44: ADR 0015, Decode greedy, `LOAD_KIND=gguf`, release UEFI, comparable subset INCONCLUSIVO

## Próximo passo

- Promover B39 ou B40 conforme ordem sensata (hipótese vs USB)
- Lease liberar após push E44

## Notas

- README capa: sem mudança necessária (AGENTS cobre)
