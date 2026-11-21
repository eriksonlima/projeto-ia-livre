# Runtime falando o contrato nativo — Etapa 20

Consumidor do contrato candidato ADR 0003 (`Weights` / `KvCache` + fases Prefill/Decode), **além** do proxy Linha B da Etapa 12.

Desenho: [`desenho-memoria-scheduler-nativo.md`](desenho-memoria-scheduler-nativo.md).  
ADR: [`adr/0003-memoria-model-aware-e-scheduler-fases.md`](adr/0003-memoria-model-aware-e-scheduler-fases.md).  
Proxy B (não é este contrato): [`runtime-nativo-linha-b.md`](runtime-nativo-linha-b.md).  
Harness: [`harness-linha-a-b.md`](harness-linha-a-b.md).

> **Hipótese A vs B: não comprovada.** Evidência de contrato ≠ carga GGUF canônica em B ≠ prova.

## Dependência da Etapa 19

O **provedor** do contrato no kernel (allocator tipado + política de quantum + marcadores serial pós-ExitBoot) é a Etapa 19. Enquanto E19 estiver `em_andamento` / ausente em `main`, esta etapa avança com:

1. Documentação desta superfície (este doc).
2. **Shim host** (`ia-livre-runtime-contract`) — stub alinhado ao desenho, **sem** QEMU.
3. Gate host `make verify-runtime-contract`.

Integração nativa QEMU contra marcadores reais E19 fica **bloqueada** até E19 mergear o caminho verificável.

## Superfície (esboço — não ABI estável)

Alinhado ao desenho; **não** congela syscall:

```
Runtime / shim                         Kernel (E19) ou stub host
──────────────                         ─────────────────────────
mem_alloc(class=Weights|KvCache, n) →  região tipada
sched_set_phase(Prefill|Decode|…)   →  hint / quantum candidato
```

Classes mínimas: `Weights`, `KvCache`.  
Fases mínimas exercidas nesta etapa: `Prefill` → `Decode` (Load/Idle candidatas no desenho).

## Marcadores do provedor (Etapa 19 — candidatos)

Nomes esperados pelo Pronto quando da E19 / desenho — **não inventados aqui como ABI final**. Se E19 publicar nomes diferentes no merge, este doc e o consumidor nativo alinham-se na Task 4.

| Marcador (candidato) | Significado |
|----------------------|-------------|
| `IA_LIVRE_TYPED_WEIGHTS_OK` (e `TYPED_*` irmãos) | Região Weights alocada/tipada |
| `IA_LIVRE_TYPED_KVCACHE_OK` (candidato / irmão) | Região KvCache alocada/tipada |
| `IA_LIVRE_PHASE=Prefill` \| `Decode` | Hint de fase ativo |
| `IA_LIVRE_QUANTUM=…` | Quantum/política mínima aplicada |
| `IA_LIVRE_MEM_SCHED_OK` | Caminho memória+scheduler mínimo OK |

Se a Etapa 19 publicar nomes finais ligeiramente diferentes no merge, a Task 4 alinha o consumidor nativo — **sem** inventar ABI paralela.  
Até E19 publicar em `main`, estes **não** são exigidos por `make verify-runtime-contract` (gate host).

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

Backend futuro (Task 4): `IA_LIVRE_CONTRACT_BACKEND=native_qemu` (ou equivalente documentado) quando houver evidência serial E19 — **sem** fingir GGUF.

## Harness B: PROXY vs contrato

| Caminho | O que é | Marcadores | `TOKENS_PER_S` |
|---------|---------|------------|----------------|
| Linha A | Host + GGUF | `HARNESS_LINE=A`, load/tokens | Permitido (A) |
| Linha B (E12) | QEMU + proxy microbench | `HARNESS_LINE=B`, `PROXY=*`, `NATIVE_BENCH_*` | **Proibido** |
| Contrato host (E20) | Shim no Linux | `CONTRACT_*`, `RUNTIME_CONTRACT_OK` | **Proibido** (não é inferência) |
| Contrato nativo (E20 T4) | QEMU + E19 | serial `MEM_SCHED`/`TYPED_*` + reemissão honesta | **Proibido** até GGUF real em B |

- Shim host **não** conta como Linha B.
- Evidência de contrato **não** substitui o proxy no `verify-harness` até a Task 4 decidir pontes explícitas.
- **Proibido** emitir `TOKENS_PER_S` / fingir load GGUF em qualquer caminho B ou de contrato desta etapa.

## Como rodar (shim host)

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
cargo build -p ia-livre-runtime-contract
cargo run -p ia-livre-runtime-contract
# Esperado: CONTRACT_* + IA_LIVRE_RUNTIME_CONTRACT_OK
make verify-runtime-contract
```

## O que esta etapa **não** faz

- Não prova a hipótese A vs B
- Não carrega TinyLlama no IA Livre
- Não implementa GPU manager
- Não edita o mecanismo E19 no `kernel/` enquanto outro agente o detém
