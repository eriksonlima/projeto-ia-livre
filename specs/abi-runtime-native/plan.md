# Plan — ABI mínima estável kernel↔runtime-native

## Abordagem

Fechar B66/E71 versionando a fronteira **já existente** entre kernel (mecanismos E19 + glue) e `runtime-native` (motor freestanding) — sem syscall e sem mover inferência para o núcleo.

1. **Contrato + decisão A (Task 1)** — `docs/abi-runtime-native.md`: natureza da ABI (freestanding v1 ≠ syscall); `ABI_VERSION`; superfície mínima (MemClass, Phase, layout/`prepare`, marcadores); o que fica fora; pontes E19/E20/ADR 0003/0010; nome do consumidor e do `make` target; critérios de pivot B. ADR 0025 **só** se a distinção estrutural precisar de ADR próprio. **Sem** gate obrigatório ainda (esqueleto opcional).
2. **Version id + consumidor (Task 2)** — Constante(s) na crate (+ espelho no glue se o consumidor for o guest); consumidor emite `ABI_VERSION` + `ABI_OK` (nomes da Task 1) exercitando MemClass/Phase/layout handshake; refator mínima do glue **só** para alinhar à superfície — **proibido** expandir motor no `kernel/`.
3. **Gate + pontes (Task 3)** — `scripts/verify-abi-runtime-native.sh` + `Makefile`; `AGENTS.md`; README avaliado; regressão `make verify` + `make verify-runtime-contract`.

Ordem: 1 → 2 → 3. Se Task 1 pivota B: Task 2 = contrato do glue + critérios de estabilização + marcador de teto; Task 3 = gate que prova o doc (sem `ABI_OK` falso).

## Arquivos prováveis

- `docs/abi-runtime-native.md` (**novo**, contrato canônico)
- Pontes: `docs/runtime-contrato-nativo.md`, `docs/memoria-scheduler-impl-minima.md`, `docs/runtime-nativo-linha-b.md`, `docs/desenho-memoria-scheduler-nativo.md` (curtas)
- `docs/adr/0003-….md` / `0010-….md` (ponte) **ou** `docs/adr/0025-abi-runtime-native-freestanding.md` se Task 1 exigir ADR
- `runtime-native/src/lib.rs` (e módulo opcional `abi.rs`) — `ABI_VERSION`, tipos/reexports mínimos da superfície
- `kernel/src/main.rs` — glue mínimo: emitir version id / alinhar nomes (**sem** mover Prefill/Decode para cá)
- Opcional: teste freestanding/`tests/` ou `#[cfg(test)]` na crate se o gate default for sem QEMU
- `scripts/verify-abi-runtime-native.sh`, `Makefile` (`verify-abi-runtime-native`)
- `AGENTS.md`; opcionalmente `README.md`
- **Intocados salvo ponte:** `runtime-contract/`, harness comparable, `agent/`, autonomia E70, GPU gates

## Dependências

- E19 feita — `MEM_SCHED_*` / tipados / fases.
- E20 feita — shim host permanece ortogonal.
- `runtime-native/` + glue kernel (E29–E44) — API e marcadores existentes para versionar.
- QEMU: só se o consumidor escolhido for o serial guest; preferir path freestanding no gate se provar a mesma superfície.
- Autonomia / metal / espécie canônica / `COMPROVA` — **fora**.

## Verificação

- **A — sucesso:** contrato versionado no repo + consumidor emite `ABI_VERSION=` + `ABI_OK` (ou nomes fixados) sem motor no kernel.
- **Gate:** `make verify-abi-runtime-native` exit 0 no host de referência.
- **Regressão:** `make verify` (MEM_SCHED / RUNTIME_NATIVE existentes) e `make verify-runtime-contract` intactos.
- **Negativo:** falha se só ecoar doc sem version id; falha se “prova” for só `RUNTIME_CONTRACT_OK` host; ausência de `TOKENS_PER_S`/`COMPROVA`/`METAL_OK` inventados como prova de ABI.
- **Fronteira ADR 0001:** review da fatia confirma que dequant/matmul/sampling **não** migraram para `kernel/src` como produto.
- **Se B:** gate exige contrato do glue + marcador de teto; sem `ABI_OK` de estabilidade.
- Checklist `AGENTS.md` → Como verificar (Task 3).
