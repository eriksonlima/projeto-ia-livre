# Spec — Kernel pós-Boot Services

## Resultado visível

No **UEFI/QEMU (x86-64)**, o kernel IA Livre (`kernel/`) passa a **sair de Boot Services** (`ExitBootServices` via uefi-rs) com **base estável**:

1. **Mapa de memória preservado** após o exit (`MemoryMapOwned` retornado pela API).
2. **Memória utilizável** comprovada (bloco `LOADER_DATA` da Etapa 10 / bump write/read **depois** do exit).
3. **Gate serial** que exige marcador(es) **pós-exit** capturáveis no mesmo `make verify` / QEMU `-serial stdio` — sem regressão dos marcadores Etapa 4/10 emitidos ainda sob Boot Services.

Documentação curta descreve o contrato, a estratégia de I/O pós-exit e os limites. **Ainda sem inferência no kernel**, sem llama.cpp no UEFI, sem runtime Linha B, sem MMU completa.

## Contexto fixo (não reinventar)

- ADR 0001: kernel pequeno/auditável; inteligência **fora** do kernel — [`docs/adr/0001-separacao-camadas-e-p2p.md`](../../docs/adr/0001-separacao-camadas-e-p2p.md).
- Arquitetura (camada 1): handoff pós-UEFI é evolução natural após Etapa 10 — [`docs/architecture.md`](../../docs/architecture.md).
- Etapa 10 (`specs/kernel-alem-do-boot/`): mapa + `AllocatePages` + bump **sob Boot Services**; marcadores `BOOT_OK` / `MEM_MAP_OK` / `ALLOC_OK`; `ExitBootServices` ficou **fora**.
- Stack: `uefi` **0.33** + target `x86_64-unknown-uefi`; API `unsafe fn boot::exit_boot_services(MemoryType) -> MemoryMapOwned`.
- Gate atual: `make verify` / `scripts/verify-boot.sh` (timeout `VERIFY_TIMEOUT`, default 45s).
- Runtime Linha B / harness B real = backlog **B5** (fora).
- Rule `readme-por-fatia`: avaliar `README.md` por fatia; só atualizar se a home do GitHub ficar enganosa.

## Decisão de desenho (obrigatória — uma escolha)

| Peça | Escolha nesta etapa |
|------|---------------------|
| Ambiente | Continuar QEMU/OVMF x86-64; `-serial stdio` como captura do gate |
| Saída de Boot Services | Chamar `boot::exit_boot_services(MemoryType::LOADER_DATA)` (uefi 0.33) **depois** dos marcadores Etapa 10 |
| Mapa pós-exit | Usar o `MemoryMapOwned` retornado; iterar/contar Conventional (ou equivalente documentado) **após** o exit |
| Memória utilizável | Manter o bloco `AllocatePages` (`LOADER_DATA`, Etapa 10) e **reprovar** bump write/read **depois** do exit |
| I/O pós-exit | **UART 16550 bare-metal em COM1 (`0x3F8`)** — escrita direta de bytes ASCII; **não** usar Serial I/O UEFI / ConOut após o exit |
| Prova no gate | Marcadores pós-exit aparecem na **mesma** serial do QEMU que o `verify-boot.sh` já captura |
| Inferência / GGUF | **Proibido** no kernel |
| MMU / identity map / heap geral | **Fora** (identity map implícito do loader UEFI basta para esta prova) |

### Por que dual-phase + UART COM1 (e não só “emitir antes do exit”)

1. **Pré-exit (Boot Services):** emitir `IA_LIVRE_BOOT_OK`, mapa/alloc Etapa 10, e `IA_LIVRE_EXIT_BOOT_BEGIN` pelo caminho UEFI Serial/ConOut já existente — prova regressão e intenção de sair.
2. **Exit:** `exit_boot_services` — Boot Services e protocolos UEFI de console/serial **deixam de ser válidos**.
3. **Pós-exit:** com o mapa owned + bump no bloco preservado, emitir via **COM1**:
   - evidência do mapa (`IA_LIVRE_EXIT_MAP_PAGES=` + `IA_LIVRE_EXIT_MAP_OK`);
   - evidência de memória (`IA_LIVRE_EXIT_MEM_OK`);
   - sucesso canônico `IA_LIVRE_EXIT_BOOT_OK`.

