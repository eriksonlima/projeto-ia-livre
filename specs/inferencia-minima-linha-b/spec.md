# Spec — Inferência mínima / TOKENS_PER_S na Linha B (após loader)

## Resultado visível

Avanço **honesto** rumo à carga canônica na Linha B **sem** inventar `TOKENS_PER_S`:

1. **Fatia mínima da via A** — RAM QEMU suficiente + GGUF canônico **completo** no ESP + carga/parse stub de metadados/tensores no guest (além do prefixo 4 KiB da Etapa 26).
2. Bloqueio residual **mais preciso** documentado: `B_BLOCK=no_gguf_infer_engine` (loader + arquivo/path de modelo avançam; **motor** de geração ainda ausente).
3. Gates harness atualizados **sem** emitir `TOKENS_PER_S` / `LOAD_S` / `LOAD_KIND=gguf` fingidos; hipótese A vs B permanece **não** comprovada (`INCONCLUSIVO` no comparável).

Esta etapa **não** entrega geração TinyLlama no guest nem prova A vs B. Entrega a **primeira fatia** verificável do caminho A (infra + stub), com desfecho honesto se o motor continuar inviável no prazo da etapa.

## Contexto fixo (não reinventar)

- Etapa 26 **feita**: loader ESP `esp_header`; artefato `IA_LIVRE/gguf.hdr` = prefixo **4 KiB**; `GGUF_STATUS=header_ok`; `B_BLOCK=no_gguf_infer`; QEMU **`-m 256M`**; modelo completo ≈ **638 MiB** — **não cabe** na RAM atual. ADR [`0008`](../../docs/adr/0008-loader-gguf-esp-pre-exitboot.md).
- Contrato Linha B: [`docs/runtime-nativo-linha-b.md`](../../docs/runtime-nativo-linha-b.md) — proxy E12 + contrato E19/E20 + loader E26.
- Memória tipada: [`docs/memoria-scheduler-impl-minima.md`](../../docs/memoria-scheduler-impl-minima.md) — `Weights` / `KvCache` + Prefill/Decode.
- Harness: [`docs/harness-linha-a-b.md`](../../docs/harness-linha-a-b.md); comparável: [`docs/harness-a-b-comparavel.md`](../../docs/harness-a-b-comparavel.md) — com B sem GGUF real de geração → `INCONCLUSIVO`.
- Linha A (referência, **não** é B): `ia-livre-runtime` + llama.cpp no host ≈ ~13 tok/s; GGUF canônico TinyLlama Q4_K_M.
- Guest: kernel UEFI `#![no_std]` — **sem** llama.cpp; SimpleFileSystem tipicamente só em Boot Services.
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`; se não precisar, registrar.

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A** | Aumentar `-m` QEMU + GGUF completo no ESP + portar/integrar motor mínimo de inferência no guest | **Escolhida em fatia mínima** — motor completo é multi-etapa; **esta** etapa só a fatia infra+stub |
| **B** | Emitir `TOKENS_PER_S` de microbench de decode tipado **não** equivalente a TinyLlama | **Rejeitada** — confunde com carga canônica; projeto prefere não |
| **C** | Só renomear/documentar bloqueio (`no_gguf_infer_engine`) sem avançar RAM/arquivo | **Rejeitada como desfecho único** — fecha sem progresso rumo à carga real; o **nome** do bloqueio residual **é** adotado no fim da fatia A |
| **D** | Outro atalho “mínimo” (ex. host runtime rotulado como B) | **Rejeitada** — fraude de ambiente |

### Escolha: **A (fatia mínima desta etapa)**

| Peça | Escolha nesta etapa |
|------|---------------------|
| Objetivo | Avançar I/O/RAM/parse rumo a inferência real **ou**, se o motor ainda não existir ao fechar as tasks, deixar bloqueio honesto `no_gguf_infer_engine` |
| Ambiente B | QEMU / IA Livre — **não** host `ia-livre-runtime` |
| RAM QEMU | **Aumentar** `-m` o suficiente para o GGUF ≈638 MiB + overhead kernel/buffers (alvo documentado na Task 1, ex. `1024M` ou o mínimo medido) |
| Artefato ESP | GGUF canônico **completo** (não só `gguf.hdr` 4 KiB); path estável documentado (ex. `IA_LIVRE/model.gguf` ou evolução do staging script) |
| Leitura | Continuar ADR 0008: SimpleFileSystem **antes** de ExitBootServices → cópia/stream para região `Weights`/buffer documentado |
| Parse | Stub mínimo: magic + tabela/metadados de tensores (ou contagem/`tensor_info` documentado) — **sem** matmul/decode/geração de tokens |
| Motor de inferência | **Fora do mínimo obrigatório desta etapa** — candidato a etapa(s) seguinte(s); não portar llama.cpp inteiro aqui |
| `TOKENS_PER_S` / `LOAD_S` / `LOAD_KIND=gguf` | **Proibidos** nesta etapa sem geração real medido no guest |
| Bloqueio residual | Evoluir `no_gguf_infer` → **`no_gguf_infer_engine`** (path+RAM+arquivo/parse avançam; falta motor) |
| Hipótese A vs B | **Não** comprovada; **proibido** `COMPROVA` / declarar vitória |
| GPU / P2P / autonomy | **Fora** |
| ADR | Sim — curta (0009): fatia A mínima; rejeição explícita de B (tokens de microbench) e de fingir motor |

### Justificativa

- Geração TinyLlama Q4_K_M em `no_std` UEFI **não** cabe em uma etapa: falta motor (dequant, attention, tokenizer, sampling) e integração com o contrato Prefill/Decode.
- Inventar `TOKENS_PER_S` (opção B) quebraria o harness comparável e a honestidade da hipótese.
- Só C sem A deixaria o guest em 256M/prefixo 4 KiB — próximo passo de inferência real continuaria bloqueado por RAM/arquivo, não só por “engine”.
- Portanto E27 = **primeira fatia de A** (RAM + arquivo completo + stub) + desfecho honesto `no_gguf_infer_engine`. Etapas futuras: motor mínimo / tokens medidos / eventual `LOAD_KIND=gguf`.

### Rejeitado (explícito)

- Emitir `TOKENS_PER_S` / `LOAD_S` / `LOAD_KIND=gguf` / `MODEL=` TinyLlama como corrida completa sem motor+geração medidos no guest.
- Microbench tipado rotulado como tokens canônicos (opção B).
- Contar corrida host `ia-livre-runtime` como progresso de B.
- Declarar `COMPROVA` / hipótese comprovada.
- GPU manager, rede P2P, autonomy.
- Exigir port completo de llama.cpp ou geração 32 tokens nesta etapa.

### Contrato de marcadores (evolução)

Namespace kernel (serial COM1) + reemissão harness `IA_LIVRE_HARNESS_*`.

#### Progresso desta etapa (obrigatório)

| Marcador (kernel e/ou harness) | Significado |
|--------------------------------|-------------|
| Evidência de RAM/política QEMU | `-m` documentado e aplicado nos scripts de B/verify |
| Staging ESP do GGUF **completo** | Script/`make esp` coloca o arquivo canônico (não só 4 KiB) |
| `GGUF_NATIVE_LOADER=` | Evolui além de `esp_header` (ex. `esp_file` / `esp_full` — nome estável na Task 1) |
| `GGUF_STATUS=` | Além de `header_ok` (ex. `file_ok` / `tensors_stub_ok`) |
| Bytes / tamanho | `GGUF_BYTES=` coerente com carga além do prefixo (ou `GGUF_FILE_BYTES=` do arquivo no ESP) |
| Stub tensores | Marcador honesto (ex. `GGUF_TENSORS_STUB_OK` / `GGUF_TENSOR_COUNT=`) — **sem** claim de inferência |
| `B_BLOCK=` | **`no_gguf_infer_engine`** ao fechar (não permanecer só `no_gguf_infer` genérico se o bloqueio agora for o motor) |

#### Preservado / proibido

| Item | Regra |
|------|--------|
| Proxy E12 | Pode permanecer `LOAD_KIND=proxy` + `HARNESS_OK` do microbench |
| Contrato E19/E20 | `HARNESS_CONTRACT_*` / `CONTRACT_READY=1` preservados |
| `TOKENS_PER_S` / `LOAD_S` GGUF | **Proibido** sem geração real |
| Veredito comparável | Continua aceitando / exigindo `INCONCLUSIVO` enquanto B não tiver tokens em espécie |

### Relação com o gate atual

- Hoje: `GGUF_NATIVE_LOADER=esp_header`, `GGUF_STATUS=header_ok`, `B_BLOCK=no_gguf_infer`, sem `TOKENS_PER_S` em B.
- Nesta etapa o gate **atualiza** para exigir evidência de arquivo completo / loader evoluído / stub (conforme Task 1) e `B_BLOCK=no_gguf_infer_engine`.
- Continua **rejeitando** fraude de tokens; `make verify-harness-comparable` permanece `INCONCLUSIVO`.
- Timeouts: carga de ~638 MiB via FAT pode exigir `VERIFY_*_TIMEOUT` maior — documentar.

## Conteúdo obrigatório

### 1. Documentação + decisão (Task 1)

- Estender `docs/runtime-nativo-linha-b.md`: seção Etapa 27; escolha A fatia mínima; tabela RAM/ESP/loader/status/`B_BLOCK`; rejeição de B.
- Atualizar `docs/harness-linha-a-b.md` e ponte em `docs/harness-a-b-comparavel.md` se o bloqueio residual mudar o texto do slot B.
- ADR 0009 (ou próximo livre): fatia A; proibição de tokens de microbench; motor fora.
- `AGENTS.md`: Como rodar/verificar o novo estado B; nota de RAM/timeout.
- README: avaliar (`readme-por-fatia`).

### 2. Infra RAM + GGUF completo no ESP + carga guest (Task 2)

- Ajustar `-m` em Makefile/scripts QEMU/harness B.
- Staging do arquivo completo (fetch-model + esp-stage); documentar tamanho/path.
- Guest: ler além do prefixo (chunked ok) para buffer/`Weights`; marcadores de progresso; **sem** geração.

### 3. Parse stub de tensores (Task 3)

- Parse mínimo GGUF (metadados / contagem ou nomes de tensores stub) pós-carga ou durante; seed tipado se couber.
- Sem matmul / sampling / `TOKENS_PER_S`.

### 4. Harness + gate (Task 4)

- `run-harness-line-b.sh` / comparable: reemissão do novo loader/status/`B_BLOCK=no_gguf_infer_engine`.
- `verify-harness.sh` / `verify-boot.sh` / comparable alinhados; sem tokens inventados; docs/`AGENTS.md` finais.

## Fora de escopo

- Geração mínima com `TOKENS_PER_S` medidos na carga canônica (fica para etapa futura **após** motor)
- Port de llama.cpp / motor completo de transformer no guest
- Opção B (tokens de microbench tipado)
- Prova/refutação da hipótese (`COMPROVA`/`REFUTA`)
- GPU / CUDA / Vulkan / GPU manager
- libp2p / mudanças em `node/`
- Autonomy / mudanças em `agent/`
- Trocar a carga canônica da Linha A
- Filesystem maduro / multi-tenant / ABI estável além do necessário

## Critérios de aceite

- [ ] Decisão A (fatia mínima) documentada; B e fraude de ambiente rejeitadas por escrito
- [ ] QEMU `-m` suficiente para o GGUF completo + overhead, documentado e aplicado no caminho B
- [ ] GGUF canônico completo no ESP; guest lê além do prefixo 4 KiB com evidência serial
- [ ] Stub de parse de tensores/metadados com marcador honesto
- [ ] `B_BLOCK=no_gguf_infer_engine` (ou nome equivalente fixado na Task 1) no harness B
- [ ] Gate harness atualizado **sem** `TOKENS_PER_S` / `LOAD_KIND=gguf` fingido
- [ ] Comparável permanece `INCONCLUSIVO`; hipótese **não** comprovada
- [ ] Proxy E12 + contrato E19/E20 preservados onde couber
- [ ] `AGENTS.md` cobre o cenário; README avaliado
- [ ] Etapa pronta para o agente principal marcar `feita` após gate + revisor

## Riscos e rollback

- **Risco:** ESP `fat:rw` com ~638 MiB lento / timeout do gate → aumentar `VERIFY_*_TIMEOUT`; progresso serial; chunks.
- **Risco:** `-m` insuficiente ainda (overhead UEFI/mapa) → medir e documentar margem (ex. 1024M).
- **Risco:** pressão por `TOKENS_PER_S` nesta etapa → regra dura: sem motor+geração = sem tokens; fechar com `no_gguf_infer_engine`.
- **Risco:** parse GGUF incompleto (versão/endian) → stub mínimo + falha honesta serial se magic/estrutura inválida.
- **Rollback:** restaurar `-m 256M` + prefixo 4 KiB + `esp_header` / `no_gguf_infer`; docs de tentativa permanecem como registro.

## Etapa do roadmap

- Etapa 27 — Inferência mínima / TOKENS_PER_S na Linha B (após loader) (`em_andamento`)
- Issue: [#27](https://github.com/eriksonlima/projeto-ia-livre/issues/27)
- Spec: `specs/inferencia-minima-linha-b/`
- Pronto quando (roadmap): geração mínima na Linha B com a carga canônica (ou caminho intermediário documentado) emitindo `TOKENS_PER_S` / `LOAD_S` **medidos** comparáveis em espécie aos de A, **ou** bloqueio honesto novo documentado; gates harness atualizados sem inventar números; hipótese só deixa `INCONCLUSIVO` com evidência real; depende da Etapa 26 (loader).

> **Desfecho esperado desta spec:** caminho intermediário = fatia A (RAM+arquivo+stub) + **bloqueio honesto** `no_gguf_infer_engine` — cumpre o “ou” do Pronto quando **sem** fingir tokens. Geração com `TOKENS_PER_S` em espécie fica para etapa futura de motor.

> **Agente principal:** `Spec: specs/inferencia-minima-linha-b/` já aponta no `ROADMAP.md` da Etapa 27 — confirmar; não marcar a etapa `feita` aqui.
