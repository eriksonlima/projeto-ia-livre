# Plan — Kernel pós-Boot Services

## Abordagem

Três fatias verticais até o Pronto quando da Etapa 11. Entrega = **`ExitBootServices` + mapa owned + memória utilizável pós-exit** + **marcadores na serial do QEMU via UART COM1 bare-metal**. **Sem** inferência, **sem** MMU completa, **sem** Linha B.

### Desenho fixo (não reabrir A vs B na implementação)

**Dual-phase + UART COM1 (`0x3F8`):**

1. Sob Boot Services: fluxo Etapa 10 intacto → `IA_LIVRE_EXIT_BOOT_BEGIN` (UEFI Serial/ConOut).
2. Drop do protocolo Serial UEFI; `exit_boot_services(LOADER_DATA)`.
3. Pós-exit: iterar `MemoryMapOwned`; bump write/read no bloco já alocado; emitir `EXIT_MAP_*` / `EXIT_MEM_OK` / `EXIT_BOOT_OK` só pela UART COM1 (mesmo `-serial stdio` do gate).

### Task 1 — Contrato documental + marcadores canônicos

1. Criar `docs/kernel-pos-boot-services.md`: objetivo; decisão dual-phase + COM1; tabela pré/pós-exit; sequência; fora de escopo; como observar; aviso explícito “Serial UEFI inválida após exit”.
2. Ponte em `docs/kernel-alem-do-boot.md` (ExitBoot = Etapa 11) e mínima em `docs/architecture.md`.
3. Listar constantes/marcadores canônicos (pode só na doc nesta fatia).
4. `AGENTS.md`: menção parcial (doc + intenção `EXIT_BOOT_OK` / UART).
5. `readme-por-fatia`: avaliar; provavelmente cedo demais.

Critério parcial: qualquer implementador sabe a ordem, o I/O pós-exit e o que o gate vai exigir.

### Task 2 — `exit_boot_services` + UART COM1 + provas pós-exit no `kernel/`

1. Após `ALLOC_OK`: emitir `EXIT_BOOT_BEGIN`; fechar/dropar Serial UEFI.
2. Chamar `boot::exit_boot_services` (unsafe, uefi 0.33); obter mapa owned.
3. Contar Conventional (ou equivalente) no mapa pós-exit; emitir `EXIT_MAP_PAGES=` + `EXIT_MAP_OK` via COM1.
4. Reprovar bump no ponteiro `AllocatePages` da Etapa 10; emitir `EXIT_MEM_OK`.
5. Emitir `IA_LIVRE_EXIT_BOOT_OK` via COM1.
6. Em falha: não emitir `EXIT_BOOT_OK`; não usar APIs Boot Services após o exit.
7. Atualizar a doc com exemplo de serial (pré + pós) e detalhes mínimos do UART.
8. `AGENTS.md` → Como rodar menciona pós-Boot Services / marcadores novos.
9. `readme-por-fatia`: reavaliar.

Critério parcial: `make run` mostra `EXIT_BOOT_BEGIN` e `EXIT_BOOT_OK` (e preferencialmente `EXIT_MAP_OK` / `EXIT_MEM_OK`) na serial.

### Task 3 — Gate estendido + AGENTS completo

1. Estender `scripts/verify-boot.sh` para exigir marcadores Etapa 4/10 **e** `IA_LIVRE_EXIT_BOOT_OK` (e, se barato, `EXIT_MAP_OK` + `EXIT_MEM_OK`).
2. Manter `make verify`; timeout `VERIFY_TIMEOUT` (default 45s salvo ajuste documentado).
3. Completar `AGENTS.md` → Como verificar (Etapa 11 / gate do kernel).
4. Confirmar que outros gates não foram afetados.
5. `readme-por-fatia`: menção curta + ponte AGENTS só se a capa ficar enganosa.
6. Não marcar roadmap `feita` nesta task — agente principal após gate + revisor.

### Valores canônicos (orientação)

| Item | Valor |
|------|--------|
| Target | `x86_64-unknown-uefi` |
| uefi-rs | 0.33 (`exit_boot_services`) |
| Tipo do mapa/exit | `MemoryType::LOADER_DATA` |
| UART | COM1 base `0x3F8` (x86 I/O ports) |
| Marcador sucesso pós-exit | `IA_LIVRE_EXIT_BOOT_OK` |
| Make | `verify` (estendido) |
| Timeout | `VERIFY_TIMEOUT` default 45s |

### Notas de implementação (orientação, não código aqui)

- Não chamar `uefi::print!` / Serial protocol após o exit.
- Preservar o `NonNull` do `allocate_pages` em variável que sobreviva ao exit (não depender de Boot Services para “realocar”).
- UART: polling do LSR (bit THRE) antes de escrever; sem interrupções.
- Evitar novos crates; I/O ports com `core::arch::asm` ou intrinsic mínimo já aceitável no target UEFI.
- Não tocar `runtime/`, `node/`, `agent/`; não alterar harness Linha B.
- Manter greps/marcadores Etapa 4/10 compatíveis.

## Arquivos prováveis

- `docs/kernel-pos-boot-services.md` (Task 1; exemplo serial na Task 2)
- `docs/kernel-alem-do-boot.md` — ponte Etapa 11 (Task 1)
- `docs/architecture.md` — ponte mínima (Task 1)
- `kernel/src/main.rs` e, se couber, `kernel/src/uart.rs` (Task 2)
- `kernel/Cargo.toml` — só se feature uefi precisar ajuste (improvável)
- `scripts/verify-boot.sh`, `Makefile` — gate (Task 3)
- `AGENTS.md` — Como rodar / Como verificar / Estrutura
- `README.md` — só se `readme-por-fatia` exigir

Não editar como entrega: `runtime/**`, `node/**`, `agent/**`, scripts do harness, pesos em `models/`.

## Dependências

- Etapa 10 feita (mapa + alloc/bump + `make verify` com BOOT/MEM/ALLOC)
- Host: Rust target UEFI, QEMU, OVMF (iguais às Etapas 4/10)
- Sem GGUF, GPU, P2P ou agent para o gate desta etapa

## Verificação

1. Checklist de `spec.md` (critérios de aceite)
2. `make run` — serial com pré-exit + `EXIT_BOOT_OK` (COM1)
3. `make verify` — exige marcadores Etapa 10 + `EXIT_BOOT_OK` (e OK pós-exit auxiliares se incluídos)
4. Após gate verde da etapa: agente principal chama `revisor-de-fatia`, atualiza ROADMAP/Memory Bank (fora do papel do especificador)
