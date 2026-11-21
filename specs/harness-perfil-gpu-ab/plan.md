# Plan — Perfil harness GPU espelhado A/B (quando B gerar)

## Abordagem

1. **Contrato / docs** — atualizar E18: perfil `A_gpu` (nome fixado) executável; definir espelho B como assimétrico (tokens subset + `ACCEL=cpu`); ponte comparable → `INCONCLUSIVO`; marcadores e política de skip.
2. **Runner A GPU + agregação** — script(s) que constroem runtime com feature GPU, rodam carga canônica com `--n-gpu-layers` > 0, emitem `HARNESS_*` + `ACCEL≠cpu`; incluem B (subset existente) **sem** inventar métricas; skip se sem GPU.
3. **Gate opt-in** — `make verify-harness-gpu` + `AGENTS.md`; anti-fraude (sem COMPROVA/REFUTA indevido; sem ACCEL GPU em B); regressão dos gates harness existentes.

## Arquivos prováveis

- `docs/harness-perfis-a-otimizada-gpu.md` — promover GPU de “roadmap” → executável A + espelho B honesto
- `docs/harness-a-b-comparavel.md` — ponte perfil GPU / assimetria → `INCONCLUSIVO`
- `docs/harness-linha-a-b.md` e/ou `docs/runtime-nativo-linha-b.md` — ponte curta se necessário
- `scripts/run-harness-line-a-gpu.sh` (ou nome fixado) — A com accel
- `scripts/run-harness-a-b-gpu.sh` (ou estágio no comparable com perfil) — agregação A/B
- `scripts/verify-harness-gpu.sh` + `Makefile` target
- `AGENTS.md` — Como rodar / Como verificar
- `README.md` — avaliar (`readme-por-fatia`)
- Opcional: extensão mínima de `run-harness-a-b-comparable.sh` se o veredito GPU for opt-in via env (sem mudar default)

## Dependências

- E44: B com `TOKENS_PER_S` subset (já existe)
- E8: feature `cuda`/`vulkan` + detecção GPU host
- E18: metodologia base
- GGUF canônico para A (`./scripts/fetch-model.sh`)
- QEMU/OVMF para B (mesmo harness B atual)
- GPU host **não** obrigatória (skip)

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

# Docs / contrato
test -f docs/harness-perfis-a-otimizada-gpu.md

# Gate opt-in: A GPU + B honesto, ou skip
make verify-harness-gpu

# Regressões (default intocado)
make verify-harness
make verify-harness-comparable
make verify-harness-a-otimizada   # se aplicável no host
```
