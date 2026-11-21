# Spec — ABI mínima estável kernel↔runtime-native

Etapa 71 · Issue [#71](https://github.com/eriksonlima/projeto-ia-livre/issues/71) (ex-B66)  
Depende: ADR [`0003`](../../docs/adr/0003-memoria-model-aware-e-scheduler-fases.md) (desenho Weights/KvCache + Prefill/Decode); impl. E19 [`memoria-scheduler-impl-minima.md`](../../docs/memoria-scheduler-impl-minima.md); consumidor E20 [`runtime-contrato-nativo.md`](../../docs/runtime-contrato-nativo.md) (shim host ≠ ABI nativa); crate `runtime-native/` (ADR [`0010`](../../docs/adr/0010-runtime-nativo-freestanding-linha-b.md)); glue Linha B [`runtime-nativo-linha-b.md`](../../docs/runtime-nativo-linha-b.md).

---

## Resultado visível

Existe um **contrato versionado** da superfície mínima kernel↔`runtime-native` (classes de memória, fases, version id, marcadores) **e** um **consumidor nativo verificável** que prova o contrato — **sem** puxar o motor de inferência para dentro do `kernel/` (ADR 0001 / 0003 / 0010), **sem** inventar `TOKENS_PER_S` / `COMPROVA` / `METAL_OK`, e **sem** misturar autonomia (E70).

| Caminho | Condição | Esperado |
|---------|----------|----------|
| **A — ABI mínima versionada + consumidor (escolhido)** | Superfície já existente (MemClass/Phase E19, `LayoutReport`/`prepare`, marcadores `RUNTIME_NATIVE_*` / `MEM_SCHED_*`) é documentável e versionável sem syscall maduro | Doc + `ABI_VERSION` (ou equivalente) + consumidor nativo (kernel e/ou teste freestanding) + gate aditivo |
| **B — Glue atual honesto (só se A colapsar)** | Congelar ABI “estável” exigir syscall/IPC/processo separado inviável agora, ou forçar motor no kernel | Contrato do glue ad hoc + critérios de estabilização + gate prova o doc — **sem** fingir ABI madura |

**Preferência:** **A** (factível com o que já existe).

---

## Contexto fixo (não reinventar)

- **ADR 0003:** interface kernel↔runtime = classes `Weights`/`KvCache` + hints Prefill/Decode; kernel **não** executa o modelo. ABI/syscalls ficaram **fora** daquela ADR — lacuna B66/E71.
- **E19:** allocator tipado + quantum Prefill/Decode + `MEM_SCHED_OK` / `TYPED_*` / `PHASE=` no serial pós-ExitBoot.
- **E20:** shim host `ia-livre-runtime-contract` (`CONTRACT_BACKEND=host_shim`) + evidência harness `HARNESS_CONTRACT_*`. **≠** ABI crate↔kernel; não substitui esta etapa.
- **ADR 0010:** motor em `runtime-native/` (`no_std`); kernel **orquestra** (loader, alloc, serial) e **chama** a API da crate; glue fino em `main.rs` ok; motor **não** é produto monolítico no kernel.
- **Estado atual do glue:** `kernel` depende de `ia-livre-runtime-native` via path; chama `prepare` / `try_*` / decode guest; emite `IA_LIVRE_RUNTIME_NATIVE_*` ad hoc. **Não** há `ABI_VERSION` documentado nem superfície mínima congelada.
- **ADR 0001:** inferência **fora** do kernel; mais interfaces a manter — esta etapa fecha a interface mínima, não a viola.
- Hipótese A vs B / comparable: **não** forçar `COMPROVA`. Espécie subset (E44) permanece.
- Autonomia E70 / bridge E49: **fora** — não misturar.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A — ABI mínima versionada (Rust freestanding + serial)** | Documentar + versionar superfície mínima (MemClass, Phase, layout handshake, version id, marcadores) + consumidor nativo verificável; motor permanece na crate | **Escolhida** |
| **B — Contrato do glue ad hoc** | Doc do estado atual + critérios de estabilização + gate de doc; sem version id “ABI estável” | **Reserva** — só se Task 1 provar que A exige syscall/IPC ou move motor ao kernel |
| **C — Syscall / IPC processo separado** | Kernel e runtime em espaços distintos com trap/syscalls | **Rejeitada agora** — sem MMU/userspace; over-design vs Pronto quando |
| **D — Embutir motor no `kernel/src`** | Copiar Prefill/Decode/tensores para o núcleo | **Rejeitada** — ADR 0001 / 0010 |
| **E — Contar só shim host E20** | `verify-runtime-contract` = “ABI nativa” | **Rejeitada** — host_shim ≠ fronteira kernel↔runtime-native |
| **F — Inventar `TOKENS_PER_S` / `COMPROVA` / `METAL_OK`** | Prova falsa de estabilidade via métricas | **Rejeitada** |

### Escolha: **A — ABI mínima versionada + consumidor nativo**

| Peça | Nesta etapa |
|------|-------------|
| Natureza da ABI | **Contrato Rust freestanding** (crate pública mínima + handshake de memória/fase) **e** contrato de **observabilidade serial** alinhado. **Não** é syscall estável, ABI C multi-linguagem, nem IPC. Nome honesto no doc: «ABI mínima v1 (freestanding)» |
| Version id | Constante versionada (ex. `IA_LIVRE_ABI_VERSION=1` / `runtime_native::ABI_VERSION`) emitida pelo consumidor e exigida pelo gate. Task 1 fixa o nome canônico |
| Superfície mínima (congelar só isto) | (1) classes `Weights` \| `KvCache`; (2) fases `Prefill` \| `Decode` (+ Idle opcional no doc, não obrigatório no gate); (3) handshake de layout/`prepare` (ou equivalente documentado); (4) namespace de marcadores serial da ABI (`ABI_*` e/ou subset canônico de `MEM_SCHED_*` + ponte `RUNTIME_NATIVE_*`); (5) fronteira: o que **não** entra (tensores, sampling, GGUF parse completo como “kernel API”) |
| Fora da ABI v1 (explícito) | API completa de Prefill/Decode guest, KV interno, dequant, species/perf, GPU manager, syscalls |
| Consumidor nativo | **Preferência:** caminho já no kernel pós-ExitBoot que declara a versão + exercita alloc tipado/fase **via** a superfície documentada; **e/ou** teste freestanding/`#[cfg(test)]` / binário host `no_std`-compatível que prova símbolos/constantes do contrato **sem** QEMU no default do gate se viável. Task 1 escolhe o consumidor mínimo verificável |
| O que o kernel **pode** fazer | Glue: passar buffer GGUF, regiões tipadas, chamar funções da crate, emitir serial. **Não** reimplementar matmul/dequant/sampling como produto em `main.rs` |
| Gate | Novo `make verify-abi-runtime-native` (nome final na Task 1) **aditivo**; prova version id + superfície mínima; **não** exige `COMPROVA` / espécie canônica |
| Relação com E19/E20 | E19 = provedor tipado no kernel; E20 = shim host. E71 = **versão** da fronteira crate↔kernel + prova. Pontes nos docs; **não** quebrar `verify` / `verify-runtime-contract` / `verify-harness` |
| ADR | Preferência: doc de contrato + ponte em ADR 0003/0010. **ADR novo (próximo livre ≈ 0025)** se a decisão «ABI = freestanding versionada ≠ syscall» precisar de registro estrutural além dos docs de contrato |
| ADR 0001 | Intacta: motor na crate; kernel só mecanismos + glue |

### Justificativa (por que A, não B agora)

- Já existem enums/tipos espelhados (MemClass/Phase no kernel; `LayoutReport`/`KvCache`/`prepare` na crate) e marcadores serial estáveis o bastante para **versionar o mínimo**.
- O Pronto quando pede «contrato versionado + consumidor nativo» — A cumpre sem fingir syscall.
- Congelar *toda* a API de inferência seria prematuro (ADR 0003); A congela só a fronteira mecanismo↔runtime.
- B só se «estável» for interpretado como syscall/IPC — aí documentar glue + critérios, sem rotular ABI madura.

### Pivot B (obrigatório se A colapsar)

Se na Task 1 ficar claro que a única forma de «ABI estável» exige userspace/syscalls, ou que versionar força mover motor para o kernel:

1. Parar implementação teatral de A.
2. Contrato honesto do glue atual (`main.rs` chama crate; marcadores ad hoc) + critérios de estabilização (ex.: quando houver isolamento de processo / tabela de symbols congelada).
3. Gate prova presença do contrato + marcador de teto (ex. `IA_LIVRE_ABI_BLOCK=glue_not_stable`); **sem** `ABI_OK` fingido de estabilidade.
4. Gates E19/E20/harness/kernel permanecem.

---

## Conteúdo obrigatório

### 1. Documentação / contrato

- Contrato canônico (sugestão): `docs/abi-runtime-native.md` — o que é ABI v1; version id; superfície mínima (structs/enums/fases/marcadores); o que fica **fora**; relação E19 (provedor) / E20 (shim host) / ADR 0010 (crate); proibições ADR 0001; proibido `TOKENS_PER_S`/`COMPROVA`/`METAL_OK` como prova de ABI.
- Pontes curtas: `docs/runtime-contrato-nativo.md`, `docs/memoria-scheduler-impl-minima.md`, `docs/runtime-nativo-linha-b.md`, ADR 0003/0010 (ou ADR 0025 se necessário).
- `AGENTS.md`: Como rodar / Como verificar o gate aditivo (Task 3).

### 2. Implementação mínima (A)

- Constantes/tipos de versão na crate `runtime-native` (e espelho honesto no glue do kernel se o consumidor for o guest).
- Consumidor que **prova** o contrato (não só o doc):
  - emite `IA_LIVRE_ABI_VERSION=` (ou nome fixado) + marcador de sucesso da ABI (ex. `IA_LIVRE_ABI_OK`);
  - exercita MemClass + Phase (alinhado a E19) **sem** exigir Decode guest completo nem `TOKENS_PER_S` novos.
- Refator mínima do glue **só** se necessária para alinhar nomes à superfície documentada — **proibido** expandir inferência no kernel.

### 3. Gate

- `make verify-abi-runtime-native` (nome final na Task 1).
- Exige version id + `ABI_OK` (ou equivalente) via path documentado (QEMU serial **ou** teste freestanding — Task 1 fixa; preferir path barato se provar a mesma superfície).
- Regressão: `make verify` (MEM_SCHED / RUNTIME_NATIVE existentes) e `make verify-runtime-contract` intactos.
- **Não** exige `COMPROVA`, espécie 22L×32, GPU, metal, autonomia.

---

## Fora de escopo

- Syscalls finais, MMU/userspace, ABI C multi-linguagem, IPC multi-processo.
- Mover Prefill/Decode/dequant/sampling para `kernel/src` como produto.
- Alterar veredito harness / inventar `TOKENS_PER_S` / `COMPROVA` / `METAL_OK`.
- Autonomia (E70), bridge autonomia (E49), Rede/TCP guest.
- Espécie canônica Linha B; GPU manager nativo além do que E38 já faz.
- Congelar a API completa de `runtime-native` (só a superfície mínima da fronteira).
- Substituir ou enfraquecer E19/E20/gates existentes.
- Promover etapa a `feita` (agente principal após gate).

---

## Critérios de aceite

- [ ] Decisão A vs B registrada; desfecho **A** (ou pivot B com contrato/critérios de estabilização).
- [ ] Contrato versionado documenta superfície mínima + version id + fronteira ADR 0001 (motor fora do kernel).
- [ ] Consumidor nativo verificável emite version id + sucesso da ABI **sem** puxar inferência para o kernel.
- [ ] Gate aditivo verde; regressão `verify` + `verify-runtime-contract`.
- [ ] Sem `TOKENS_PER_S`/`COMPROVA`/`METAL_OK` inventados como prova de ABI; sem misturar autonomia.
- [ ] `AGENTS.md` atualizado; `README.md` avaliado (`readme-por-fatia`).

---

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| Violação ADR 0001 (motor no kernel) | Critério explícito: lógica de tensores/sampling permanece em `runtime-native/`; review rejeita cópia para `main.rs` |
| Super-ABI (congelar toda a crate) | Doc lista **somente** superfície mínima; resto = interno/evolutivo |
| Confundir E20 host_shim com ABI nativa | Gate E71 exige consumidor nativo (crate/kernel), não só `RUNTIME_CONTRACT_OK` |
| Confundir marcadores `RUNTIME_NATIVE_*` de geração com prova de ABI | ABI prova version id + MemClass/Phase/layout handshake; geração subset é ortogonal |
| Over-design syscall | C rejeitada; pivot B se insistirem em syscall agora |
| Gate pesado (QEMU sempre) | Preferir teste freestanding da superfície + marcador; QEMU só se for o único consumidor honesto |
| Quebrar E19/harness | Mudanças mínimas de glue; regressão `make verify` |

Rollback: remover doc/gate/constantes E71; glue E19/E44 e crate permanecem como antes.

---

## Etapa do roadmap

- Etapa 71 `em_andamento` — ABI mínima estável kernel↔runtime-native
- Pronto quando: contrato versionado documentado + consumidor nativo; sem puxar inferência pro kernel (ADR 0001/0003).
