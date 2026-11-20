# AGENTS.md

Brief do repositório para agentes. Em conflito com outros arquivos de ferramenta, este arquivo e `.cursor/rules/` vencem para o processo; `CLAUDE.md` apenas aponta para cá.

## Projeto

- Nome: `Projeto IA Livre`
- Resumo: Ecossistema open source brasileiro com SO próprio (IA Livre) especializado em IA nativa e rede P2P (Rede IA Livre) para colaboração computacional e de conhecimento. Participar da rede não exige o SO.
- Stack: Kernel mínimo em Rust (`uefi-rs`, target `x86_64-unknown-uefi`) + QEMU/OVMF; runtime e P2P nas etapas seguintes.

## Como rodar

### Pré-requisitos (host)

```bash
# Rust (se ainda não tiver)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. "$HOME/.cargo/env"
rustup target add x86_64-unknown-uefi

# QEMU + firmware UEFI (Ubuntu/Debian)
sudo apt install qemu-system-x86 ovmf
```

Opcional: `OVMF_CODE=/caminho/OVMF_CODE_4M.fd` se a firmware não estiver nos paths padrão.

### Build e QEMU

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
cd /caminho/para/projeto-ia-livre

make build   # gera target/x86_64-unknown-uefi/debug/ia-livre-kernel.efi
make run     # ESP em build/esp + QEMU UEFI, serial no stdio
```

Equivalente: `./scripts/run-qemu.sh`.

Na Task 1 (atual) a saída serial é o placeholder `IA Livre kernel scaffold`. A string canônica `IA_LIVRE_BOOT_OK` entra na Task 2.

## Como verificar

Gate parcial da Task 1 (scaffold + EFI):

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
test -f README.md && test -f AGENTS.md && test -f ROADMAP.md
test -d kernel && test -f kernel/Cargo.toml && test -f kernel/src/main.rs
test -f Makefile && test -f Cargo.toml
make build
test -f target/x86_64-unknown-uefi/debug/ia-livre-kernel.efi
grep -q 'em_andamento' ROADMAP.md
```

Gate completo da Etapa 4 (Task 2): QEMU com timeout e `grep IA_LIVRE_BOOT_OK` — a documentar na próxima fatia.

## PATH

Sempre inclua o GitHub CLI e o Cargo locais:

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
```

## Estrutura

- `ROADMAP.md` — etapas e status (fonte do próximo passo)
- `specs/` — Spec-Driven Development (spec → plan → tasks)
- `docs/` — produto, arquitetura e ADRs
- `memory-bank/` — contexto volátil entre chats (`activeContext.md`, `progress.md`)
- `.cursor/` — rules, agents, skills, commands, hooks
- `kernel/` — crate do kernel IA Livre (`Cargo.toml`, `src/main.rs`), target UEFI
- `Cargo.toml` — workspace Cargo (membro `kernel`)
- `Makefile` — `build` / `esp` / `run` / `clean`
- `scripts/run-qemu.sh` — atalho para `make run`
- `build/esp/` — ESP gerada (gitignored via `build/`)

## Fora de escopo do agente

- Commitar segredos, `.env` ou chaves
- Force push, `--no-verify`, alterar config do git
- Abrir PR sem evidência do gate
- Implementar fora da etapa `em_andamento` do roadmap

## Ponte

- Rules: `.cursor/rules/`
- Roadmap: `ROADMAP.md`
- Specs: `specs/`
- Product context: `docs/product-context.md`
- Memory Bank: `memory-bank/activeContext.md`