**Rejeitado:** emitir `EXIT_BOOT_OK` só *antes* do exit (não prova sobrevivência).  
**Rejeitado:** depender de Serial I/O UEFI após o exit (UB / silêncio no QEMU).  
**Rejeitado:** dual-phase só com “escrever em memória e torcer” sem marcador pós-exit na serial do host (gate não fica verificável).

No QEMU com `-serial stdio`, a UART ISA COM1 é o caminho que o host já lê; a mesma captura do gate serve para pré e pós-exit.

### Marcadores serial (canônicos)

**Pré-exit** (caminho UEFI; regressão Etapa 4/10 — **permanecem**):

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_BOOT_OK` | Boot UEFI ok |
| `IA_LIVRE_MEM_CONVENTIONAL_PAGES=` / `MEM_MAP_OK` | Mapa sob Boot Services |
| `IA_LIVRE_ALLOC_BYTES=` / `ALLOC_OK` | Alloc + bump sob Boot Services |
| `IA_LIVRE_EXIT_BOOT_BEGIN` | Última linha UEFI antes de chamar `exit_boot_services` |

**Pós-exit** (somente UART COM1 bare-metal):

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_EXIT_MAP_PAGES=<n>` | Páginas Conventional (ou equivalente documentado) no mapa **owned** pós-exit |
| `IA_LIVRE_EXIT_MAP_OK` | Mapa pós-exit iterado com sucesso |
| `IA_LIVRE_EXIT_MEM_OK` | Bump write/read no bloco pré-alocado **após** o exit |
| `IA_LIVRE_EXIT_BOOT_OK` | ExitBoot + base estável concluídos |

Ordem sugerida: marcadores Etapa 10 → `EXIT_BOOT_BEGIN` → (exit) → `EXIT_MAP_PAGES=` → `EXIT_MAP_OK` → `EXIT_MEM_OK` → `EXIT_BOOT_OK`.

Em falha (exit, mapa ou mem): **não** emitir `IA_LIVRE_EXIT_BOOT_OK` (gate vermelho). Panic pós-exit: evitar dependência de logger UEFI; hang silencioso ou mensagem UART mínima — documentar.

## Conteúdo obrigatório

### 1. Documentação do contrato

- Doc nova (ex. `docs/kernel-pos-boot-services.md`): decisão dual-phase + COM1; tabela de marcadores; sequência; fora de escopo; como observar; nota de que Serial UEFI **não** vale após o exit.
- Atualizar `docs/kernel-alem-do-boot.md` com ponte (“Etapa 11: ExitBoot — ver …”), sem reescrever o contrato da Etapa 10.
- Ponte mínima em `docs/architecture.md`.
- Sem ADR nova **salvo** troca estrutural inesperada (ex.: abandonar uefi-rs) — a decisão desta spec basta.

### 2. Código no `kernel/`

- Após provas Etapa 10: emitir `EXIT_BOOT_BEGIN`; soltar handles de Serial UEFI antes do exit.
- `unsafe { boot::exit_boot_services(MemoryType::LOADER_DATA) }` (ou tipo alinhado à doc uefi 0.33 / ao bloco preservado).
- Iterar mapa owned; reprovar bump no ponteiro já alocado; driver UART mínimo (init + `write_str` em COM1).
- Continuar `#![no_std]`; sem `std`; sem runtime/node/agent; sem GGUF.

### 3. Gate + AGENTS

