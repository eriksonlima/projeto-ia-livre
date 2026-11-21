# Spec — GPU real no caminho nativo (além de `synthetic`)

Etapa 55 · Issue [#55](https://github.com/eriksonlima/projeto-ia-livre/issues/55) (ex-B49)  
Depende: E38 (`GPU_MGR=native`, enum **sintética** no QEMU).

---

## Resultado visível

Existe um caminho **verificável** de GPU **real** ligado ao contrato do manager nativo (E38), **além** de `IA_LIVRE_GPU_DEV*_KIND=synthetic`:

1. **Detecção/placement com GPU real** — via PCI/pass-through no guest **ou** host path documentado com `SRC` explícito — **ou**
2. **Skip honesto** `need_gpu` / `IA_LIVRE_GPU_NEED_GPU` quando não houver GPU utilizável.

Identidade **≠** stub E25 (`GPU_MGR=host_stub`). **Proibido** tratar `synthetic`-only como sucesso desta etapa. **Proibido** fingir multi-GPU (`DEVICES≥2` sem hardware) ou inventar `TOKENS_PER_S`.

A etapa fecha quando:

1. Contrato documenta fronteira E38 synthetic × E55 real × E25 stub × E41 shard host.
2. Gate **novo** (ou estágio aditivo dedicado) prova real **ou** skip `need_gpu` — sem regressão de `make verify` (E38 synthetic permanece).
3. `AGENTS.md` descreve Como verificar; README avaliado (`readme-por-fatia`).

---

## Contexto fixo (não reinventar)

- E38 / [`docs/gpu-manager-nativo.md`](../../docs/gpu-manager-nativo.md): `GPU_MGR=native` pós-ExitBoot; QEMU de referência = **1 device sintético**; afinidade/placement já existem; `make verify` cobre synthetic.
- E25 / [`docs/gpu-manager-prototipo-host.md`](../../docs/gpu-manager-prototipo-host.md): `GPU_MGR=host_stub` + `verify-gpu-manager` — **host**, skip sem GPU; **≠** nativo.
- E41 / [`docs/shard-multi-gpu-host.md`](../../docs/shard-multi-gpu-host.md): `host_shard_exec` multi-device no host; skip `need_2_devices` — **≠** esta etapa (E55 = GPU real **no caminho nativo / bridge nativo**, single-device basta).
- Kernel freestanding pós-Exit; QEMU tipicamente **sem** GPU PCI real / pass-through.
- ADR 0001 / 0006: host ≠ nativo; manager = mecanismos; runtime dono de CUDA/Vulkan; **não** embutir driver vendor no kernel nesta etapa.
- Hipótese A vs B / harness comparable: **intocados**; sem `TOKENS_PER_S` fingido.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A — PCI real no guest** | Varredura PCI / VFIO pass-through; `DEV*_KIND=pci` (ou equivalente) + placement na serial COM1 | **Opt-in / secundária** — válida quando hardware+QEMU pass-through existirem; **não** requisito do gate default (CI/QEMU sem GPU) |
| **B — Bridge / host path** | Consumidor host (ou estágio de gate) detecta GPU real no host, documenta vínculo com o contrato nativo E38 e emite `SRC` + marcadores de prova; **≠** reutilizar `host_stub` | **Escolhida (canônica para CI)** |
| **C — Skip `need_gpu`** | Sem GPU detectável → `IA_LIVRE_GPU_NEED_GPU` / motivo `need_gpu`, exit 0; **sem** `GPU_REAL_OK` | **Escolhida (obrigatória)** — desfecho honesto default sem hardware |
| **D — Synthetic como “real”** | Aceitar `DEV0_KIND=synthetic` + `GPU_MGR_OK` como prova E55 | **Rejeitada** — contradiz Pronto quando |
| **E — Reusar `verify-gpu-manager` (E25)** | Estender stub host e chamar de nativo | **Rejeitada** — confunde host×nativo |
| **F — Exigir multi-GPU / tokens** | `DEVICES≥2` ou `TOKENS_PER_S` no gate E55 | **Rejeitada** — fraude / fora de escopo |

### Escolha: **B + C canônicos; A opt-in documentado**

| Peça | Nesta etapa |
|------|-------------|
| Onde (B) | Host: script/estágio sob `scripts/` (e/ou glue mínima) que (1) prova GPU real no host (`nvidia-smi` / equivalente documentado) **e** (2) ancora no contrato nativo E38 (marcadores `GPU_MGR=native` de fixture/log QEMU **ou** referência explícita ao contrato doc) com `SRC` |
| Onde (A) | Guest: se pass-through disponível, enum PCI pós-Exit **além** de synthetic; marcador `KIND=pci` (nome fixado na Task 1); **não** obrigatório no CI |
| Identidade | Namespace dedicado `IA_LIVRE_GPU_REAL_*` (ou equivalente fixado na Task 1); **proibido** emitir `GPU_MGR=host_stub` neste caminho; E38 `GPU_MGR=native` + synthetic **permanece** no `make verify` default |
| SRC | `IA_LIVRE_GPU_REAL_SRC=host\|pci_passthrough` (valores estáveis) |
| Sucesso real | `IA_LIVRE_GPU_REAL_OK` **somente** com GPU real detectada + placement/hint mínimo documentado (1 device basta) |
| Skip | `IA_LIVRE_GPU_NEED_GPU` (+ motivo `need_gpu` ou env `VERIFY_GPU_REAL_SKIP=1`); exit **0**; **sem** `GPU_REAL_OK` |
| Placement | Reusar semântica E38 (affin/place hints) **ou** eco documentado no bridge; single-device; shard multi-GPU **fora** |
| Gate | **Novo** `make verify-gpu-native-real` (nome fixado na Task 1) — **adicional**; **não** substitui `make verify` nem `verify-gpu-manager` |
| Anti-fraude | Gate **falha** se emitir `GPU_REAL_OK` com única evidência `KIND=synthetic`; **falha** se inventar `DEVICES≥2`; **não** exige pass-through |

### Justificativa

- QEMU de referência não tem GPU PCI → A sozinha não fecha CI; B+C fecham o Pronto quando com honestidade.
- Distingue E38 (synthetic sempre no boot) de E55 (real ou skip), sem contaminar o gate kernel default.
- Preserva ADR 0001/0006: host path marca `SRC=host`; PCI guest marca `SRC=pci_passthrough` — sem fingir que synthetic = real.

### Rejeitado (explícito)

- Contar `synthetic` + `GPU_MGR_OK` como sucesso da Etapa 55.
- Unificar gate com E25 `host_stub` ou exigir `host_shard_exec` (E41).
- Driver CUDA/Vulkan in-kernel; multi-GPU executado; `TOKENS_PER_S` / prova harness comparable.
- Tornar pass-through PCI obrigatório no CI.
- Alterar semântica de `make verify` para **falhar** sem GPU real (E38 synthetic deve continuar verde).

---

## Conteúdo obrigatório

### 1. Documentação / contrato

- Novo: `docs/gpu-real-nativo.md` — o que prova (real vs skip); tabela E25 / E38 / E41 / E55; marcadores; política de skip; limites.
- Pontes em `docs/gpu-manager-nativo.md` (synthetic ≠ real E55) e stub/shard host.
- ADR novo **somente** se a fronteira bridge `SRC=host` vs PCI guest for decisão estrutural estável (avaliar na Task 1; senão ponte ADR 0006).
- `AGENTS.md`: Como rodar / Como verificar o gate novo.

### 2. Implementação mínima

- Estágio B: detecção host GPU real + emissão `GPU_REAL_SRC=host` + placement/hint mínimo + `GPU_REAL_OK` **ou** `GPU_NEED_GPU`.
- Opcional A: probe PCI no guest / doc de como habilitar pass-through; se implementado, `SRC=pci_passthrough` + `KIND=pci`.
- E38 `gpu_mgr.rs` synthetic **intocado** no caminho default do `make verify` (extensão guest só se A for exercitável sem quebrar CI).

### 3. Gate

- `make verify-gpu-native-real` (nome na Task 1).
- Com GPU: exige `GPU_REAL_OK` + `SRC=` ∈ {`host`,`pci_passthrough`} + evidência ≠ synthetic-only.
- Sem GPU / CI: `GPU_NEED_GPU` (ou skip env) exit 0.
- Regressão: `make verify` (E38), `verify-gpu-manager` (E25), `verify-gpu-shard-host` (E41) sem mudança de semântica.

---

## Fora de escopo

- Multi-GPU / shard executado (E41 permanece o caminho host multi-device).
- Offload GGUF / geração / `TOKENS_PER_S` no guest ou bridge.
- Substituir enum sintética E38 no QEMU default.
- Driver vendor in-kernel; IOMMU/SR-IOV/MIG completos.
- Mudanças em `node/`, `agent/`, harness comparable como critério.
- Prova hipótese A vs B.

---

## Critérios de aceite

- [ ] `docs/gpu-real-nativo.md` + pontes E38/E25/E41.
- [ ] Decisão B+C (+ A opt-in) refletida em marcadores estáveis e política de skip.
- [ ] Caminho implementado: real com `SRC` **ou** `need_gpu` honesto; **nunca** synthetic-as-success.
- [ ] Gate novo documentado em `AGENTS.md`; verde com GPU e com skip.
- [ ] Sem regressão E38/E25/E41; sem `TOKENS_PER_S` / multi-GPU fingido.
- [ ] README avaliado (`readme-por-fatia`).

---

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| Confundir E25 stub com E55 | Marcadores `GPU_REAL_*` + gate separado; docs tabela |
| Contaminar `make verify` exigindo GPU real | Gate E55 adicional; E38 synthetic permanece |
| Pass-through inviável no CI | A opt-in; B+C fecham Pronto quando |
| Fingir real via synthetic | Gate rejeita `GPU_REAL_OK` sem evidência real / com só `KIND=synthetic` |

Rollback: remover gate/scripts E55 + doc; E38/E25/E41 intactos.

---

## Etapa do roadmap

Etapa 55 — GPU real no caminho nativo (além de `synthetic`)  
Issue: [#55](https://github.com/eriksonlima/projeto-ia-livre/issues/55)  
Status roadmap: `em_andamento`  
Pronto quando: detecção/placement com GPU real (PCI/pass-through ou host path documentado) **ou** skip `need_gpu` honesto; ≠ stub E25; sem fingir multi-GPU.  
Spec: `specs/gpu-real-nativo/`
