# Plan — Accel GPU simétrica A/B no harness

## Abordagem

1. **Contrato / ADR** — ADR 0023 (simetria GPU inviável até B60); atualizar `harness-perfis-a-otimizada-gpu.md` com perfil `sym_cpu` e distinção vs `A_gpu` assimétrico; ponte comparable + glossário se couber.
2. **Runner `sym_cpu` + alinhamento E56** — agregação A+B com `HARNESS_ACCEL=cpu` em ambos; ajustar verify/docs do caminho GPU para reason de assimetria explícita; **nunca** emitir ACCEL GPU em B.
3. **Gate + AGENTS** — target opt-in `sym_cpu` verificável; `verify-harness-gpu` com skip/anti-fraude; regressões; README avaliado.

## Arquivos prováveis

- `docs/adr/0023-simetria-gpu-harness-inviavel.md` (nome final na Task 1)
- `docs/harness-perfis-a-otimizada-gpu.md`
- `docs/harness-a-b-comparavel.md`
- `docs/glossario.md` (entrada `sym_cpu` / simetria accel, se couber)
- `scripts/run-harness-a-b-sym-cpu.sh` (ou nome fixado) — agregação simétrica CPU
- `scripts/verify-harness-sym-cpu.sh` + `Makefile` target (ou estágio documentado)
- `scripts/run-harness-a-b-gpu.sh` / `scripts/verify-harness-gpu.sh` — reason assimetria / anti-fraude B
- `AGENTS.md` — Como rodar / Como verificar
- `README.md` — avaliar (`readme-por-fatia`)

## Dependências

- E56: `verify-harness-gpu` + docs de perfil GPU (assimétrico)
- E22: instrumento comparável / veredito
- E44: B subset com tokens medidos
- ADR 0022: pilar 1 `BLOQUEIO_FINAL` (não reabrir)
- GGUF + QEMU para corridas A/B (mesmo harness atual)
- GPU host **não** obrigatória para `sym_cpu`; skip no caminho GPU

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

# Contrato
test -f docs/adr/0023-simetria-gpu-harness-inviavel.md   # ou nome fixado
test -f docs/harness-perfis-a-otimizada-gpu.md
grep -q 'sym_cpu' docs/harness-perfis-a-otimizada-gpu.md

# Perfil simétrico CPU
make verify-harness-sym-cpu   # nome fixado na Task 1

# Caminho GPU assimétrico: skip ou INCONCLUSIVO; sem ACCEL fingido em B
make verify-harness-gpu

# Regressões
make verify-harness
make verify-harness-comparable
```
