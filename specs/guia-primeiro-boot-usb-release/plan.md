# Plan — Guia “primeiro boot USB” + release de artefato (Etapa 57)

## Abordagem

1. **Guia (Task 1)** — Criar `docs/guia-primeiro-boot-usb.md` (nome canônico sugerido) com fluxo linear para contribuidores: obter artefato → gravar USB → firmware/Secure Boot → serial → expectativa de marcadores → limites honestos (QEMU≠metal, gravação≠`METAL_OK`, hipótese INCONCLUSIVO). Pontes para `boot-hardware-real.md`, writer E47, evidência E35/E46. Atualizar `boot-hardware-real.md` com link “Primeiro boot” no topo; avaliar README/AGENTS (ponte curta).

2. **Release + checksums (Task 2)** — Script `scripts/prepare-baremetal-release.sh` (nome ajustável): invoca/assume `make baremetal-esp`, copia tar (e `.img` se existir) para `build/release/` (ou staging documentado), gera `SHA256SUMS` (EFI + tar [+ img]), imprime instruções de tag/`gh release create`. Documentar no guia + seção curta em `boot-hardware-real.md` / AGENTS. **Não** anexa GGUF full por default.

3. **Gate + fechamento (Task 3)** — `scripts/verify-boot-guide-release.sh` + `make verify-boot-guide-release` (nomes ajustáveis): exige guia no tree; roda prepare (ou valida staging) e confere checksums batem com arquivos; emite marcador(es) `IA_LIVRE_BOOT_GUIDE_OK` / `IA_LIVRE_RELEASE_ARTIFACT_OK`. Sem USB. Atualizar AGENTS “Como verificar”; README se capa omitir onboarding USB.

Reutilizar artefato E30 e writer E47; sem tocar kernel/harness.

## Arquivos prováveis

- `docs/guia-primeiro-boot-usb.md` (novo)
- `docs/boot-hardware-real.md` (ponte)
- `scripts/prepare-baremetal-release.sh` (novo)
- `scripts/verify-boot-guide-release.sh` (novo)
- `Makefile` (alvos)
- `AGENTS.md` (Como rodar / verificar)
- `README.md` (só se capa enganosa — `readme-por-fatia`)
- Opcional: `CHANGELOG.md` Unreleased (menção release); **não** obrigatório se AGENTS cobrir

Não editar (salvo nota): `kernel/`, `runtime/`, harness comparable, ADR 0011 (preservado; aditivo só se processo de release exigir — preferir doc).

## Dependências

- Rust/Cargo + QEMU **não** obrigatórios para o gate desta etapa (prepare pode chamar `baremetal-esp` → aí precisa build EFI; gate pode: (a) exigir EFI já buildado, ou (b) chamar `make baremetal-esp` como `verify-baremetal` — alinhar à impl.; default sugerido = chamar prepare que chama baremetal-esp, timeout razoável).
- Sem USB/PC no CI.
- `gh` autenticado **só** para publicar Release real (operador); gate **não** exige `gh release`.

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
test -f docs/guia-primeiro-boot-usb.md
# prepare + checksums (via gate):
make verify-boot-guide-release   # nome final na Task 3
# regressão artefato/writer:
make verify-baremetal
make verify-write-usb
```

Critérios: guia presente; SHA256SUMS consistente; marcadores de gate; texto sem “hipótese comprovada”; sem USB.
