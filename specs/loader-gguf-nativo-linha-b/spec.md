# Spec — Loader GGUF nativo mínimo na Linha B (desbloquear `no_gguf_path`)

## Resultado visível

Caminho **verificável** para bytes (ou pelo menos o **cabeçalho**) do GGUF canônico chegarem ao ambiente **Linha B** (QEMU / IA Livre pós-caminho de boot), com I/O mínimo **documentado** e evidência de progresso do loader:

- `IA_LIVRE_HARNESS_GGUF_NATIVE_LOADER` **≠** `absent`, **ou**
- marcadores intermediários honestos no serial/harness que provem leitura/progresso (ex. magic GGUF, bytes lidos, estágio `header_ok` / `bytes_ok`).

O bloqueio atual `B_BLOCK=no_gguf_path` (Etapa 21) é **substituído ou evoluído** para um estado que reflita o avanço real do loader — **sem** inventar `TOKENS_PER_S` / `LOAD_S` GGUF e **sem** declarar a hipótese A vs B comprovada.

Proxy Etapa 12 (`LOAD_KIND=proxy`) e contrato Etapa 19 (`MEM_SCHED` / `HARNESS_CONTRACT_*`) **permanecem**; esta etapa **não** exige inferência completa nem `LOAD_KIND=gguf` com geração.

## Contexto fixo (não reinventar)

