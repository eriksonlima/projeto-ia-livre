# Plan — GPU real no caminho nativo (além de `synthetic`)

## Abordagem

1. **Contrato primeiro** — fixar marcadores (`GPU_REAL_*` / `GPU_NEED_GPU`), tabela E25×E38×E41×E55 e política de skip em `docs/gpu-real-nativo.md`; pontes no doc E38.
2. **Path B (host)** — script/estágio que detecta GPU real no host, ancora no contrato nativo (log/fixture E38 ou referência documentada), emite `SRC=host` + placement mínimo + `GPU_REAL_OK`, ou skip `need_gpu`.
3. **Path A (opt-in)** — documentar (e só implementar se barato) probe PCI/pass-through no guest; não quebrar CI sem VFIO.
4. **Gate aditivo** — `make verify-gpu-native-real`; `make verify` permanece synthetic E38; anti-fraude contra synthetic-as-success.

## Arquivos prováveis

- `docs/gpu-real-nativo.md` (novo)
- `docs/gpu-manager-nativo.md` (ponte synthetic ≠ E55)
- `docs/gpu-manager-prototipo-host.md` / `docs/shard-multi-gpu-host.md` (ponte curta)
- `docs/adr/0006-…` ou ADR novo (só se Task 1 julgar necessário)
- `scripts/run-gpu-native-real.sh` (ou nome fixado) + `scripts/verify-gpu-native-real.sh`
- `Makefile` — target `verify-gpu-native-real`
- `AGENTS.md` — Como rodar / Como verificar
- `kernel/src/gpu_mgr.rs` — **só** se Task 2 implementar A (PCI); default E38 intocado
- `README.md` — avaliar (`readme-por-fatia`)

## Dependências

- E38 feita (`GPU_MGR=native` + synthetic + `verify-boot`)
- Host com `nvidia-smi` (ou equivalente) para ramo sucesso; CI sem GPU → skip
- Pass-through PCI / VFIO **não** obrigatório

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
# Contrato + pontes existem
test -f docs/gpu-real-nativo.md
# Gate novo: GPU real OK ou NEED_GPU
make verify-gpu-native-real
# Regressões
make verify                 # E38 synthetic
make verify-gpu-manager     # E25 stub
make verify-gpu-shard-host  # E41 (skip ok)
# Anti-fraude documental/greps: REAL_OK não aceita só synthetic
```
