# Plan — Boot/imagem IA Livre em hardware real (USB/ESP)

## Abordagem

Entregar a **Opção A** da spec em três fatias verticais:

1. **Contrato + artefato** — ADR 0011 + doc `docs/boot-hardware-real.md` + script/`make` que monta imagem/ESP FAT com `EFI/BOOT/BOOTX64.EFI` a partir do build UEFI existente.
2. **Gate de imagem** — `scripts/verify-baremetal.sh` (nome ajustável) + alvo Makefile; valida estrutura/EFI/checksum no host; emite `IA_LIVRE_BAREMETAL_IMAGE_OK`; **não** boot QEMU-as-metal e **não** exige USB física.
3. **Procedimento manual + pontes** — checklist hardware real, política `IA_LIVRE_BAREMETAL_SKIP`, atualizar `AGENTS.md` / `architecture.md`; README avaliados; fecho documental da etapa.

Princípios:

- Reutilizar `make build` / `make esp` / `ia-livre-kernel.efi` — não reinventar o kernel.
- Gate CI = prova do **artefato**; prova em metal = manual ou skip honesto.
- Zero alteração de harness A vs B / motor / `TOKENS_PER_S`.
- Preferir ferramentas host comuns (`mkfs.vfat`, `mtools`, `dd` documentado) sem dependência de GPU.

## Arquivos prováveis

- `docs/boot-hardware-real.md` — contrato (novo)
- `docs/adr/0011-boot-hardware-real-imagem-esp.md` — ADR da decisão A (novo)
- `scripts/build-baremetal-image.sh` (ou nome equivalente) — monta imagem/ESP
- `scripts/verify-baremetal.sh` — gate do artefato (+ skip de hardware)
- `Makefile` — alvos `baremetal-image` / `verify-baremetal` (nomes ajustáveis)
- `AGENTS.md` — Como rodar / Como verificar / Estrutura
- `docs/architecture.md` — ponte “boot QEMU ≠ bare-metal; imagem verificável”
- `README.md` — só se a capa ficar enganosa sem menção (`readme-por-fatia`)
- Possível reuso: saída de `make esp` (`build/esp/…`) como input do empacotador

**Não tocar (salvo ponte documental explícita):**

- `kernel/src/main.rs` (sem mudança obrigatória de path BlockIO)
- `runtime/`, `runtime-native/` (motor)
- `scripts/run-harness-*.sh` / veredito comparable (exceto se doc cruzado mínimo)
- `node/`, `agent/`

## Dependências

| Dependência | Uso |
|-------------|-----|
| Rust + target `x86_64-unknown-uefi` | Produzir `.efi` |
| `make build` / `make esp` | ESP de referência |
| Ferramentas FAT no host (`dosfstools` / `mtools` ou equivalente documentado) | Montar imagem |
| QEMU/OVMF | **Não** são prova bare-metal; gates QEMU existentes não substituem esta etapa |
| PC UEFI + USB (+ opcional USB-UART) | Só para checklist manual; opcional para fechar a etapa |

## Ordem das tasks

1. Doc + ADR + script de imagem (artefato existe e é descritível).
2. Gate automatizado do artefato (CI-friendly).
3. Procedimento manual + skip + pontes AGENTS/architecture + fecho.

## Verificação

- Gate novo da etapa (artefato): conforme Task 2 / `AGENTS.md` após pontes.
- Regressão: `make verify` (kernel QEMU) permanece verde; harness **não** precisa passar para fechar E30, mas **não** deve ser quebrado por mudanças acidentais.
- Hardware: checklist manual **ou** `IA_LIVRE_BAREMETAL_SKIP` documentado — nunca fingir metal.
- Critérios de aceite da `spec.md` checáveis ao fim da Task 3.