- Estender `scripts/verify-boot.sh` / `make verify` para exigir **também** `IA_LIVRE_EXIT_BOOT_OK` (e, se barato, `EXIT_MAP_OK` / `EXIT_MEM_OK`).
- Preservar exigência dos marcadores Etapa 4/10.
- `AGENTS.md` → Como rodar / Como verificar / Estrutura refletem pós-Boot Services + UART.
- Timeout: manter ~45s salvo evidência de necessidade; documentar override.
- Outros gates (runtime/node/agent/harness) **não** regridem.

### 4. README

- Avaliar (`readme-por-fatia`); atualizar só se a capa omitir o handoff pós-Boot Services de forma enganosa — senão “considerado, não necessário”.

## Fora de escopo

- Inferência no kernel; GGUF; llama.cpp / runtime no UEFI
- Runtime Linha B real / substituir `IA_LIVRE_HARNESS_B_SKIP` (B5)
- MMU completa / page tables explícitas / identity map “de verdade”
- Heap geral, buddy/slab, `#[global_allocator]` completo
- Filesystem, rede, GPU, interrupções, scheduler, APIC/timer
- Suporte a máquina física além do necessário para QEMU; multi-UART; VGA
- Mudanças em `runtime/`, `node/`, `agent/` salvo ponte documental
- Prova da hipótese A vs B

## Critérios de aceite

- [ ] Em QEMU UEFI, a serial mostra os marcadores Etapa 4/10 **e** `IA_LIVRE_EXIT_BOOT_BEGIN` **e** `IA_LIVRE_EXIT_BOOT_OK`
- [ ] Há evidência pós-exit de mapa (`EXIT_MAP_OK` + `EXIT_MAP_PAGES=`) e de memória (`EXIT_MEM_OK`)
- [ ] Pós-exit **não** depende de Serial I/O UEFI; contrato documenta UART COM1
- [ ] Gate automatizado do kernel falha se faltar `EXIT_BOOT_OK` (e os OK pré-exit); passa no ambiente de referência
- [ ] Contrato documentado; `AGENTS.md` atualizado; README avaliado
- [ ] Nenhum código de inferência/GGUF no kernel; ADR 0001 respeitado
- [ ] Etapa 11 **não** marcada `feita` nesta spec (só após gate + revisão pelo agente principal)

## Riscos e rollback

- **Risco:** Serial UEFI silenciosa após exit → mitigado pela decisão COM1; documentar e testar no gate.
- **Risco:** `exit_boot_services` falha se mapa/buffers inválidos → seguir padrão uefi-rs (uma chamada que obtém o mapa final); não emitir `EXIT_BOOT_OK` em falha.
- **Risco:** bloco `AllocatePages` não sobrevive se tipo errado → usar `LOADER_DATA` (já Etapa 10); não liberar páginas antes do exit.
- **Risco:** COM1 não mapeada em algum firmware → QEMU/OVMF de referência é o alvo; documentar; gate falha de forma clara.
- **Risco:** escopo inchado (MMU, heap, Linha B) → rejeitar; Pronto quando = ExitBoot + mapa/memória + gate serial.
- **Rollback:** reverter `kernel/` + script de verify ao estado Etapa 10; etapa continua `em_andamento`.

## Decisões abertas (não bloqueiam se documentadas)

1. **Init completo vs mínimo do 16550** — bastam IER/FIFO/LCR/baud se o firmware já inicializou; documentar o mínimo usado.
2. **Exigir só `EXIT_BOOT_OK` vs também `EXIT_MAP_OK`/`EXIT_MEM_OK` no script** — preferir exigir os três OK pós-exit se barato.
3. **Módulo `uart.rs` vs inline em `main.rs`** — extrair se `main.rs` crescer demais.

## Etapa do roadmap

- Etapa 11 — Kernel pós-Boot Services (`em_andamento`, Issue [#13](https://github.com/eriksonlima/projeto-ia-livre/issues/13))
- Spec: `specs/kernel-pos-boot-services/`
- Pronto quando (roadmap): caminho documentado e verificável no UEFI/QEMU para sair de Boot Services (ou equivalente mínimo) com base estável (mapa preservado / memória utilizável), gate serial — ainda sem inferência no kernel.
