# Spec — Boot UEFI em hardware real (evidência serial) (Etapa 35)

## Resultado visível

Caminho **documentado e verificável** para registrar boot do kernel IA Livre em **PC UEFI físico** com evidência **serial** (≥ `IA_LIVRE_BOOT_OK`; ideal `IA_LIVRE_EXIT_BOOT_OK` via COM1), **sem** fingir que QEMU/OVMF = bare-metal e **sem** exigir PC físico no CI.

A etapa fecha quando:

1. **Checklist operacional** e **procedimento de captura serial** (USB-UART / adaptador, 115200 8N1, COM1) estão no contrato, alinhados ao artefato da Etapa 30.
2. **Formato de evidência anexada** definido (arquivo versionável ou referência em issue) com critérios mínimos de autenticidade (marcadores presentes, contexto do hardware, SHA do EFI exercitado).
3. **Gate estendido** (`make verify-baremetal` ou equivalente) aceita **evidência anexada** (`IA_LIVRE_BAREMETAL_SKIP=0` + validação do log) **OU** **skip honesto** (`IA_LIVRE_BAREMETAL_SKIP=1`) — nunca inventa `BOOT_OK` de metal a partir de saída QEMU.
4. **AGENTS.md** e ponte em `docs/boot-hardware-real.md` descrevem o gate de metal vs artefato vs QEMU.

## Contexto fixo (não reinventar)

- **Etapa 30 (feita):** `make baremetal-esp` + `make verify-baremetal` → `IA_LIVRE_BAREMETAL_IMAGE_OK`; `IA_LIVRE_BAREMETAL_SKIP=1` (default) no trecho hardware; ADR [`0011`](../../docs/adr/0011-boot-imagem-esp-baremetal.md); contrato [`docs/boot-hardware-real.md`](../../docs/boot-hardware-real.md).
- **QEMU:** `make verify` prova kernel em **OVMF simulado** — saída serial do QEMU **não** conta como evidência de metal para esta etapa.
- **Artefato:** `build/baremetal-esp/EFI/BOOT/BOOTX64.EFI`, tar `build/ia-livre-esp.tar.gz`; imagem `.img` opcional com `mtools`.
- **Marcadores mínimos (serial):** `IA_LIVRE_BOOT_OK` (sucesso mínimo roadmap); ideal pós-ExitBoot: `IA_LIVRE_EXIT_BOOT_OK` e posteriores em COM1 ([`docs/kernel-pos-boot-services.md`](../../docs/kernel-pos-boot-services.md)).
- **Hipótese A vs B:** intocada; proibido `TOKENS_PER_S` / harness `COMPROVA` nesta etapa.
- **GGUF completo na USB:** fora de escopo (limites E30 permanecem).
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A** | Checklist + procedimento de captura serial; diretório/formato de evidência; gate valida log anexado **ou** `BAREMETAL_SKIP` honesto; QEMU explicitamente excluído | **Escolhida** |
| **B** | Exigir boot em metal no CI (runner com PC/USB) | **Rejeitada** — inviável e não portátil |
| **C** | Copiar/colar saída de `make verify` (QEMU) como evidência de metal | **Rejeitada** — fraude de ambiente |
| **D** | Só checklist manual sem gate de evidência | **Rejeitada** — não verificável no repositório |
| **E** | Reimplementar artefato ESP / mudar kernel BlockIO para metal | **Rejeitada** — E30 já fechou artefato; escopo errado |

### Escolha: **A — evidência serial anexada + skip honesto + gate que não confunde ambientes**

| Peça | Escolha nesta etapa |
|------|---------------------|
| Prova em metal | Log serial capturado em PC real (minicom/picocom/cu/screen documentado) |
| Sucesso mínimo | Presença de `IA_LIVRE_BOOT_OK` no log |
| Sucesso ideal | `IA_LIVRE_EXIT_BOOT_OK` (e opcionalmente marcadores COM1 posteriores) |
| Evidência no repo | Arquivo em `docs/evidence/boot-metal/` (git) **ou** path configurável + checksum do EFI usado |
| Sem hardware | `IA_LIVRE_BAREMETAL_SKIP=1` → exit 0 no trecho metal; `IMAGE_OK` **permanece obrigatório** |
| Com hardware | `IA_LIVRE_BAREMETAL_SKIP=0` + gate valida evidência (marcadores + SHA EFI alinhado ao artefato atual ou documentado) |
| Anti-fraude QEMU | Gate **rejeita** evidência que cite `qemu`/`OVMF` ou que não declare origem metal; **não** importa serial de `make run` |
| ADR 0011 | Preservado; aditivo apenas se necessário (evidência vs artefato) — preferir estender `boot-hardware-real.md` |

