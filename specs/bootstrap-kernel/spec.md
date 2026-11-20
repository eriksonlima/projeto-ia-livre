# Spec — Bootstrap do kernel IA Livre

## Resultado visível

Existe um **kernel mínimo do IA Livre em Rust** (`#![no_std]`, freestanding) que **inicializa via UEFI em QEMU (x86-64)** e imprime uma **mensagem conhecida na saída serial**, verificável no host. O layout do crate/kernel está documentado; `AGENTS.md` (**Como rodar** / **Como verificar**) contém os comandos reais de build e gate. Não há guest Linux: o binário bootado é o próprio kernel do projeto.

## Contexto fixo (não reinventar)

- ADR 0001: kernel pequeno/auditável; inteligência (runtime, autonomia) **fora** do kernel; P2P independente do SO — [`docs/adr/0001-separacao-camadas-e-p2p.md`](../../docs/adr/0001-separacao-camadas-e-p2p.md).
- Arquitetura: bootstrap **x86-64 + UEFI + QEMU**, **CPU antes de GPU** — [`docs/architecture.md`](../../docs/architecture.md).
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Hardware de referência do autor (Acer Nitro 5): só como host de desenvolvimento; **execução alvo desta etapa = QEMU**, não bare metal no notebook.
- Etapas 5 (runtime) e 6 (P2P) permanecem fora desta spec.

## Decisão de stack (obrigatória nesta etapa)

**Abordagem única escolhida: `uefi-rs` + target `x86_64-unknown-uefi`.**

Justificativa (caminho mais simples e reproduzível para “hello serial”):

- Uma toolchain Cargo + OVMF + QEMU, sem bootloader externo (Limine) nem pipeline de imagem do crate `bootloader` rust-osdev.
- `#![no_std]` freestanding alinhado ao ADR (binário do projeto, não Linux guest).
- Serial via protocolo UEFI Serial I/O (ou stdout UEFI com QEMU `-serial stdio`), documentado e grepável.
- Suficiente para o Pronto quando da Etapa 4; `ExitBootServices`, UART bare-metal e MMU ficam para etapas posteriores.

Alternativas **não** adotadas nesta etapa: Limine; crate `bootloader` (rust-osdev). Podem ser reavaliadas depois se o handoff pós-UEFI exigir.

## Conteúdo obrigatório

### 1. Kernel mínimo (crate)

- Diretório canônico: `kernel/` (ou equivalente documentado no README/`AGENTS.md` se o nome divergir — preferir `kernel/`).
- Rust freestanding: `#![no_std]`, `#![no_main]` (ou equivalente UEFI), dependência `uefi` (uefi-rs).
- Mensagem serial **fixa e documentada** (ex.: `IA_LIVRE_BOOT_OK` ou string equivalente explícita na spec de verificação).
- Sem `std`; sem depender de SO guest.

### 2. Boot UEFI em QEMU x86-64

- Firmware OVMF (ou equivalente EDK2) para boot UEFI.
- QEMU `qemu-system-x86_64` com serial no host (`-serial stdio` ou equivalente documentado).
- Artefato bootável produzido por build documentado (ESP FAT, `*.efi`, etc. — detalhar no plan/AGENTS).

### 3. Build / run

- `Makefile` e/ou script(s) em `scripts/` com alvos claros (ex.: `build`, `run` / `qemu`).
- `.gitignore` cobre `target/` (e artefatos de imagem ESP se gerados fora de `target/`).
- Pré-requisitos de host listados em `AGENTS.md` (Rust com target UEFI, QEMU, OVMF).

### 4. `AGENTS.md`

- **Como rodar:** comandos reais para build + QEMU com serial.
- **Como verificar:** gate reproduzível que falha se a mensagem serial conhecida não aparecer (ex.: rodar QEMU com timeout e `grep` da string).
- Remover ou substituir o texto atual de “nesta etapa não há binário”.

### 5. Layout documentado

- Estrutura mínima do crate (ex.: `kernel/Cargo.toml`, `kernel/src/main.rs`, workspace root se houver) descrita em `AGENTS.md` → Estrutura ou parágrafo curto no README apontando para o kernel — sem inventar docs longos fora do necessário.

## Fora de escopo

- MMU completa, page tables avançadas, heap completo
- Filesystem, rede, GPU, drivers além do necessário ao boot/serial
- Scheduler, multiprocessamento, interrupções avançadas
- Runtime de LLM / inferência (Etapa 5)
- Nó ou protocolo P2P (Etapa 6)
- Bare metal no Acer Nitro 5 (QEMU basta)
- `ExitBootServices` e kernel pós-UEFI “puro” (pode ficar como nota; não é critério desta etapa)
- Autonomia, agentes, treinamento
- Guest Linux ou qualquer SO de propósito geral como ambiente de execução do “kernel”

## Critérios de aceite

- [ ] Existe crate/kernel Rust freestanding sob `kernel/` (ou path documentado) usando **uefi-rs** e target UEFI x86-64
- [ ] `make run` (ou comando equivalente documentado) inicia QEMU UEFI e a mensagem serial conhecida aparece no host
- [ ] Gate em `AGENTS.md` → **Como verificar** automatiza (ou documenta de forma executável) a checagem da mensagem serial e passa no ambiente de referência
- [ ] `AGENTS.md` → **Como rodar** lista pré-requisitos e comandos reais de build/run
- [ ] Layout do diretório do kernel está documentado; `.gitignore` inclui `target/`
- [ ] Nenhum guest Linux; nenhum código de runtime LLM ou P2P introduzido como entrega desta etapa
- [ ] Etapa 4 permanece alinhada ao roadmap; não marcar como `feita` nesta spec (só após gate + revisão)

## Riscos e rollback

- **Risco:** OVMF/paths diferem por distro → documentar pacotes comuns (`ovmf`, `qemu-system-x86`) e variável/caminho da firmware no `AGENTS.md`.
- **Risco:** target UEFI exige nightly ou componente `rust-src` → fixar no `AGENTS.md` a receita testada (stable com `x86_64-unknown-uefi` se disponível, senão nightly documentado).
- **Risco:** serial silenciosa (protocolo/dispositivo errado) → preferir Serial I/O UEFI + `-serial stdio`; mensagem única e grepável.
- **Risco:** escopo inchado (MMU, “kernel de verdade” pós-ExitBootServices) → rejeitar; Pronto quando = boot UEFI + hello serial.
- **Rollback:** remover `kernel/`, scripts e reverter `AGENTS.md`/`.gitignore`; etapa continua `em_andamento`.

## Etapa do roadmap

- Etapa 4 — Bootstrap do kernel IA Livre (`em_andamento`, Issue [#4](https://github.com/eriksonlima/projeto-ia-livre/issues/4))
- Spec: `specs/bootstrap-kernel/`
- Pronto quando (roadmap): boot UEFI em QEMU (x86-64), kernel mínimo em Rust com saída serial verificável; instruções em AGENTS.md.
