# Plan — Kernel além do boot

## Abordagem

Três fatias verticais até o Pronto quando da Etapa 10. Entrega = **mecanismos de memória mínimos no kernel UEFI** (mapa + alocação/bump) + **gate serial** sem regressão de `IA_LIVRE_BOOT_OK`. **Sem** inferência, **sem** `ExitBootServices`, **sem** Linha B.

### Task 1 — Contrato documental + esqueleto de marcadores

1. Criar `docs/kernel-alem-do-boot.md`: objetivo da etapa; decisão (Boot Services + mapa UEFI + `AllocatePages` + bump); tabela de marcadores; fora de escopo; como observar na serial.
2. Ponte curta em `docs/architecture.md` (primeiro mecanismo de memória no kernel) — mínimo necessário.
3. Em `kernel/`: preparar constantes/helpers de escrita serial reutilizando o caminho da Etapa 4; pode emitir placeholders ou só documentar nomes se a implementação completa for Task 2 — preferir **já** esboçar emissão de `MEM_MAP_OK` / `ALLOC_OK` só se barato; o critério da Task 1 é o **contrato legível**.
4. `AGENTS.md`: menção parcial (doc + intenção dos marcadores).
5. `readme-por-fatia`: avaliar; provavelmente cedo demais.

Critério parcial: qualquer implementador sabe o que emitir e o que não fazer.

### Task 2 — Mapa de memória + alocação/bump no `kernel/`

1. Implementar obtenção do memory map UEFI (uefi-rs); iterar descritores; contar Conventional Memory (páginas ou MiB — alinhar ao marcador `IA_LIVRE_MEM_CONVENTIONAL_PAGES=`).
2. `AllocatePages` de N páginas (N pequeno, fixo, documentado); inicializar bump sobre esse bloco; alocar ≥1 pedaço; escrever/ler padrão (prova de uso).
3. Emitir na serial, nesta ordem sugerida:
   - `IA_LIVRE_BOOT_OK`
   - `IA_LIVRE_MEM_CONVENTIONAL_PAGES=<n>`
   - `IA_LIVRE_MEM_MAP_OK`
   - `IA_LIVRE_ALLOC_BYTES=<n>`
   - `IA_LIVRE_ALLOC_OK`
4. Em falha de mapa/alloc: **não** emitir o `*_OK` correspondente (gate falha); log humano opcional na serial.
5. Atualizar a doc com o N escolhido e exemplo de saída.
6. `AGENTS.md` → Como rodar (kernel) menciona os novos marcadores.
7. `readme-por-fatia`: reavaliar.

Critério parcial: `make run` mostra todos os marcadores obrigatórios na serial.

### Task 3 — Gate estendido + AGENTS completo

1. Estender `scripts/verify-boot.sh` para exigir `IA_LIVRE_BOOT_OK`, `IA_LIVRE_MEM_MAP_OK` e `IA_LIVRE_ALLOC_OK` (e, se barato, linhas `MEM_CONVENTIONAL_PAGES=` / `ALLOC_BYTES=` presentes).
2. Manter `make verify` como alvo; timeout `VERIFY_TIMEOUT` (default 45s).
3. Completar `AGENTS.md` → Como verificar (Etapa 10 / gate do kernel atualizado).
4. Confirmar que outros gates (runtime, node, agent, harness) não foram afetados.
5. `readme-por-fatia`: se a capa ainda disser só “hello boot”, considerar menção curta + ponte AGENTS; senão “considerado, não necessário”.
6. Não marcar roadmap `feita` nesta task — agente principal após gate + revisor.

### Valores canônicos (orientação)

| Item | Valor |
|------|--------|
| Target | `x86_64-unknown-uefi` |
| Boot Services | Sim (sem ExitBoot) |
| Páginas de prova | 1–4 × 4 KiB |
| Marcadores OK | `BOOT_OK`, `MEM_MAP_OK`, `ALLOC_OK` |
| Make | `verify` (estendido) |
| Timeout | `VERIFY_TIMEOUT` default 45s |

### Notas de implementação (orientação, não código aqui)

- Preferir APIs estáveis do crate `uefi` já em uso; evitar novos crates salvo necessidade clara.
- Não introduzir `alloc` global / `#[global_allocator]` completo se o bump local bastar para a prova.
- Não tocar `runtime/`, `node/`, `agent/` na implementação.
- Não baixar GGUF nem alterar harness Linha B.
- Manter mensagem `IA_LIVRE_BOOT_OK` compatível com greps existentes em docs/AGENTS.

## Arquivos prováveis

- `docs/kernel-alem-do-boot.md` (Task 1; detalhes N/exemplo na Task 2)
- `docs/architecture.md` — ponte mínima (Task 1)
- `kernel/src/main.rs` (e módulos locais se o arquivo crescer — ex. `mem.rs`) (Task 2)
- `kernel/Cargo.toml` — só se precisar de feature/dep uefi já alinhada
- `scripts/verify-boot.sh`, `Makefile` — gate (Task 3; Make provavelmente só help text)
- `AGENTS.md` — Como rodar / Como verificar / Estrutura
- `README.md` — só se `readme-por-fatia` exigir

Não editar como entrega: `runtime/**`, `node/**`, `agent/**`, scripts do harness, pesos em `models/`.

## Dependências

- Etapa 4 feita (boot + `make verify` com `IA_LIVRE_BOOT_OK`)
- Host: Rust target UEFI, QEMU, OVMF (iguais à Etapa 4)
- Sem GGUF, GPU, P2P ou agent para o gate desta etapa

## Verificação

1. Checklist de `spec.md` (critérios de aceite)
2. `make run` — serial com marcadores
3. `make verify` — exige BOOT + MEM_MAP + ALLOC
4. Após gate verde da etapa: agente principal chama `revisor-de-fatia`, atualiza ROADMAP/Memory Bank (fora do papel do especificador)
