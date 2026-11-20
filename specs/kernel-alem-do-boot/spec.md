# Spec — Kernel além do boot

## Resultado visível

No **UEFI/QEMU (x86-64)**, o kernel IA Livre (`kernel/`) passa a expor **mecanismos mínimos além** da linha `IA_LIVRE_BOOT_OK`:

1. **Consulta e resumo do mapa de memória UEFI** (Boot Services), com marcador serial verificável.
2. **Alocação mínima comprovável** (páginas via UEFI `AllocatePages` e/ou bump allocator sobre região convencional), com marcador serial verificável.
3. **Gate serial** que exige os novos marcadores **e** preserva `IA_LIVRE_BOOT_OK` (sem regressão do boot).

Documentação curta descreve o contrato (marcadores, o que conta como “além do boot”, limites). **Ainda sem inferência no kernel**, sem llama.cpp no UEFI, sem runtime Linha B.

## Contexto fixo (não reinventar)

- ADR 0001: kernel pequeno/auditável; inteligência **fora** do kernel — [`docs/adr/0001-separacao-camadas-e-p2p.md`](../../docs/adr/0001-separacao-camadas-e-p2p.md).
- Arquitetura (camada 1): boot UEFI + memória física/virtual como responsabilidade do kernel — [`docs/architecture.md`](../../docs/architecture.md).
- Etapa 4 (`specs/bootstrap-kernel/`): boot + `IA_LIVRE_BOOT_OK`; `ExitBootServices`, heap completo e UART bare-metal ficaram **explicitamente** fora.
- Stack: `uefi-rs` + target `x86_64-unknown-uefi`; gate atual `make verify` / `scripts/verify-boot.sh`.
- Runtime Linha B / harness B real = backlog **B5** (fora desta etapa).
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: avaliar `README.md` por fatia; só atualizar se a home do GitHub ficar enganosa.

## Decisão de desenho (obrigatória nesta etapa)

| Peça | Escolha nesta etapa |
|------|---------------------|
| Ambiente | Continuar sob **UEFI Boot Services** (mesmo fluxo QEMU/OVMF da Etapa 4) |
| Mecanismo A | **Mapa de memória UEFI** (`memory_map` / equivalente uefi-rs) + resumo serial |
| Mecanismo B | **Alocação mínima**: preferir `AllocatePages` (Boot Services) **e** um **bump allocator** trivial sobre um bloco já obtido (prova de “mecanismo de memória” no código do projeto, não só chamada única) |
| `ExitBootServices` | **Fora** desta etapa (handoff pós-UEFI / heap bare-metal fica etapa futura) |
| Carregamento de arquivo ESP | **Fora** do mínimo (alternativa mencionada no roadmap; não necessária se mapa + alloc cumprirem o Pronto quando) |
| Inferência / GGUF / llama.cpp | **Proibido** no kernel nesta etapa |
| Gate | Estender o gate do kernel (`make verify` / `verify-boot.sh` **ou** script irmão documentado) para exigir marcadores novos **além** de `IA_LIVRE_BOOT_OK` |

### Por que mapa UEFI + bump (e não ExitBootServices agora)

- Cumpre o Pronto quando (“alocação/mapa de memória … com gate serial”) com risco baixo no ambiente já gateado.
- Mantém o kernel **auditável e pequeno** (ADR 0001) sem reinventar UART/MMU pós-ExitBoot.
- `ExitBootServices` + alocador bare-metal seria salto de escopo (serial, panic, identidade de páginas) — melhor depois que o contrato de memória sob Boot Services existir.
- Carregamento mínimo de payload no ESP é útil para Linha B futura, mas **não** é o diferencial desta fatia se memória já estiver comprovada.

### Marcadores serial (canônicos)

Estáveis e grepáveis (além de `IA_LIVRE_BOOT_OK`, que **permanece**):

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_BOOT_OK` | Boot UEFI ok (regressão Etapa 4) |
| `IA_LIVRE_MEM_MAP_OK` | Mapa de memória obtido e processado |
| `IA_LIVRE_MEM_CONVENTIONAL_PAGES=` | Contagem (ou equivalente documentado) de páginas Conventional Memory — prova numérica do mapa |
| `IA_LIVRE_ALLOC_OK` | Alocação mínima (páginas + uso via bump) concluiu |
| `IA_LIVRE_ALLOC_BYTES=` | Bytes alocados/comprometidos na prova (valor > 0) |

Opcional (documentar se emitido): `IA_LIVRE_MEM_DESC_COUNT=`, endereço base do bloco bump em hex.

Ordem sugerida na serial: `BOOT_OK` → resumo mapa → `MEM_MAP_OK` → prova alloc → `ALLOC_OK` (ordem fixa ajuda o gate).

## Conteúdo obrigatório

### 1. Documentação do contrato

- Doc curta (ex. `docs/kernel-alem-do-boot.md`) **ou** seção explícita em doc/kernel existente: mecanismos desta etapa, marcadores, limites (sem ExitBoot, sem inferência), como rodar/verificar.
- Ponte mínima em `docs/architecture.md` se couber (ex.: “primeiro mecanismo de memória no kernel UEFI — Etapa 10”).
- Sem ADR nova **salvo** escolha estrutural inesperada (ExitBoot agora, troca de stack, etc.) — a decisão desta spec basta.

### 2. Código no `kernel/`

- Obter mapa de memória UEFI; iterar descritores; agregar Conventional (e tipos úteis se barato).
- Alocar bloco (`AllocatePages`) e exercitar bump (ex.: `alloc` de N bytes, escrever/ler padrão, não só “chamei a API”).
- Emitir marcadores na serial (mesmo caminho Serial I/O / ConOut da Etapa 4).
- Continuar `#![no_std]`; sem `std`; sem dependência de runtime/node/agent.

