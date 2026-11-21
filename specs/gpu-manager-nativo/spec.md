# Spec — GPU manager nativo (mecanismos kernel ↔ runtime)

Etapa 38 · Issue [#37](https://github.com/eriksonlima/projeto-ia-livre/issues/37) (ex-B31)  
Depende: E11 (ExitBoot + UART COM1), E19 (`MEM_SCHED` / Weights·KvCache / Prefill·Decode), E25 (stub **host** — fronteira, **não** reutilizar semântica), E16/ADR 0006 (desenho).

---

## Resultado visível

O kernel IA Livre expõe **mecanismos nativos mínimos** de GPU manager **pós-ExitBoot** (e/ou ponte honesta com `runtime-native/` no caminho Linha B), com **marcadores serial** distintos do stub host da Etapa 25:

1. **Enumeração** mínima de aceleradores (contagem + id sintético ou detectável; **sem** exigir CUDA/Vulkan real no QEMU).
2. **Afinidade** de regiões tipadas (`Weights` / `KvCache`, ADR 0003) a um **device hint** verificável.
3. **Placement** por fase (`Prefill` / `Decode`) — hint documentado e emitido na serial.
4. Identidade **`IA_LIVRE_GPU_MGR=native`** + `IA_LIVRE_GPU_MGR_OK` na UART COM1; gate kernel (`make verify`) cobre o caminho.

**Não** entrega multi-GPU completo, driver vendor in-kernel, `TOKENS_PER_S`, prova A vs B, nem desktop.

A etapa fecha quando:

1. Contrato em `docs/gpu-manager-nativo.md` descreve ordem pós-exit, marcadores, fronteira host×nativo×runtime e limites.
2. `make verify` (extensão aditiva de `scripts/verify-boot.sh`) exige a sequência GPU manager nativo **sem** regressão de `MEM_SCHED_OK` / `NATIVE_BENCH_OK`.
3. Stub Etapa 25 (`IA_LIVRE_GPU_MGR=host_stub`, `make verify-gpu-manager`) e Etapa 8 (`verify-runtime-gpu`) **inalterados** em semântica.
4. `AGENTS.md` atualizado; shard pipeline/layer permanece **documentado**, não executado.

---

## Contexto fixo (não reinventar)

- ADR 0006 + [`docs/desenho-gpu-manager-multi-gpu.md`](../../docs/desenho-gpu-manager-multi-gpu.md): contrato esboçado `list_devices` → alloc+afinidade → placement por fase; multi-GPU preferido = pipeline/layer sharding **futuro**.
- ADR 0001: inferência **fora** do kernel; runtime dono de kernels CUDA/Vulkan — manager nativo = **mecanismos**, não llama.cpp no núcleo.
- ADR 0003 + [`docs/memoria-scheduler-impl-minima.md`](../../docs/memoria-scheduler-impl-minima.md): Etapa 19 já emite `TYPED_*`, `PHASE=*`, `MEM_SCHED_OK` — **esta etapa complementa** com «em qual device», **não** substitui o scheduler.
- Etapa 25 / [`docs/gpu-manager-prototipo-host.md`](../../docs/gpu-manager-prototipo-host.md): `IA_LIVRE_GPU_MGR=host_stub` no **host** — **≠** nativo; gates separados.
- Etapa 8 / ADR 0002: `IA_LIVRE_ACCEL`, `--n-gpu-layers` — **≠** GPU manager nativo.
- QEMU: **não** é obrigatório GPU PCI pass-through; enum pode ser **sintética** (0 ou 1 device lógico) desde que honesta e verificável na serial.
- Hipótese A vs B: **proibido** `TOKENS_PER_S` fingido, `LOAD_KIND=gguf` adulterado, alteração de `verify-harness-comparable` como critério desta etapa.
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A** | Módulo `kernel/` pós-exit: enum sintética + afinidade sobre regiões E19 + placement por fase; marcadores COM1 | **Escolhida (núcleo)** |
| **B** | Ponte mínima `runtime-native/` consumindo o mesmo contrato (reemissão ou eco de marcadores no proxy Linha B) | **Escolhida (opcional na Task 2)** — só se não duplicar fraude |
| **C** | Varredura PCI real + driver NVIDIA in-kernel | **Rejeitada** — fora do mínimo; QEMU não garante hardware |
| **D** | Reusar `host_stub` na serial do kernel | **Rejeitada** — confunde host vs nativo |
| **E** | Multi-GPU com ≥2 devices obrigatório no gate | **Rejeitada** — finge cluster |
| **F** | Integrar manager na Etapa 8 / llama.cpp | **Rejeitada** — viola fronteira |

### Escolha: **A (+ B opcional) — mecanismos nativos pós-ExitBoot com identidade `native`**

| Peça | Escolha nesta etapa |
|------|---------------------|
| Onde | `kernel/` após `IA_LIVRE_MEM_SCHED_OK`; UART COM1 (`0x3F8`) |
| Identidade | `IA_LIVRE_GPU_MGR=native` (**proibido** `host_stub` neste caminho) |
| Enum | `IA_LIVRE_GPU_DEVICES=<N>`; por device: `IA_LIVRE_GPU_DEV<id>_KIND=synthetic\|…` (mínimo 1 linha se N≥1); N=0 permitido com placement degradado documentado |
| Afinidade | Após demo E19: `IA_LIVRE_GPU_AFFIN_CLASS=weights\|kvcache` + `IA_LIVRE_GPU_AFFIN_DEV=<id>` ligado às regiões tipadas já provadas |
| Placement | `IA_LIVRE_GPU_PLACE_PHASE=prefill\|decode` + `IA_LIVRE_GPU_PLACE_HINT=device<id>\|<class>` alinhado às fases E19 |
| Shard | `IA_LIVRE_GPU_SHARD_DOC=pipeline_layer` (igual stub — **só documentado**, sem execução multi-GPU) |
| Sucesso | `IA_LIVRE_GPU_MGR_OK` |
| Runtime-native | Se existir hook no proxy (`NATIVE_BENCH_*`): no máximo **eco** de `IA_LIVRE_GPU_MGR=native` ou marcador `IA_LIVRE_GPU_NATIVE_BRIDGE_OK` — **sem** `TOKENS_PER_S` |
| Anti-fraude | Gate **não** aceita `GPU_MGR_OK` sem `GPU_MGR=native` e sem `GPU_DEVICES=`; **não** exige `DEVICES≥2` |

### Ordem serial canônica (pós-exit, trecho novo)

```
… → MEM_SCHED_OK
  → GPU_MGR=native
  → GPU_DEVICES=<N>  [+ linhas DEV* se N≥1]
  → GPU_AFFIN_* (weights + kvcache)
  → GPU_PLACE_PHASE=prefill + GPU_PLACE_HINT=…
  → GPU_PLACE_PHASE=decode + GPU_PLACE_HINT=…
  → GPU_SHARD_DOC=pipeline_layer
  → GPU_MGR_OK
  → NATIVE_BENCH_* (inalterado em ordem e contrato E12)
```

Regressão obrigatória: `BOOT_OK` … `EXIT_BOOT_OK` … `MEM_SCHED_OK` … `NATIVE_BENCH_OK` + obs E37 se já presente no fluxo.

### Rejeitado (explícito)

- Driver CUDA/Vulkan/ROCm in-kernel; pass-through GPU no QEMU como requisito do gate.
- `IA_LIVRE_GPU_MGR=host_stub` no kernel; unificar gates 25 e 38.
- Tensor/expert parallel, RDMA, clusters; shard **executado** entre ≥2 GPUs.
- Alterar `verify-runtime-gpu`, `verify-gpu-manager`, harness comparable como critério de fechamento.
- ABI/syscalls estáveis; desktop/GOP para status GPU.
- Prova hipótese A vs B via multi-GPU.

---

## Fora de escopo

- Implementação de pipeline/layer sharding real (≥2 GPUs ativas).
- Offload de pesos GGUF para device real; geração medida na Linha B.
- Substituir ou fundir Etapa 25 stub host.
- IOMMU, SR-IOV, MIG, ACPI _SB.PCI0.GFX0 completo.
- Mudanças em `node/`, `agent/`, `runtime/` host (salvo doc pontual).
- Atualizar ADR 0006 para «implementado» — ponte doc apenas.

---

## Critérios de aceite

- [ ] `docs/gpu-manager-nativo.md`: contrato, marcadores, ordem, QEMU sem GPU real, fronteira host×nativo×E8.
- [ ] Pontes em `docs/desenho-gpu-manager-multi-gpu.md` (item «enum nativo pós-ExitBoot» = E38) e `docs/gpu-manager-prototipo-host.md` (stub ≠ nativo).
- [ ] `kernel/`: demo pós-`MEM_SCHED_OK` emitindo marcadores conforme spec; módulo dedicado (ex. `kernel/src/gpu_mgr.rs`) preferível.
- [ ] `scripts/verify-boot.sh` + greps em `AGENTS.md` exigem `GPU_MGR=native`, `GPU_MGR_OK`, `GPU_DEVICES=`, afinidade e placement mínimos.
- [ ] `make verify` verde; `make verify-gpu-manager` e `make verify-runtime-gpu` sem regressão de semântica/skip.
- [ ] Opcional documentado: ponte `runtime-native` sem `TOKENS_PER_S`.
- [ ] README avaliado (`readme-por-fatia`).
- [ ] Nenhuma prova A vs B nem multi-GPU completo fingido.

---

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| Confundir E25 stub com E38 nativo | Marcador `GPU_MGR=native` obrigatório; docs e AGENTS com tabela host×nativo |
| Regressão MEM_SCHED / NATIVE_BENCH | Inserir bloco GPU **depois** de `MEM_SCHED_OK`; gate exige ordem |
| Escopo PCI/driver | Enum sintética no QEMU; doc declara honestidade |
| Timeout `make verify` | Marcadores aditivos; `VERIFY_TIMEOUT` ajustável documentado |

Rollback: remover bloco GPU do kernel + extensão do verify; docs revertem ponte; E19/E25/E8 permanecem válidas.

---

## Etapa do roadmap

Etapa 38 — GPU manager nativo (mecanismos kernel ↔ runtime)  
Issue: [#37](https://github.com/eriksonlima/projeto-ia-livre/issues/37)  
Status roadmap: `em_andamento`  
Pronto quando: enum/afinidade/placement mínimo pós-ExitBoot verificável; sem fingir multi-GPU completo.  
Spec: `specs/gpu-manager-nativo/`