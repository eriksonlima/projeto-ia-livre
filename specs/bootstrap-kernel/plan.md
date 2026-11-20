# Plan — Bootstrap do kernel IA Livre

## Abordagem

Duas fatias verticais até o Pronto quando da Etapa 4. Stack fixa: **uefi-rs** + `x86_64-unknown-uefi` + QEMU/OVMF + serial no host.

### Task 1 — Scaffold freestanding + build/run documentado

1. Criar workspace ou crate em `kernel/` com `#![no_std]` / entry UEFI via uefi-rs.
2. Adicionar target UEFI ao fluxo de build (`rustup target add x86_64-unknown-uefi` documentado).
3. Produzir artefato `.efi` e empacotar ESP mínima (diretório FAT com `EFI/BOOT/BOOTX64.EFI` ou path documentado).
4. `Makefile` e/ou `scripts/` com `build` e `run` (QEMU + OVMF + drive ESP + `-serial stdio`).
5. `.gitignore`: `target/` e artefatos gerados da ESP se aplicável.
6. Atualizar `AGENTS.md` com pré-requisitos e **Como rodar** (mesmo que a mensagem serial ainda seja placeholder).
7. Documentar layout (`kernel/Cargo.toml`, `kernel/src/...`) em `AGENTS.md` → Estrutura.

Critério parcial: `make build` (ou equivalente) gera o EFI; `make run` sobe QEMU sem exigir ainda o grep da mensagem final (pode imprimir qualquer saída estável).

### Task 2 — Hello serial verificável + gate

1. No entry UEFI, abrir protocolo Serial (ou stdout redirecionado) e escrever mensagem **fixa**, ex.: `IA_LIVRE_BOOT_OK` (uma linha, ASCII).
2. Garantir que QEMU exponha essa saída em `-serial stdio` (ou equivalente já documentado na Task 1).
3. Substituir **Como verificar** em `AGENTS.md` por gate que:
   - constrói o kernel;
   - executa QEMU com timeout curto;
   - confirma a presença de `IA_LIVRE_BOOT_OK` na saída;
   - encerra QEMU de forma não interativa.
4. Confirmar que o gate passa no host de referência (Ubuntu + QEMU + OVMF).
5. Não avançar roadmap para `feita` nesta task — só cumprir critérios; marcação `feita` fica para o agente principal após gate + revisor.

### Mensagem canônica

```
IA_LIVRE_BOOT_OK
```

Usar exatamente essa string no código e no `grep` do gate (salvo nota explícita se encoding/newline exigir ajuste documentado).

### Notas de implementação (orientação, não código aqui)

- Preferir API uefi-rs estável documentada no crate; panic handler mínimo (`loop {}` ou `uefi` helpers).
- OVMF: aceitar path via variável (`OVMF_PATH` / `OVMF_CODE`) com default comum da distro.
- Timeout do gate: o suficiente para boot UEFI em CI/local lento (ex.: 10–30s), sem hang infinito.
- Não introduzir Limine nem crate `bootloader` nesta etapa.

## Arquivos prováveis

- `kernel/Cargo.toml`, `kernel/src/main.rs` (e módulos mínimos se necessário)
- `Cargo.toml` (workspace na raiz, se adotado)
- `Makefile` e/ou `scripts/run-qemu.sh`, `scripts/build.sh`
- `.gitignore` — `target/`, possivelmente `esp/` ou `build/`
- `AGENTS.md` — Como rodar / Como verificar / Estrutura
- Opcional: `rust-toolchain.toml` se nightly for inevitável (só se stable não bastar; justificar no AGENTS)

Não editar: manifesto, ADR 0001 (salvo link), código de runtime/P2P, etapas 5–6.

Opcional mínimo: uma linha em `docs/architecture.md` na tabela “Fronteira” atualizando Etapa 4 de “Código começa aqui” para refletir bootstrap em andamento/feito — **não** é critério de aceite; só se couber na mesma fatia sem escopo extra.

## Dependências

- Etapas 1–3 feitas (scaffold, manifesto, architecture + ADR 0001)
- Host: Rust, QEMU system x86_64, firmware OVMF
- Sem dependência de GPU, rede ou modelos

## Verificação

1. Checklist de `spec.md` (critérios de aceite)
2. Gate de `AGENTS.md` → **Como verificar** (deve incluir a string `IA_LIVRE_BOOT_OK`)
3. Confirmar ausência de guest Linux e de escopo Etapa 5/6 no diff
4. Após gate verde: agente principal chama `revisor-de-fatia`, atualiza ROADMAP/Memory Bank (fora do papel do especificador)
