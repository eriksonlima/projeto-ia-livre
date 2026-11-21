# Plan — GPU real no guest (PCI/pass-through)

## Abordagem

1. **Contrato primeiro** — documentar VFIO/IOMMU/QEMU pass-through, âncora de evidência mínima, marcadores (`SRC=pci_passthrough`, `REAL_OK`, skip `need_gpu`/`need_vfio`) e fronteira E38 × E55 × E65; ponte ADR 0023.
2. **Runner/estágio** — detectar pré-requisitos; emitir `pci_passthrough` + `REAL_OK` só com evidência real; senão skip honesto (exit 0). Não inventar device; não contar `SRC=host` como sucesso E65.
3. **Gate aditivo** — estender `verify-gpu-native-real` **ou** target novo (Task 1 decide); anti-fraude; regressões E38/E55; `AGENTS.md` + README (`readme-por-fatia`).

## Arquivos prováveis

- `docs/gpu-guest-passthrough.md` (novo) **e/ou** extensão de `docs/gpu-real-nativo.md`
- `docs/gpu-manager-nativo.md` (ponte synthetic ≠ passthrough)
- `docs/adr/0023-simetria-gpu-harness-inviavel.md` (ponte: pré-requisito B60/E65)
- `docs/adr/0006-…` ou ADR novo (só se Task 1 julgar necessário)
- `scripts/run-gpu-native-real.sh` / novo `scripts/run-gpu-guest-passthrough.sh` (nome na Task 1)
- `scripts/verify-gpu-native-real.sh` e/ou `scripts/verify-gpu-guest-passthrough.sh`
- `Makefile` — target do gate E65
- `AGENTS.md` — Como rodar / Como verificar
- `kernel/src/gpu_mgr.rs` — **só** se probe PCI guest for barato e não quebrar CI/E38
- `README.md` — avaliar (`readme-por-fatia`)
- `docs/glossario.md` — se termo `pci_passthrough` / `need_vfio` precisar entrada

## Dependências

- E38 feita (synthetic + `GPU_MGR=native`)
- E55 feita (`GPU_REAL_*` + `verify-gpu-native-real` + path `host`)
- ADR 0023 aceita (simetria GPU até passthrough)
- VFIO/GPU dedicada **não** obrigatórios no CI — skip honesto

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
# Contrato + pontes
test -f docs/gpu-real-nativo.md
# Gate E65 (nome fixado na Task 1): pci_passthrough+REAL_OK OU skip need_gpu/need_vfio
# make verify-gpu-guest-passthrough   # ou estágio documentado em verify-gpu-native-real
# Regressões
make verify                  # E38 synthetic
make verify-gpu-native-real  # E55 host ou skip
# Anti-fraude: REAL_OK+pci_passthrough exige evidência; host-only ≠ sucesso E65
```
