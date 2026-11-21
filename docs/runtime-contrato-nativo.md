# Runtime falando o contrato nativo — Etapa 20

Consumidor do contrato candidato ADR 0003 (`Weights` / `KvCache` + fases Prefill/Decode), **além** do proxy Linha B da Etapa 12.

Desenho: [`desenho-memoria-scheduler-nativo.md`](desenho-memoria-scheduler-nativo.md).  
ADR: [`adr/0003-memoria-model-aware-e-scheduler-fases.md`](adr/0003-memoria-model-aware-e-scheduler-fases.md).  
Provedor kernel (Etapa 19): [`memoria-scheduler-impl-minima.md`](memoria-scheduler-impl-minima.md).  
Proxy B (não é este contrato sozinho): [`runtime-nativo-linha-b.md`](runtime-nativo-linha-b.md).  
Harness: [`harness-linha-a-b.md`](harness-linha-a-b.md).

> **Hipótese A vs B: não comprovada.** Evidência de contrato ≠ carga GGUF canônica em B ≠ prova.

## Dependência da Etapa 19

O **provedor** do contrato no kernel (allocator tipado + política de quantum + marcadores serial pós-ExitBoot) é a Etapa 19 — **feita** em `main` (`MEM_SCHED_OK` / `TYPED_*`).

Esta etapa entrega:

1. Documentação desta superfície (este doc).
2. **Shim host** (`ia-livre-runtime-contract`) — stub alinhado ao desenho, **sem** QEMU.
3. Gate host `make verify-runtime-contract`.
4. **Integração QEMU** (Task 4): `scripts/run-harness-line-b.sh` observa o serial E19 e reemite evidência honesta no namespace `HARNESS_CONTRACT_*`, **preservando** o proxy E12.

## Superfície (esboço host — ≠ ABI nativa E71)

Alinhado ao desenho / impl. E19; shim host **não** congela a ABI crate↔kernel.  
ABI mínima freestanding versionada: [`abi-runtime-native.md`](abi-runtime-native.md) (Etapa 71).

Alinhado ao desenho / impl. E19; **não** congela syscall:

```
Runtime / shim / harness B             Kernel (E19) ou stub host
──────────────────────────             ─────────────────────────
mem_alloc(class=Weights|KvCache, n) →  região tipada
sched_set_phase(Prefill|Decode|…)   →  hint / quantum
```

Classes mínimas: `Weights`, `KvCache`.  
Fases mínimas: Prefill → Decode (serial E19: `prefill` / `decode`).

## Marcadores do provedor (Etapa 19 — canônicos)

Contrato: [`memoria-scheduler-impl-minima.md`](memoria-scheduler-impl-minima.md).

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_TYPED_WEIGHTS_BYTES=` / `TYPED_WEIGHTS_OK` | Região Weights |
| `IA_LIVRE_TYPED_KVCACHE_BYTES=` / `TYPED_KVCACHE_OK` | Região KvCache |
| `IA_LIVRE_PHASE=prefill` \| `decode` | Hint de fase |
| `IA_LIVRE_QUANTUM=` | Quantum da fase (Prefill=8, Decode=2) |
| `IA_LIVRE_MEM_SCHED_OK` | Caminho memória+scheduler mínimo OK |

Gate: `make verify` (inclui estes + `NATIVE_BENCH_OK`).

## Marcadores do consumidor / shim host (canônicos — Etapa 20)

Namespace distinto do harness (`HARNESS_*`) e do proxy (`NATIVE_BENCH_*`).

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_CONTRACT_BACKEND=host_shim` | Consumidor é shim no host (**≠** Linha B) |
| `IA_LIVRE_CONTRACT_ALLOC_WEIGHTS=OK` | Alloc tipado Weights exercido |
| `IA_LIVRE_CONTRACT_ALLOC_KVCACHE=OK` | Alloc tipado KvCache exercido |
| `IA_LIVRE_CONTRACT_PHASE=Prefill` | Fase Prefill anunciada |
| `IA_LIVRE_CONTRACT_PHASE=Decode` | Fase Decode anunciada (após Prefill) |
| `IA_LIVRE_RUNTIME_CONTRACT_OK` | Sequência mínima do consumidor concluída |

## Marcadores harness B — evidência nativa (Task 4)

Observados no serial QEMU e **reemitidos** por `run-harness-line-b.sh` (namespace `HARNESS_CONTRACT_*`).  
Proxy E12 **permanece** (`PROXY=*`, `LOAD_KIND=proxy`).

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_HARNESS_CONTRACT_BACKEND=native_qemu` | Evidência veio do kernel E19 via QEMU |
| `IA_LIVRE_HARNESS_CONTRACT_MEM_SCHED=OK` | `MEM_SCHED_OK` visto no serial |
| `IA_LIVRE_HARNESS_CONTRACT_TYPED_WEIGHTS=OK` | `TYPED_WEIGHTS_OK` visto |
| `IA_LIVRE_HARNESS_CONTRACT_TYPED_KVCACHE=OK` | `TYPED_KVCACHE_OK` visto |
| `IA_LIVRE_HARNESS_CONTRACT_PHASE_PREFILL=OK` | `PHASE=prefill` visto |
| `IA_LIVRE_HARNESS_CONTRACT_PHASE_DECODE=OK` | `PHASE=decode` visto |
| `IA_LIVRE_HARNESS_CONTRACT_*_BYTES=` | Espelha bytes tipados (opcional) |

**Proibido** neste caminho: `TOKENS_PER_S`, `LOAD_S`, `LOAD_KIND=gguf`, modelo TinyLlama.

## Harness B: PROXY vs contrato

| Caminho | O que é | Marcadores | `TOKENS_PER_S` |
|---------|---------|------------|----------------|
| Linha A | Host + GGUF | `HARNESS_LINE=A`, load/tokens | Permitido (A) |
| Linha B (E12+E20) | QEMU + proxy **e** evidência MEM_SCHED | `PROXY=*`, `HARNESS_CONTRACT_*` | **Proibido** |
| Contrato host (E20) | Shim no Linux | `CONTRACT_*`, `RUNTIME_CONTRACT_OK` | **Proibido** |

- Shim host **não** conta como Linha B.
- Evidência de contrato **não** é carga GGUF canônica em B (B15+).
- Hipótese **não** comprovada.

## Como rodar

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Shim host (sem QEMU)
cargo build -p ia-livre-runtime-contract
cargo run -p ia-livre-runtime-contract
make verify-runtime-contract

# Evidência nativa via harness B (QEMU + E19 + proxy)
./scripts/run-harness-line-b.sh
make verify-harness   # A GGUF + B proxy+contrato
make verify           # serial kernel incl. MEM_SCHED_OK
```

## O que esta etapa **não** faz

- Não prova a hipótese A vs B
- Não carrega TinyLlama no IA Livre
- Não implementa GPU manager
- Não altera o mecanismo E19 no `kernel/` (só observa/reemite)