- Bloqueio atual: [`docs/runtime-nativo-linha-b.md`](../../docs/runtime-nativo-linha-b.md) — `B_BLOCK=no_gguf_path`, `GGUF_NATIVE_LOADER=absent`, `GGUF_STATUS=blocked`, `CONTRACT_READY=1`.
- Contrato memória (Etapa 19): [`docs/memoria-scheduler-impl-minima.md`](../../docs/memoria-scheduler-impl-minima.md) — `Weights` / `KvCache` + Prefill/Decode.
- Harness: [`docs/harness-linha-a-b.md`](../../docs/harness-linha-a-b.md); scripts `run-harness-line-b.sh` / `verify-harness.sh`.
- Modelo canônico (host, gitignored): TinyLlama 1.1B Chat v1.0 Q4_K_M ≈ 638 MiB em `models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf` (`./scripts/fetch-model.sh`).
- Guest hoje: ESP via `make esp` + QEMU `-drive … fat:rw:build/esp` com **`-m 256M`** (insuficiente para mapear o GGUF inteiro em RAM — o mínimo desta etapa pode ser **cabeçalho / prefixo**, não os 638 MiB residindo no guest).
- Spec anterior (bloqueio): [`specs/carga-gguf-linha-b/`](../carga-gguf-linha-b/) — Etapa 21 **feita** com desfecho honesto `no_gguf_path`.
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`; se não precisar, registrar.

## Decisão de desenho (única — obrigatória)

| Peça | Escolha nesta etapa |
|------|---------------------|
| Objetivo | Desbloquear `no_gguf_path` com **loader nativo mínimo** + evidência verificável |
| Ambiente B | QEMU / IA Livre — **não** host `ia-livre-runtime` (isso continua Linha A) |
| Mecanismo de I/O (canônico) | **ESP (FAT já usado pelo boot)** — copiar artefato GGUF (arquivo completo **ou** prefixo/cabeçalho documentado) para `build/esp/` no host; ler no guest via protocolo UEFI de arquivo **antes** de ExitBootServices (SimpleFileSystem típico só em Boot Services), copiar bytes para região `Weights` (ou buffer documentado); pós-ExitBoot só **evidência**/uso da cópia já feita |
| Alternativas rejeitadas no v1 | **fw_cfg** e **virtio-blk/fs** — só se ESP for inviável no host de referência; nesse caso ADR + doc obrigatórios **antes** de implementar |
| Mínimo de bytes | Cabeçalho GGUF válido (magic `GGUF` + campos mínimos documentados) **ou** prefixo N KiB documentado; arquivo completo no ESP é desejável mas **não** exige carregar 638 MiB na RAM de 256M |
| RAM QEMU | Manter 256M se o mínimo for cabeçalho/prefixo; aumentar `-m` **só** se a task de I/O precisar e estiver documentado (sem fingir inferência) |
| Destino tipado | Preferir alocação/`Weights` do contrato E19 quando couber; se só cabeçalho couber, documentar buffer mínimo + ponte para `Weights` futura |
| Marcadores | `GGUF_NATIVE_LOADER` deixa de ser `absent`; estados honestos (ex. `esp_header`, `esp_prefix`, `esp_bytes`) + marcadores serial kernel |
| `TOKENS_PER_S` / geração | **Proibidos** nesta etapa (ficam para etapa futura de inferência em B) |
| Hipótese A vs B | **Não** comprovada; veredito comparável pode permanecer `INCONCLUSIVO` |
| GPU / libp2p / autonomy | **Fora** |
| ADR | Sim, **curta**, se a fatia 1 confirmar ESP-pré-ExitBoot como escolha estrutural (ou se pivô para fw_cfg/virtio) |

### Rejeitado (explícito)

- Inventar `TOKENS_PER_S` / `LOAD_S` / `LOAD_KIND=gguf` com geração sem motor de inferência.
- Declarar hipótese comprovada / `COMPROVA` só porque o loader leu bytes.
- Contar corrida host de `ia-livre-runtime` como progresso do loader B.
- Implementar GPU manager, rede P2P ou autonomia nesta etapa.
- Exigir TinyLlama **inteiro** em RAM guest se `-m 256M` (ou política documentada) não permitir — usar cabeçalho/prefixo honesto.
- Deixar `GGUF_NATIVE_LOADER=absent` com gate ainda exigindo `absent` após o loader existir (gate deve acompanhar o contrato novo).

### Contrato de marcadores (evolução)

Namespace kernel (serial COM1) + reemissão harness `IA_LIVRE_HARNESS_*`.

#### Progresso do loader (obrigatório — pelo menos um caminho)

| Marcador (kernel e/ou harness) | Significado |
|--------------------------------|-------------|
| `IA_LIVRE_GGUF_LOADER_BEGIN` (ou equivalente documentado) | Início do caminho de I/O |
| `IA_LIVRE_GGUF_MAGIC_OK` / evidência de magic `GGUF` | Cabeçalho reconhecido |
| `IA_LIVRE_GGUF_BYTES=` ou `IA_LIVRE_GGUF_HEADER_OK` | Bytes/cabeçalho lidos com sucesso |
| `IA_LIVRE_HARNESS_GGUF_NATIVE_LOADER=<estado>` | Estado ≠ `absent` (ex. `esp_header`, `esp_prefix`, `esp_partial`) |
| `IA_LIVRE_HARNESS_GGUF_STATUS=` | Evolui de `blocked` puro: ex. `loader_partial` / `header_ok` (nome estável documentado na Task 1) |
| `IA_LIVRE_HARNESS_B_BLOCK=` | **Não** permanece `no_gguf_path` se o path existir; usar motivo novo só se ainda houver bloqueio residual (ex. `no_gguf_infer` para ausência de geração) **ou** omitir `B_BLOCK` de path se o desbloqueio for completo para o critério desta etapa |

#### Preservado / proibido

| Item | Regra |
|------|--------|
| Proxy E12 | Pode permanecer `LOAD_KIND=proxy` + `HARNESS_OK` do microbench |
| Contrato E19/E20 | `HARNESS_CONTRACT_*` / `CONTRACT_READY=1` preservados |
| `TOKENS_PER_S` / `LOAD_S` GGUF | **Proibido** sem geração/carga de inferência real |
| `MODEL=` TinyLlama como se inferiu | Só se documentado como **alvo** (`GGUF_TARGET_*`), não como corrida completa |

### Relação com o gate atual

- Hoje `make verify-harness` **exige** `GGUF_NATIVE_LOADER=absent` + `B_BLOCK=no_gguf_path` + `GGUF_STATUS=blocked`.
- Nesta etapa o gate **atualiza** para exigir evidência de loader (estado ≠ `absent` + marcadores acordados) e **deixa** de exigir o trio de bloqueio E21 como sucesso.
- Continua rejeitando fraude de `TOKENS_PER_S` / `LOAD_KIND=gguf` fingido.
- `make verify` (kernel) deve cobrir marcadores serial do loader se forem emitidos no EFI.
- Hipótese **não** comprovada na mensagem/docs do gate.

## Conteúdo obrigatório

### 1. Documentação + decisão I/O (Task 1)

- Estender [`docs/runtime-nativo-linha-b.md`](../../docs/runtime-nativo-linha-b.md): seção “loader GGUF nativo mínimo”; mecanismo ESP-pré-ExitBoot; tabela `GGUF_NATIVE_LOADER` / `GGUF_STATUS` / evolução de `B_BLOCK`; limite RAM vs arquivo 638 MiB; proibição de `TOKENS_PER_S`.
- Atualizar [`docs/harness-linha-a-b.md`](../../docs/harness-linha-a-b.md): slot B passa a ter loader parcial ≠ ausência de path.
- ADR curta em `docs/adr/` (ESP canônico; fw_cfg/virtio rejeitados no v1) **ou** seção decisória suficiente no doc de runtime se ADR for redundante — preferir ADR se a escolha for estrutural.
- Ponte em `docs/architecture.md` se ainda disser só `no_gguf_path` sem loader.
- `AGENTS.md`: Como rodar / verificar o novo estado B.
- README: avaliar (`readme-por-fatia`).

### 2. I/O guest (Task 2)

- Host: incluir artefato GGUF (completo ou prefixo documentado) no ESP (`Makefile` / script de `esp` / harness prep).
- Guest: ler via UEFI file protocol em Boot Services → copiar para buffer/`Weights` → emitir marcadores; **não** depender de SimpleFileSystem após ExitBoot sem documentar alternativa.
- Sem motor de decode/prefill de tokens.

### 3. Marcadores + harness (Task 3)

- Kernel emite progresso; `run-harness-line-b.sh` reemite `GGUF_NATIVE_LOADER` ≠ `absent` e status coerente.
- Proxy + contrato preservados; sem `TOKENS_PER_S`.

### 4. Gate (Task 4)

- `verify-harness.sh` / `make verify-harness` (e `make verify` se marcadores forem do kernel) alinhados ao contrato novo.
- Falha se `absent` + path prometido; falha se métricas inventadas; docs/`AGENTS.md` finais.

## Fora de escopo

- Inferência completa / geração / `TOKENS_PER_S` em B (candidato B21 / etapa futura)
- Prova ou refutação da hipótese A vs B (`COMPROVA`/`REFUTA`)
- GPU / CUDA / Vulkan / GPU manager
- libp2p / mudanças em `node/`
- Autonomy / mudanças em `agent/` além do necessário
- Filesystem maduro, multi-tenant, ABI estável além do I/O mínimo
- Trocar a carga canônica da Linha A

## Critérios de aceite

- [ ] Mecanismo de I/O escolhido e documentado (ESP preferido; ADR/doc se estrutural)
- [ ] Bytes/cabeçalho GGUF canônico (ou prefixo documentado) chegam ao guest Linha B por caminho verificável
- [ ] Evidência serial/harness: `GGUF_NATIVE_LOADER` ≠ `absent` **ou** marcadores intermediários honestos equivalentes
- [ ] `B_BLOCK=no_gguf_path` não permanece como sucesso do gate se o path foi desbloqueado
- [ ] Gate harness atualizado **sem** inventar `TOKENS_PER_S` / `LOAD_S` GGUF
- [ ] Proxy E12 + contrato E19/E20 preservados onde couber
- [ ] Hipótese A vs B **não** declarada comprovada
- [ ] `AGENTS.md` cobre o cenário; README avaliado
- [ ] Etapa pronta para o agente principal marcar `feita` após gate + revisor

## Riscos e rollback

- **Risco:** SimpleFileSystem indisponível pós-ExitBoot → mitigação: ler em Boot Services e copiar para RAM tipada **antes** de `ExitBootServices`.
- **Risco:** GGUF 638 MiB vs `-m 256M` → aceitar cabeçalho/prefixo; não fingir modelo completo em memória.
- **Risco:** ESP `fat:rw` lento/grande com arquivo completo → prefixo no ESP + doc; ou aumentar disco/RAM só com documentação.
- **Risco:** gate antigo exige `absent` → Task 4 atualiza verificadores na mesma etapa.
- **Risco:** pressão por `TOKENS_PER_S` → regra dura: sem geração = sem tokens.
- **Rollback:** restaurar `GGUF_NATIVE_LOADER=absent` + `B_BLOCK=no_gguf_path` no harness/gate; reverter cópia ESP/kernel; docs de tentativa permanecem como registro.

## Etapa do roadmap

- Etapa 26 — Loader GGUF nativo mínimo na Linha B (desbloquear `no_gguf_path`) (`em_andamento`)
- Issue: [#26](https://github.com/eriksonlima/projeto-ia-livre/issues/26)
- Spec: `specs/loader-gguf-nativo-linha-b/`
- Pronto quando (roadmap): caminho verificável para o GGUF canônico (ou bytes/cabeçalho do modelo) chegar ao ambiente Linha B (QEMU/IA Livre pós-ExitBoot) com I/O mínimo documentado e evidência de progresso do loader (`GGUF_NATIVE_LOADER` ≠ `absent` ou marcadores intermediários honestos); gate harness atualizado sem inventar `TOKENS_PER_S` se ainda não houver geração; hipótese **não** comprovada; sem inferência completa obrigatória nesta etapa; sem GPU manager.

> **Agente principal:** `Spec: specs/loader-gguf-nativo-linha-b/` já consta no `ROADMAP.md` da Etapa 26 — confirmar após merge desta pasta; não marcar a etapa `feita` aqui.
