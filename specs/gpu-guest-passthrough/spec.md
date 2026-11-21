# Spec — GPU real no guest (PCI/pass-through)

Etapa 65 · Issue [#65](https://github.com/eriksonlima/projeto-ia-livre/issues/65) (ex-B60)  
Depende: E38 (`GPU_MGR=native`, QEMU `KIND=synthetic`); E55 (`GPU_REAL_SRC=host` + `GPU_REAL_OK` ou skip `need_gpu`); ADR [`0023`](../../docs/adr/0023-simetria-gpu-harness-inviavel.md) (simetria GPU harness inviável até passthrough).

---

## Resultado visível

Existe um caminho **verificável** de GPU **real no guest** via PCI/VFIO pass-through (QEMU), **além** do path host E55 (`SRC=host`) e **além** do enum sintético E38:

1. **Sucesso guest** — evidência real de device pass-through → `IA_LIVRE_GPU_REAL_SRC=pci_passthrough` (ou equivalente estável fixado na Task 1) + `IA_LIVRE_GPU_REAL_OK`.
2. **Skip honesto** — sem GPU dedicada / sem VFIO / CI → `need_gpu` e/ou `need_vfio` (marcadores estáveis), exit **0**, **sem** `GPU_REAL_OK`.

Identidade **≠** só enum host E55. **≠** `KIND=synthetic` como sucesso. **Proibido** inventar GPU no guest ou emitir `pci_passthrough` sem evidência. **Proibido** `COMPROVA` / fingir simetria GPU harness.

A etapa fecha quando o contrato VFIO/QEMU + gate cobrem sucesso `pci_passthrough` **ou** skip honesto — no mesmo espírito de E55/E62 (hardware opt-in; CI verde sem device).

---

## Contexto fixo (não reinventar)

- E55 / [`docs/gpu-real-nativo.md`](../../docs/gpu-real-nativo.md): `GPU_REAL_*`; canônico CI = `SRC=host`; `pci_passthrough` já previsto como valor estável mas **opt-in / não exercitado** como desfecho desta etapa.
- E38 / [`docs/gpu-manager-nativo.md`](../../docs/gpu-manager-nativo.md): `GPU_MGR=native` + `KIND=synthetic` no QEMU default; `make verify` permanece synthetic.
- E25 / E41: stub host / shard multi-GPU host — **fora**; não rebrandar como guest passthrough.
- ADR 0023: simetria GPU A/B no harness **inviável até** evidência B60/`pci_passthrough`; E64 = `sym_cpu`; E56 permanece assimétrico. Esta etapa **habilita** o pré-requisito documentado; **não** exige fechar simetria harness nem `COMPROVA`.
- ADR 0022 / pilar 1 `BLOQUEIO_FINAL`: intactos.
- Host de referência pode não ter GPU dedicada nem IOMMU/VFIO — skip aceitável (como E55/E62).
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A — Contrato VFIO/QEMU + gate `pci_passthrough` ou skip `need_gpu`/`need_vfio`** | Docs de pré-requisitos (IOMMU/VFIO/QEMU `-device vfio-pci` ou equivalente); runner emite `SRC=pci_passthrough` + `REAL_OK` só com evidência real; senão skip honesto exit 0 | **Escolhida** |
| **B — Exigir VFIO no CI / host de referência** | Gate falha sem passthrough | **Rejeitada** — contradiz skip E55/E62 e realidade do host |
| **C — Emitir `SRC=pci_passthrough` sem device (só docs/marcador)** | “Sucesso” de papel | **Rejeitada** — fraude |
| **D — Contar `SRC=host` (E55) como Pronto quando E65** | Só enum host | **Rejeitada** — Pronto quando exige guest/`pci_passthrough` **ou** skip explícito ≠ host-only success |
| **E — Só documentação, sem gate/marcadores** | ADR/doc sem verificação | **Rejeitada** — Pronto quando pede `GPU_REAL_*` / skip grepável |
| **F — Passthrough + simetria harness + `COMPROVA`** | Fechar ADR 0023 + hipótese | **Rejeitada** — fora; multi-GPU / COMPROVA fora |

### Escolha: **A — contrato VFIO/QEMU + evidência `pci_passthrough` ou skip honesto**

| Peça | Nesta etapa |
|------|-------------|
| Contrato | Doc dedicado (ex. `docs/gpu-guest-passthrough.md`) **ou** seção canônica em `gpu-real-nativo.md` (Task 1 fixa): pré-requisitos VFIO/IOMMU/QEMU; fronteira E38 synthetic × E55 `SRC=host` × E65 `pci_passthrough`; política de skip |
| Evidência sucesso | Device PCI pass-through observável (serial guest `KIND=pci` / log QEMU vfio / script de prova documentado — Task 1 fixa a âncora mínima) → `GPU_REAL_SRC=pci_passthrough` + `GPU_REAL_OK` |
| Skip | Sem GPU: `need_gpu`; GPU sem VFIO/passthrough configurável: `need_vfio` (ou motivo composto documentado); env force-skip (ex. `VERIFY_GPU_PASSTHROUGH_SKIP=1`); exit **0**; **sem** `REAL_OK` |
| Gate | Estender `make verify-gpu-native-real` **ou** target aditivo (ex. `make verify-gpu-guest-passthrough`) — nome fixado na Task 1; **não** substitui `make verify` (E38) nem o path `SRC=host` E55 |
| Anti-fraude | Gate **falha** se `REAL_OK` + `SRC=pci_passthrough` sem evidência guest/VFIO; **falha** se tratar só `SRC=host` ou `KIND=synthetic` como sucesso E65; **proibido** inventar device |
| Harness / hipótese | ADR 0023: ponte “pré-requisito B60 cumprível”; **não** exige corrida simétrica GPU nem `COMPROVA` |
| Kernel default | E38 synthetic **intocado** no CI; path guest passthrough = opt-in / skip |

### Justificativa

- Fecha o Pronto quando (ex-B60) sem exigir hardware raro no CI: skip `need_gpu`/`need_vfio` é desfecho válido.
- Distingue E55 (`host`) de E65 (`pci_passthrough`) sem contaminar `make verify`.
- Cumpre a ponte da ADR 0023 (passthrough como pré-requisito de simetria GPU futura) sem reabrir pilar 1 / `COMPROVA`.
- Alinha honestidade operacional a E55/E62.

### Rejeitado (explícito)

- Fingir passthrough / emitir `pci_passthrough` sem evidência.
- Tratar sucesso só-host (E55) como fechamento de E65.
- Exigir VFIO no CI; falhar o gate default do kernel sem GPU guest.
- `COMPROVA` / simetria harness GPU / `sym_cpu` como critério desta etapa.
- Multi-GPU completo / SR-IOV/MIG / driver vendor in-kernel.
- Inventar `TOKENS_PER_S` ou ACCEL GPU na Linha B sem device.

---

## Conteúdo obrigatório

### 1. Documentação / contrato

- Contrato VFIO/QEMU (doc novo ou seção E55 ampliada — Task 1): como habilitar pass-through; o que conta como evidência; marcadores; skip `need_gpu` / `need_vfio`.
- Pontes: `docs/gpu-real-nativo.md` (E55 × E65), `docs/gpu-manager-nativo.md` (synthetic ≠ passthrough), ADR 0023 (pré-requisito agora especificável).
- ADR nova **somente** se a política de evidência/skip for decisão estrutural além de 0023/0006 (avaliar na Task 1; preferir ponte).
- `AGENTS.md`: Como rodar / Como verificar o gate E65.

### 2. Implementação mínima

- Runner/estágio que: (1) detecta pré-requisitos VFIO/GPU; (2) se pass-through exercitável e evidência ok → emite `SRC=pci_passthrough` + `REAL_OK`; (3) senão skip honesto.
- Extensão guest (probe PCI / `KIND=pci`) **só** se não quebrar CI/E38 synthetic; default permanece skip ou path opt-in.
- **Proibido** caminho que emita `REAL_OK` sem evidência real de guest/VFIO.

### 3. Gate

- Target Makefile fixado na Task 1 (estender E55 ou novo).
- Com passthrough: exige `GPU_REAL_OK` + `SRC=pci_passthrough` (+ âncora de evidência).
- Sem GPU/VFIO / CI: skip grepável exit 0.
- Regressão: `make verify` (E38), `make verify-gpu-native-real` path `host` (E55), stub/shard host sem mudança de semântica.

---

## Fora de escopo

- Fingir passthrough ou GPU no guest.
- Simetria harness GPU / `COMPROVA` / reabrir ADR 0022.
- Alterar critério de sucesso do perfil `sym_cpu` (E64).
- Multi-GPU completo / shard guest / SR-IOV/MIG.
- Driver CUDA/Vulkan in-kernel; offload GGUF / `TOKENS_PER_S` no guest.
- Substituir enum sintética E38 no QEMU default.
- Mudanças em `node/`, `agent/` como requisito.
- Boot metal / `METAL_OK`.

---

## Critérios de aceite

- [ ] Contrato VFIO/QEMU documentado (pré-requisitos, evidência, skip `need_gpu`/`need_vfio`).
- [ ] Caminho emite `GPU_REAL_SRC=pci_passthrough` + `GPU_REAL_OK` **somente** com evidência real — **ou** skip honesto exit 0.
- [ ] Sucesso E65 **≠** só `SRC=host` / `KIND=synthetic`.
- [ ] Gate documentado em `AGENTS.md`; verde com passthrough e com skip.
- [ ] Sem regressão E38/E55 (host); sem `COMPROVA` / ACCEL fingido / multi-GPU fingido.
- [ ] Ponte ADR 0023 atualizada (pré-requisito B60/E65); README avaliado (`readme-por-fatia`).

---

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| Host sem VFIO/GPU | Skip `need_vfio`/`need_gpu` exit 0 (como E55) |
| Confundir E55 host com E65 guest | Critério de aceite e gate exigem `pci_passthrough` **ou** skip — não `host`-as-success |
| Contaminar `make verify` | Path opt-in; E38 synthetic permanece |
| Emitir `pci_passthrough` sem device | Anti-fraude no gate; falha se REAL_OK sem evidência |
| Pressão por COMPROVA/simetria | Fora de escopo explícito; ADR 0022/0023 intactas no critério |

Rollback: remover/estender-revert gate e doc E65; E38/E55 intactos.

---

## Etapa do roadmap

Etapa 65 — GPU real no guest (PCI/pass-through)  
Issue: [#65](https://github.com/eriksonlima/projeto-ia-livre/issues/65) (ex-B60)  
Status roadmap: _(promover / `em_andamento` — agente principal)_  
Pronto quando: `GPU_REAL_SRC=pci_passthrough` (ou equiv.) + `GPU_REAL_OK` **ou** skip `need_gpu` (e/ou `need_vfio`); ≠ só enum host.  
Spec: `specs/gpu-guest-passthrough/`
