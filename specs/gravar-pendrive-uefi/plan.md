# Plan — One-shot gravar pendrive UEFI (script + doc)

## Abordagem

Entregar a **Opção A** da spec em três fatias verticais:

1. **Script writer seguro** — `scripts/write-usb-esp.sh` com listagem de candidatos USB/removíveis, confirmação explícita (path ou `YES`+path), checks anti-sistema honestos, dry-run / `--help` / list-only, e caminho de gravação a partir de `build/ia-livre-esp.img` (fallback: gerar `.img` com mtools **ou** `cp` árvore `build/baremetal-esp/` para partição FAT já formatada).
2. **Docs + pontes** — atualizar `docs/boot-hardware-real.md` (one-shot substitui `dd` manual); ponte curta em `AGENTS.md`; avaliar `README.md` (`readme-por-fatia`).
3. **Gate sem USB** — `scripts/verify-write-usb.sh` (ou equivalente) + alvo Makefile: help + dry-run/list-only + exit ≠ 0 sem confirmação; **não** exige pendrive; documentar em AGENTS “Como verificar”.

Princípios:

- Reutilizar artefato E30 (`make baremetal-esp`); não reinventar ESP/kernel.
- **Nunca** gravar sem confirmação digitada; default seguro = abortar.
- Gate CI = prova do contrato de segurança do script, não hardware.
- Zero `METAL_OK` / Secure Boot assinatura / harness A vs B.

## Arquivos prováveis

- `scripts/write-usb-esp.sh` — writer one-shot (novo)
- `scripts/verify-write-usb.sh` — gate dry-run/help/recusa (novo)
- `Makefile` — alvos opcionais `write-usb` / `verify-write-usb` (nomes ajustáveis)
- `docs/boot-hardware-real.md` — seção “Gravar USB” → procedimento one-shot
- `AGENTS.md` — Como rodar / Como verificar / Estrutura
- `README.md` — só se a capa ficar enganosa sem menção (`readme-por-fatia`)

**Não tocar (salvo ponte documental explícita):**

- `kernel/`, `runtime/`, `runtime-native/`
- `scripts/make-baremetal-esp.sh` / `scripts/verify-baremetal.sh` (salvo chamada opcional “gere o artefato antes”)
- `scripts/run-harness-*.sh` / veredito comparable
- `node/`, `agent/`
- Evidência metal / `docs/evidence/boot-metal/` (não inventar log)

## Dependências

| Dependência | Uso |
|-------------|-----|
| E30 / `make baremetal-esp` | Árvore ESP + tar; `.img` se mtools |
| `lsblk` (ou equivalente) | Listar candidatos removíveis |
| `dd` / `cp` + mount FAT | Gravação real (só com confirmação) |
| `mtools` | Opcional — gerar `.img` se ausente |
| USB físico | Só uso manual do operador; **não** no gate CI |
| QEMU/OVMF | Irrelevante para esta etapa |

## Ordem das tasks

1. Script writer (list / confirm / refuse / dry-run / write paths).
2. Docs + pontes AGENTS/README.
3. Gate automatizado sem USB + fecho documental do gate em AGENTS.

## Verificação

- Gate novo: help + dry-run/list-only + recusa sem confirmação (exit ≠ 0).
- Regressão: `make verify-baremetal` (IMAGE_OK) permanece; `make verify` não quebrado por mudanças acidentais.
- Critérios de aceite da `spec.md` checáveis ao fim da Task 3.
- Hardware real / `METAL_OK`: **fora** — não é critério desta etapa.