### Justificativa

- Fecha o critério do roadmap («evidência em PC real») sem obrigar metal no CI.
- Reutiliza artefato e gate E30; camada nova é **procedimento + validação de log**.
- Honestidade explícita: três níveis (QEMU / artefato / metal).

### Rejeitado (explícito)

- Tratar `make verify` como prova de hardware real.
- Emitir `IA_LIVRE_BAREMETAL_METAL_OK` (ou equivalente) só com `IMAGE_OK` ou só com QEMU.
- Exigir `TOKENS_PER_S`, harness comparable ou motor na Linha B.
- Secure Boot assinado, instalador, framebuffer, drivers USB complexos no kernel.
- Subir evidência sem marcadores mínimos ou com EFI SHA incompatível sem nota explícita.

## Fora de escopo

- Nova imagem ESP / alteração obrigatória do layout da mídia (salvo doc).
- Mudança obrigatória em `kernel/` para paths de disco em metal.
- GGUF completo (~638 MiB) na USB.
- Automação de gravação USB no CI.
- Prova da hipótese A vs B / alteração de veredito comparable.

## Critérios de aceite

- [ ] `docs/boot-hardware-real.md` (ou doc dedicado linkado) inclui: procedimento passo a passo de captura serial; pré-requisitos (Secure Boot, mídia, adaptador COM1); exemplos de comando host; o que **não** vale como evidência (QEMU).
- [ ] Formato de evidência definido: nome sugerido `boot-metal-serial-YYYYMMDD.txt` (ou `.log`); campos obrigatórios: data, modelo/firmware resumido, SHA256 do `BOOTX64.EFI` exercitado, trecho serial com marcadores.
- [ ] Diretório ou variável de evidência documentada (ex. `docs/evidence/boot-metal/` + `IA_LIVRE_BAREMETAL_EVIDENCE=…`).
- [ ] `scripts/verify-baremetal.sh` estendido: com `SKIP=0`, exige arquivo de evidência válido (contém `IA_LIVRE_BOOT_OK`; falha se ausente ou se indicadores de QEMU); com `SKIP=1`, comportamento E30 preservado.
- [ ] Marcadores de gate metal sugeridos e documentados: `IA_LIVRE_BAREMETAL_METAL_OK` (evidência válida) **ou** `IA_LIVRE_BAREMETAL_SKIP=1`; nunca ambos fingindo sucesso sem log.
- [ ] `AGENTS.md` — seção Como verificar distingue `make verify` (QEMU), `verify-baremetal` (artefato + evidência opcional), e checklist manual.
- [ ] Gates existentes (`make verify`, `verify-baremetal` com default skip) **não** regridem.
- [ ] Hipótese A vs B / `TOKENS_PER_S` **não** adulterados.
- [ ] README avaliado (`readme-por-fatia`).

### Tabela de ambientes (referência)

| Ambiente | Gate / ação | Prova |
|----------|-------------|-------|
| QEMU+OVMF | `make verify` | Kernel simulado |
| Host (artefato) | `make verify-baremetal` | `IMAGE_OK` |
| PC físico | Checklist + log anexado | ≥ `BOOT_OK` serial |
| CI sem PC | `BAREMETAL_SKIP=1` | Artefato only (honesto) |

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| Log QEMU colado como metal | Validador rejeita strings QEMU/OVMF; doc proíbe |
| Evidência stale (EFI antigo) | Exigir SHA no cabeçalho do log; gate compara com artefato buildado ou documenta mismatch |
| Operador sem USB-UART | Skip honesto; etapa ainda fecha com doc + gate artefato |
| Confundir `METAL_OK` com fecho da etapa no CI | Default `SKIP=1`; metal OK só em corrida explícita com evidência |

Rollback: reverter extensão do verify-baremetal e evidência; E30 permanece válida.

## Etapa do roadmap

Etapa 35 — Boot UEFI em hardware real (evidência serial)  
Issue: [#34](https://github.com/eriksonlima/projeto-ia-livre/issues/34) (ex-B28)  
Status roadmap: `em_andamento`  
Pronto quando: evidência em PC real com ≥ `BOOT_OK` (ideal `EXIT_BOOT_OK`) via serial; sem fingir CI de metal.