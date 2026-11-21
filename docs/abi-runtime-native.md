# ABI mínima v1 — kernel ↔ runtime-native (Etapa 71)

Contrato **versionado** da fronteira freestanding entre o kernel IA Livre (mecanismos) e a crate `runtime-native` (motor).  
**Não** é syscall, ABI C multi-linguagem nem IPC.  
ADR 0001 / 0003 / 0010: inferência **fora** do kernel; kernel orquestra e chama a crate.

## Version id

| Campo | Valor |
|-------|--------|
| `ABI_VERSION` | `1` |
| Constante Rust | `ia_livre_runtime_native::ABI_VERSION` |
| Serial | `IA_LIVRE_ABI_VERSION=1` |
| Sucesso | `IA_LIVRE_ABI_OK` |

Bump de versão só com mudança da superfície mínima abaixo (doc + constante + gate).

## Superfície mínima (congelada nesta v1)

| Peça | Contrato |
|------|----------|
| Classes de memória | `Weights` \| `KvCache` (E19 `MemClass`; tipagem no kernel) |
| Fases | `Prefill` \| `Decode` (Idle opcional no desenho; gate exige Prefill+Decode) |
| Handshake layout | `prepare(gguf) → LayoutReport` na crate (versão GGUF + tensores) |
| Observabilidade | `MEM_SCHED_*` / `TYPED_*` / `PHASE=` (E19) + `RUNTIME_NATIVE_*` (glue) + `ABI_*` (esta etapa) |

## Fora da ABI v1

API completa de Prefill/Decode guest, KV interno, dequant, sampling, species/perf, GPU manager, syscalls, autonomia (E70).

## Consumidores

| Consumidor | Como prova |
|------------|------------|
| **Freestanding** (default do gate) | `cargo test -p ia-livre-runtime-native abi_v1` emite `ABI_VERSION` + `ABI_OK` |
| **Guest** (QEMU) | Kernel emite os mesmos marcadores pós-`MEM_SCHED` (`make verify`) |

## Relação com E19 / E20

| Etapa | Papel |
|-------|--------|
| E19 | Provedor tipado no kernel (`MEM_SCHED_OK`) |
| E20 | Shim host (`CONTRACT_BACKEND=host_shim`) — **≠** esta ABI |
| E71 | Versiona a fronteira crate↔kernel + prova |

## Limites

- Sem puxar Prefill/Decode/dequant/sampling para `kernel/src` como produto.
- Sem inventar `TOKENS_PER_S` / `COMPROVA` / `METAL_OK` como prova de ABI.
- Sem rotular o glue ad hoc pré-E71 como “ABI estável” sem `ABI_VERSION`.

## Pivot B (se «estável» = syscall)

Critérios de reabertura: userspace/isolamento de processo **ou** tabela de symbols C congelada. Até lá: desfecho A (freestanding v1).

## Gate

```bash
make verify-abi-runtime-native
```

Esperado: `IA_LIVRE_ABI_VERSION=1` + `IA_LIVRE_ABI_OK`.  
Regressão: `make verify-runtime-contract`; `make verify` cobre emissão guest.
