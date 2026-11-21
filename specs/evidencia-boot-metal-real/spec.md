# Spec — Evidência de boot metal real (serial ≥ BOOT_OK em PC)

Etapa 46 · Issue [#46](https://github.com/eriksonlima/projeto-ia-livre/issues/46)  
Depende: E30 (artefato ESP) · E35 (gate `METAL_OK`/`SKIP` + formato de evidência).

---

## Resultado visível

Prova **honesta** de boot do kernel IA Livre em **PC UEFI físico**, com log serial versionado e gate `IA_LIVRE_BAREMETAL_METAL_OK` — **ou**, se não houver hardware nesta máquina nem log fornecido pelo operador, **bloqueio honesto** documentado (checklist + procedimento + SKIP na issue), **sem** inventar ou reciclar saída QEMU.

A etapa fecha quando **um** dos caminhos abaixo for cumprido:

| Caminho | Condição | Gate esperado |
|---------|----------|---------------|
| **A — Evidência real** | Arquivo em `docs/evidence/boot-metal/` com serial de PC (≥ `IA_LIVRE_BOOT_OK`), cabeçalho V1, sem QEMU/OVMF | `IA_LIVRE_BAREMETAL_SKIP=0` + `EVIDENCE=…` → `IA_LIVRE_BAREMETAL_METAL_OK` |
| **B — Bloqueio honesto** | Hardware ausente **e** nenhum log fornecido pelo usuário; checklist Secure Boot/serial consolidado; comentário/nota na issue #46 registrando SKIP e critério | Default `SKIP=1` (IMAGE_OK permanece); **não** emite `METAL_OK` |

**Regra dura:** o agente **não inventa** log de metal. Aceitar evidência só se o operador anexar/fornecer captura de PC real.

## Contexto fixo (não reinventar)

- **E35 (feita):** contrato [`docs/boot-hardware-real.md`](../../docs/boot-hardware-real.md), pasta [`docs/evidence/boot-metal/`](../../docs/evidence/boot-metal/), gate em `scripts/verify-baremetal.sh` (`METAL_OK` / `SKIP`). Neste host de referência fechou com **SKIP** (sem PC).
- **E30:** `make baremetal-esp` → `IA_LIVRE_BAREMETAL_IMAGE_OK`; ADR [`0011`](../../docs/adr/0011-boot-imagem-esp-baremetal.md).
- **QEMU ≠ metal:** `make verify` / serial OVMF **nunca** contam como evidência desta etapa.
- Hipótese A vs B / `TOKENS_PER_S` / harness comparable: **intocados**.
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A** | Anexar log real (operador) + `METAL_OK`; se sem PC/log → checklist + SKIP documentado na issue; agente não inventa | **Escolhida** |
| **B** | Exigir PC no CI / runner com USB | **Rejeitada** — inviável |
| **C** | Colar serial QEMU como metal | **Rejeitada** — fraude |
| **D** | Fechar só com docs sem critério escrito de bloqueio | **Rejeitada** — Pronto quando ambíguo |
| **E** | Reescrever kernel/artefato ESP | **Rejeitada** — escopo E30/E35 |

### Escolha: **A — evidência real ou bloqueio honesto com critério escrito**

| Peça | Nesta etapa |
|------|-------------|
| Sucesso mínimo (caminho A) | `IA_LIVRE_BOOT_OK` no log de PC |
| Ideal | `IA_LIVRE_EXIT_BOOT_OK` (+ marcadores COM1) |
| Formato | `IA_LIVRE_BAREMETAL_EVIDENCE_V1` (já E35); nome `YYYY-MM-DD-<host>.txt` |
| Secure Boot | Checklist explícito: desligado / setup; EFI **não** assinado |
| Sem PC / sem log | Caminho B: docs + issue #46; **não** forjar `METAL_OK` |
| Gate | Reutilizar E35; ajustes só se checklist/anti-fraude pedirem (mínimo) |
| Código de produto | Preferir **zero** mudança em `kernel/`/`runtime/`; só docs/gate se necessário |

### Justificativa

- Cumpre o espírito do roadmap (prova metal) sem fraudar ambiente.
- Reaproveita infra E35; E46 é **fechamento com evidência ou honestidade**, não reimplementação do gate.
- Deixa explícito o papel do operador vs do agente.

### Rejeitado (explícito)

- Inventar, sintetizar ou copiar log QEMU para `docs/evidence/boot-metal/`.
- Emitir `METAL_OK` sem arquivo de evidência válido.
- Tratar `IMAGE_OK` ou `SKIP=1` como prova de metal.
- Secure Boot assinado, instalador, drivers USB no kernel, GGUF metal obrigatório.
- Alterar veredito A vs B / emitir `TOKENS_PER_S` nesta etapa.

## Fora de escopo

- Novo layout ESP / mudança obrigatória no kernel.
- Automação de gravação USB no CI.
- Assinatura Secure Boot / MokManager.
- Inferência ou GGUF completo como requisito de metal (E36 permanece opt-in).
- Prova da hipótese A vs B.

## Critérios de aceite

### Comuns (sempre)

- [ ] Checklist Secure Boot + mídia + serial (COM1 115200 8N1) consolidado e referenciável em `docs/boot-hardware-real.md` (e/ou `docs/evidence/boot-metal/README.md`) — sem lacunas operacionais para o operador.
- [ ] Documento deixa claro: QEMU ≠ metal; agente não inventa log; caminho A vs B.
- [ ] `make verify-baremetal` (default `SKIP=1`) permanece verde (`IMAGE_OK`).
- [ ] Gates existentes (`make verify`, harness, etc.) **não** regridem.
- [ ] README avaliado (`readme-por-fatia`).
- [ ] Issue #46 atualizada com o desfecho (METAL_OK **ou** SKIP/bloqueio).

### Caminho A — evidência real

- [ ] Log em `docs/evidence/boot-metal/<arquivo>.txt` com cabeçalho V1 + ≥ `IA_LIVRE_BOOT_OK`.
- [ ] `IA_LIVRE_BAREMETAL_SKIP=0 IA_LIVRE_BAREMETAL_EVIDENCE=<path> make verify-baremetal` emite `IA_LIVRE_BAREMETAL_METAL_OK`.
- [ ] Evidência **sem** indicadores QEMU/OVMF; SHA EFI coerente ou mismatch documentado.

### Caminho B — bloqueio honesto (só se hardware e log ausentes)

- [ ] Critério escrito: “sem PC nesta máquina e sem log fornecido → etapa fecha com SKIP; `METAL_OK` fica pendente até evidência real”.
- [ ] Comentário/nota na issue #46 + ponte no Memory Bank / `docs/evidence/boot-metal/README.md` (estado: sem log anexado).
- [ ] **Não** há arquivo fingindo captura de PC.

### Tabela de ambientes (inalterada em espírito)

| Ambiente | Prova | Gate |
|----------|-------|------|
| QEMU | Serial OVMF | `make verify` |
| Artefato | ESP/tar | `verify-baremetal` → `IMAGE_OK` |
| PC real | Log serial | `SKIP=0` + `EVIDENCE` → `METAL_OK` |
| Sem PC | Skip honesto | `SKIP=1` + registro na issue |

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| Agente ou operador cola QEMU | Gate rejeita; revisão humana do arquivo |
| Fechar etapa sem critério B escrito | Spec exige nota na issue + README evidence |
| Evidência stale (EFI antigo) | Cabeçalho `EFI_SHA256=`; gate compara ou documenta |
| Pressão por `METAL_OK` sem hardware | Caminho B explícito; proibido inventar |

Rollback: remover log inválido; restaurar `SKIP=1`; E30/E35 intactos.

## Etapa do roadmap

- Etapa 46 `em_andamento` — Evidência de boot metal real (serial ≥ BOOT_OK em PC)
- Issue: [#46](https://github.com/eriksonlima/projeto-ia-livre/issues/46)
- Pronto quando (roadmap): log serial de PC real em `docs/evidence/boot-metal/` + `IA_LIVRE_BAREMETAL_METAL_OK` no gate; Secure Boot/checklist documentados.
- **Interpretação desta spec:** o Pronto quando do roadmap é o **caminho A**. Se hardware/log ausentes, a etapa pode fechar pelo **caminho B** (bloqueio honesto com critério escrito na issue) sem emitir `METAL_OK` — registrando no ROADMAP/desfecho que metal permanece pendente de evidência futura.