### 3. Gate + AGENTS

- Gate automatizado exige `IA_LIVRE_BOOT_OK` + `IA_LIVRE_MEM_MAP_OK` + `IA_LIVRE_ALLOC_OK` (e, se barato, presença de `MEM_CONVENTIONAL_PAGES=` / `ALLOC_BYTES=`).
- Preferência: **estender** `scripts/verify-boot.sh` / `make verify` (mesmo alvo do kernel) para não fragmentar o gate do SO; se o script for renomeado, atualizar Makefile + AGENTS de forma consistente.
- `AGENTS.md` → Como rodar / Como verificar / Estrutura refletem os novos marcadores.
- Timeout permanece razoável (default ~45s; override `VERIFY_TIMEOUT`).
- Gates de runtime/node/agent/harness **não** regridem.

### 4. README

- Avaliar (`readme-por-fatia`); atualizar só se a capa omitir mecanismos do kernel e isso enganar o visitante — senão registrar “considerado, não necessário”.

## Fora de escopo

- Inferência no kernel; GGUF; llama.cpp / runtime no UEFI
- Runtime Linha B real / substituir `IA_LIVRE_HARNESS_B_SKIP` (B5)
- `ExitBootServices`, page tables/MMU completa, heap geral, allocator buddy/slab
- Filesystem completo, rede, GPU, GPU manager, interrupções/scheduler
- Carregamento de modelo ou payload de inferência a partir do ESP
- Bare metal no notebook do autor (QEMU basta)
- Mudanças em `runtime/`, `node/`, `agent/` salvo ponte documental
- Prova da hipótese A vs B

## Critérios de aceite

- [ ] Em QEMU UEFI, a serial mostra `IA_LIVRE_BOOT_OK` **e** `IA_LIVRE_MEM_MAP_OK` **e** `IA_LIVRE_ALLOC_OK`
- [ ] Há evidência numérica do mapa (`IA_LIVRE_MEM_CONVENTIONAL_PAGES=` ou equivalente documentado) e da alocação (`IA_LIVRE_ALLOC_BYTES=` > 0)
- [ ] Existe bump (ou equivalente mínimo documentado) **além** de uma única chamada opaca sem uso do buffer
- [ ] Gate automatizado do kernel falha se faltar qualquer marcador obrigatório; passa no ambiente de referência
- [ ] Contrato documentado; `AGENTS.md` atualizado; README avaliado
- [ ] Nenhum código de inferência/GGUF no kernel; ADR 0001 respeitado
- [ ] Etapa 10 **não** marcada `feita` nesta spec (só após gate + revisão pelo agente principal)

## Riscos e rollback

- **Risco:** mapa UEFI exige buffer sizing em duas passagens → seguir padrão uefi-rs; documentar.
- **Risco:** alocação falha em OVMF com pouca memória → pedir tamanho pequeno e fixo (ex. 1–4 páginas); falhar com marcador ausente (gate vermelho), não inventar sucesso.
- **Risco:** escopo inchado (`ExitBootServices`, MMU, loader de modelo) → rejeitar; Pronto quando = mapa + alloc + gate.
- **Risco:** quebrar `IA_LIVRE_BOOT_OK` ao refatorar serial → gate exige ambos os conjuntos de marcadores.
- **Rollback:** reverter mudanças em `kernel/` e no script de verify; restaurar gate só-BOOT_OK; etapa continua `em_andamento`.

## Decisões abertas (não bloqueiam se documentadas)

1. **Tamanho do bloco de prova** (páginas) — default sugerido: 1–4 páginas de 4 KiB.
2. **Estender `verify-boot.sh` vs script novo** — preferir estender o existente; nome do Make `verify` permanece.
3. **Quando introduzir `ExitBootServices`** — etapa futura ( candidata a backlog após esta).
4. **Carregamento mínimo ESP** — só se mapa+alloc forem insuficientes (não esperado) ou etapa futura / B5.

## Etapa do roadmap

- Etapa 10 — Kernel além do boot (`em_andamento`, Issue [#10](https://github.com/eriksonlima/projeto-ia-livre/issues/10))
- Spec: `specs/kernel-alem-do-boot/`
- Pronto quando (roadmap): no UEFI/QEMU, mecanismos mínimos além de `IA_LIVRE_BOOT_OK` (ex.: alocação/mapa de memória ou carregamento mínimo documentado), com gate serial verificável — ainda sem inferência no kernel.
