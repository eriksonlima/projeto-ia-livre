# Plan — Boot UEFI em hardware real (evidência serial) (Etapa 35)

## Abordagem

Completar a fronteira **metal** que a Etapa 30 deixou em checklist + skip, em três fatias:

1. **Contrato operacional** — expandir `docs/boot-hardware-real.md` (ou doc filho linkado) com checklist executável, procedimento de captura serial (ferramentas host, COM1 115200 8N1), formato do arquivo de evidência e anti-padrões (QEMU ≠ metal).
2. **Evidência + validação** — diretório `docs/evidence/boot-metal/` (com `.gitkeep` ou exemplo redigido honestamente como template); script auxiliar opcional `scripts/capture-baremetal-evidence.sh` (wrapper de documentação, não substitui máquina); extensão de `scripts/verify-baremetal.sh` para validar log quando `IA_LIVRE_BAREMETAL_SKIP=0`.
3. **Pontes e fecho** — `AGENTS.md`, Makefile se necessário (alvo documental), README (`readme-por-fatia`); primeira evidência real **ou** skip documentado na issue #34; critérios da spec checáveis.

Princípios:

- **Não** alterar o kernel só para metal nesta etapa (salvo bug bloqueante encontrado em campo — fora do happy path).
- Reutilizar `make baremetal-esp` / `IMAGE_OK` sem regressão.
- Evidência versionada é preferível a link externo frágil; se log contiver PII, redigir e documentar.
- Zero impacto em harness A vs B.

## Arquivos prováveis

- `docs/boot-hardware-real.md` — procedimento serial + formato evidência + tabela ambientes
- `docs/evidence/boot-metal/README.md` — como nomear/submeter logs
- `docs/evidence/boot-metal/.gitkeep` ou log de exemplo/template (sem fingir captura real)
- `scripts/verify-baremetal.sh` — ramo `SKIP=0` + validação de marcadores + anti-QEMU
- `scripts/capture-baremetal-evidence.sh` (opcional) — imprime instruções / cabeçalho SHA do EFI atual
- `Makefile` — comentário ou variável `IA_LIVRE_BAREMETAL_EVIDENCE` se útil
- `AGENTS.md` — Como verificar (metal vs QEMU vs artefato)
- `README.md` — só se a capa omitir a distinção QEMU/metal
- `docs/adr/0011-boot-imagem-esp-baremetal.md` — aditivo curto **se** a decisão de evidência precisar registro ADR (preferir doc principal)

**Não tocar (salvo ponte documental):**

- `kernel/src/main.rs` (sem requisito)
- `runtime/`, `runtime-native/`, harness scripts (veredito comparable)
- `scripts/make-baremetal-esp.sh` (salvo comentário cruzado)

## Dependências

| Dependência | Uso |
|-------------|-----|
| Etapa 30 feita | Artefato + `verify-baremetal` base |
| ADR 0011 | QEMU ≠ metal; skip honesto |
| PC UEFI + USB + opcional USB-UART | Captura real (opcional para fechar com skip) |
| `minicom` / `picocom` / equivalente | Doc do host operador |
| `make build` + `make baremetal-esp` | SHA do EFI referenciado no log |

## Ordem das tasks

1. Doc + formato de evidência + template de diretório.
2. Gate: validação de evidência vs skip; marcadores `METAL_OK` ou `SKIP`.
3. AGENTS + evidência real na issue/repo ou fecho com skip + README.

## Verificação

- `make verify-baremetal` com default `IA_LIVRE_BAREMETAL_SKIP=1` → verde (regressão E30).
- Com evidência válida de teste (fixture no repo ou log capturado): `IA_LIVRE_BAREMETAL_SKIP=0 IA_LIVRE_BAREMETAL_EVIDENCE=… make verify-baremetal` → `METAL_OK` (ou marcador equivalente documentado).
- Com evidência inválida (sem `BOOT_OK` ou com "qemu") → gate falha no ramo metal.
- `make verify` (QEMU) permanece verde.
- Critérios de aceite da `spec.md` ao fim da Task 3.