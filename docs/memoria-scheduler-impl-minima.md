# Memória model-aware + scheduler por fases — implementação mínima (Etapa 19)

Contrato **mínimo verificável** no kernel UEFI/QEMU **após** `ExitBootServices`: allocator tipado (`Weights` / `KvCache`) + hints Prefill/Decode com quantum distinto + marcadores UART COM1.

Desenho (Etapa 13): [`desenho-memoria-scheduler-nativo.md`](desenho-memoria-scheduler-nativo.md) · ADR [`0003`](adr/0003-memoria-model-aware-e-scheduler-fases.md).  
Base pós-exit: [`kernel-pos-boot-services.md`](kernel-pos-boot-services.md).  
Proxy Linha B (≠ este contrato): [`runtime-nativo-linha-b.md`](runtime-nativo-linha-b.md).

**Não** é inferência / GGUF no kernel. **Não** prova a hipótese A vs B.  
ABI mínima versionada (E71): [`abi-runtime-native.md`](abi-runtime-native.md) — este doc = provedor E19; a versão da fronteira crate↔kernel vive lá.

## Objetivo

Demonstrar no próprio kernel (demo pós-`EXIT_BOOT_OK`) o mecanismo nativo candidato do ADR 0003:

1. Alocar regiões com classe `Weights` e `KvCache` sobre bump/`LOADER_DATA`.
2. Aplicar hints `Prefill` e `Decode` com política de quantum mínima (Prefill > Decode).
3. Emitir marcadores serial observáveis; gate `make verify` cobre `IA_LIVRE_MEM_SCHED_OK`.

Quem “fala” o contrato nesta etapa é o **kernel** (prova de mecanismo). Runtime/harness falando o contrato = Etapa 20 ([`runtime-contrato-nativo.md`](runtime-contrato-nativo.md)).

## Constantes

| Item | Valor |
|------|--------|
| I/O pós-exit | UART COM1 `0x3F8` |
| Classes | `Weights`, `KvCache` |
| Tamanho Weights (prova) | 128 bytes |
| Tamanho KvCache (prova) | 256 bytes |
| Fases mínimas | `prefill`, `decode` (Idle/Load omitidos) |
| `QUANTUM_PREFILL` | 8 |
| `QUANTUM_DECODE` | 2 |
| Invariante | Prefill quantum **>** Decode quantum |
| Sucesso | `IA_LIVRE_MEM_SCHED_OK` |

Quanta são unidades arbitrárias (slots/ticks de política) — **não** timer/APIC/preempt real.

## Ordem serial canônica (pós-exit)

```
… → EXIT_BOOT_OK
  → TYPED_WEIGHTS_BYTES= / TYPED_WEIGHTS_OK
  → TYPED_KVCACHE_BYTES= / TYPED_KVCACHE_OK
  → PHASE=prefill + QUANTUM=<QUANTUM_PREFILL>
  → PHASE=decode  + QUANTUM=<QUANTUM_DECODE>
  → MEM_SCHED_OK
  → NATIVE_BENCH_* (proxy Linha B — Etapa 12)
```

Regressão obrigatória: marcadores Etapas 4/10/11 + `IA_LIVRE_NATIVE_BENCH_OK`.  
Harness B (Etapa 20) exige `NATIVE_BENCH_OK` **e** `MEM_SCHED_OK` / `TYPED_*` (reemite `HARNESS_CONTRACT_*`); proxy permanece `LOAD_KIND=proxy`.

## Marcadores serial (COM1)

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_TYPED_WEIGHTS_BYTES=<n>` | Bytes alocados na classe Weights |
| `IA_LIVRE_TYPED_WEIGHTS_OK` | Alloc + prova write/read Weights |
| `IA_LIVRE_TYPED_KVCACHE_BYTES=<n>` | Bytes alocados na classe KvCache |
| `IA_LIVRE_TYPED_KVCACHE_OK` | Alloc + prova write/read KvCache |
| `IA_LIVRE_PHASE=prefill` | Hint Prefill ativo |
| `IA_LIVRE_QUANTUM=<n>` | Quantum da fase atual |
| `IA_LIVRE_PHASE=decode` | Hint Decode ativo |
| `IA_LIVRE_MEM_SCHED_OK` | Typed alloc + fases + quanta distintos ok |

Em falha de alloc tipado ou se Prefill quantum ≤ Decode: **não** emitir `IA_LIVRE_MEM_SCHED_OK`.

## Exemplo de serial (completo)

```
IA_LIVRE_EXIT_BOOT_OK
IA_LIVRE_TYPED_WEIGHTS_BYTES=128
IA_LIVRE_TYPED_WEIGHTS_OK
IA_LIVRE_TYPED_KVCACHE_BYTES=256
IA_LIVRE_TYPED_KVCACHE_OK
IA_LIVRE_PHASE=prefill
IA_LIVRE_QUANTUM=8
IA_LIVRE_PHASE=decode
IA_LIVRE_QUANTUM=2
IA_LIVRE_MEM_SCHED_OK
IA_LIVRE_NATIVE_BENCH_BEGIN
…
IA_LIVRE_NATIVE_BENCH_OK
```

## Como observar

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
make build
make run
make verify    # VERIFY_TIMEOUT default 45s
```

## Fora de escopo

- GGUF / TinyLlama / inferência / llama.cpp no kernel
- Prova ou refutação da hipótese Linha A vs B
- ABI estável / syscalls finais
- Multi-tenant; resize/free sofisticados; MMU completa; preempt real
- Multi-GPU executado / shard real (ADR 0006) — placement **nativo mínimo** = Etapa 38 ([`gpu-manager-nativo.md`](gpu-manager-nativo.md)), complementar a `MEM_SCHED_OK`
- Runtime host falando o contrato (Etapa 20 / B14 — fora desta etapa)
- Confundir este contrato com o proxy `NATIVE_BENCH_*`

## Spec

[`specs/memoria-scheduler-impl-minima/`](../specs/memoria-scheduler-impl-minima/).
