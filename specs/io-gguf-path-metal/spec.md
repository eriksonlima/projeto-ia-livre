# Spec — I/O GGUF no path metal (além de `no_gguf_metal_io`)

Etapa 63 · Issue [#63](https://github.com/eriksonlima/projeto-ia-livre/issues/63) (ex-B57)  
Depende: E36 (FULL_GGUF / mídia bare-metal) · E48 / ADR [`0017`](../../docs/adr/0017-path-metal-sfs-vs-blockio.md) (`esp_sfs` + `B_BLOCK_METAL=no_gguf_metal_io`) · E44 (motor Decode subset em `runtime-native`, path BlockIO) · E62 (SKIP `METAL_OK` sem PC — **não** desbloqueado aqui).

---

## Resultado visível

No **path metal** (SimpleFileSystem / ESP — QEMU com FAT32 capaz de caber o GGUF canônico **ou** PC), o loader avança **além** do prefixo / bloqueio `no_gguf_metal_io`:

| Caminho | Condição | Esperado |
|---------|----------|----------|
| **A — I/O full (preferido)** | FAT32 (QEMU-espelho ou PC) com `IA_LIVRE/model.gguf` completo; leitura SFS → RAM tipada | `IA_LIVRE_GGUF_PATH=esp_sfs` + evidência de **loader full** (marcador tipo `GGUF_NATIVE_LOADER=…` / `GGUF_*_OK` **no path SFS**, distinto de `blockio_full`) **e/ou** geração mínima subset com marcadores medidos |
| **B — Bloqueio honesto (fallback)** | Após tentativa medida (FAT32 + full GGUF ou limites pós-ExitBoot / memória), I/O full continua inviável | ADR **nova** (sugerida `0023`) + gate atualizado que prova o bloqueio; **proibido** `TOKENS_PER_S` / `METAL_OK` fabricados |

**Regra dura:** `blockio_full` / serial BlockIO **≠** prova metal. **Não** exigir nem fabricar `IA_LIVRE_BAREMETAL_METAL_OK`. **Não** fingir `TOKENS_PER_S`. Pilar 1 permanece `BLOQUEIO_FINAL` (ADR 0022) — esta etapa **não** busca `COMPROVA`.

---

## Contexto fixo (não reinventar)

- **ADR 0017:** path metal = SFS/ESP (`GGUF_PATH=esp_sfs`); BlockIO QEMU ≠ metal; E48 fechou com `B_BLOCK_METAL=no_gguf_metal_io` porque FAT16 default (~516 MiB) &lt; TinyLlama (~638 MiB). O próprio ADR aponta **QEMU FAT32 futuro** / PC como caminho desejável para I/O full.
- **E36:** opt-in `IA_LIVRE_BAREMETAL_FULL_GGUF=1` coloca `model.gguf` na árvore/tar; img FAT precisa `IA_LIVRE_BAREMETAL_IMG_MB` ≥ ~700 — contrato em [`docs/gguf-baremetal-midia.md`](../../docs/gguf-baremetal-midia.md).
- **Gate atual:** `make verify-metal-infer` exige `esp_sfs` + `no_gguf_metal_io` e **falha** se aparecer `TOKENS` no path bloqueado ou `GGUF_PATH=blockio`.
- **E62:** `METAL_OK` SKIP neste host — **fora** do Pronto quando da E63.
- **Motor:** permanece em `runtime-native/` (ADR 0001); kernel = glue SFS + serial.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A — QEMU FAT32 + GGUF full + loader SFS full** | Imagem/ESP FAT32 com ~638 MiB; SimpleFileSystem lê `model.gguf` completo (ou o necessário ao subset) → handoff `runtime-native`; marcadores `esp_sfs` + loader full e/ou geração mínima | **Preferida** |
| **B — ADR + gate do bloqueio medido** | Se A falhar com evidência (tamanho FAT, I/O pós-Exit, OOM, timeout): ADR 0023 (ou nº livre) documenta inviabilidade; gate deixa de exigir só `no_gguf_metal_io` genérico e passa a exigir o bloqueio **novo** ou mantém/atualiza com motivo explícito | **Fallback aceitável** |
| **C — Exigir PC + METAL_OK** | Só conta com log de hardware real | **Rejeitada** para o Pronto quando — QEMU FAT32 basta; E62 cobre metal boot |
| **D — Reutilizar BlockIO como “metal”** | Emitir `esp_sfs` enquanto carrega via BlockIO | **Rejeitada** — fraude de path |
| **E — Inventar TOKENS / METAL_OK** | Métricas sem loop; `METAL_OK` sem evidência E35/E62 | **Rejeitada** |

### Escolha: **A preferida; B só com tentativa medida documentada**

| Peça | Nesta etapa |
|------|-------------|
| Path I/O | SFS/ESP (`\\IA_LIVRE\\model.gguf`) — prova ≠ BlockIO |
| Ambiente | QEMU FAT32 **suficiente**; PC opt-in |
| Sucesso A | Loader full SFS **ou** geração mínima subset no path `esp_sfs` (marcadores fixados na Task 1) |
| Fallback B | ADR nova + motivo ≠ “ainda não tentamos FAT32” |
| `METAL_OK` | **Intocado** |
| Harness A vs B / espécie canônica | **Não** reabrir; veredito permanece `INCONCLUSIVO` / pilar 1 `BLOQUEIO_FINAL` |
| Gate | Estender `verify-metal-infer` (ou sucessor documentado) para provar **A ou B**; default CI pode ser opt-in GGUF full se o ramo A exigir ~638 MiB |

### Justificativa

- Cumpre o “futuro” já previsto no ADR 0017 sem fingir que E48 já era I/O full.
- Permite CI/host sem PC (alinha E62 SKIP).
- Preserva honestidade: BlockIO continua prova Linha B harness, não metal.

### Rejeitado (explícito)

- `TOKENS_PER_S` / `LOAD_KIND=gguf` sem loop real no path SFS sob teste.
- `IA_LIVRE_BAREMETAL_METAL_OK` fabricado ou exigido.
- Tratar `GGUF_NATIVE_LOADER=blockio_full` como desfecho da E63.
- Espécie 22L×32 / `COMPROVA` / reabrir ADR 0022.
- TCP Rede no guest; GPU passthrough; embutir llama.cpp no kernel.

---

## Fora de escopo

- Fabricar `TOKENS_PER_S` ou `METAL_OK`.
- Tratar BlockIO (`blockio_full`) como prova metal.
- Espécie canônica / `COMPROVA` (pilar 1 já `BLOQUEIO_FINAL`).
- TCP Rede no guest; GPU passthrough.
- Autonomia/agente no SO; Secure Boot assinado.
- Alterar gates host (runtime/node/agent) salvo pontes textuais (ex. bridge `metal_block` se o marcador de bloqueio mudar).

---

## Critérios de aceite

### Comuns (sempre)

- [ ] Contrato atualizado (`gguf-baremetal-midia.md` e/ou doc E63 + ponte ADR 0017) descreve: tentativa FAT32/full; sucesso A vs fallback B; BlockIO ≠ metal; proibição de tokens fingidos e de `METAL_OK`.
- [ ] Marcadores serial fixados (loader full / geração mínima **ou** bloqueio ADR) — namespace `IA_LIVRE_*`.
- [ ] Gate (`make verify-metal-infer` estendido **ou** sucessor documentado) prova **A ou B**; **falha** se BlockIO for passado como metal ou se houver `TOKENS` sem geração no path SFS.
- [ ] `make verify` (BlockIO) **não** regride; harness comparable **não** força `COMPROVA`.
- [ ] `AGENTS.md` atualizado; `README.md` avaliado (`readme-por-fatia`).
- [ ] Motor permanece em `runtime-native/`.

### Caminho A — loader full e/ou geração mínima

- [ ] Artefato/imagem FAT32 (QEMU) ou PC com `model.gguf` completo utilizável via SFS.
- [ ] Serial: `GGUF_PATH=esp_sfs` + loader full (≠ `blockio_full`) **e/ou** geração mínima subset medida no mesmo path.
- [ ] Ausência de `B_BLOCK_METAL=no_gguf_metal_io` como único desfecho (ou substituição honesta por progresso documentado).
- [ ] Se emitir `TOKENS_PER_S` / `LOAD_S`: valores **medidos** no path SFS (não copiados do BlockIO).

### Caminho B — bloqueio / ADR honesto

- [ ] Tentativa medida documentada (FAT32 tentado? tamanho img? limite pós-Exit? evidência de falha).
- [ ] ADR nova (ex. `0023`) com status aceita/proposta e motivo estável.
- [ ] Gate exige o bloqueio documentado; **proibido** `TOKENS` / `METAL_OK` fabricados.
- [ ] Não reutilizar só o texto E48 sem avanço (“FAT16” sem tentar FAT32).

---

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| FAT32/`mtools`/OVMF frágil no host | Documentar deps; skip/opt-in honesto no gate A; fallback B com evidência |
| Timeout QEMU com GGUF ~638 MiB | Timeout documentado; subset de leitura + geração mínima; ou B |
| Confundir loader BlockIO com SFS | Marcadores `PATH`/`LOADER` distintos; gate rejeita `blockio` como metal |
| Bridge E49 ainda espera `no_gguf_metal_io` | Atualizar ponte se marcador mudar (Task 3) |
| Pressão por `METAL_OK` / `COMPROVA` | Critério escrito: E63 ≠ E62 ≠ pilar 1 |

Rollback: manter `verify-metal-infer` no desfecho E48 até o novo ramo estar verde; gates existentes intactos se o avanço for opt-in.

---

## Etapa do roadmap

- Etapa 63 `em_andamento` — I/O GGUF no path metal (além de `no_gguf_metal_io`)
- Pronto quando: no path metal (SFS/ESP — QEMU FAT32 ou PC), loader full **ou** geração mínima com marcadores; **ou** bloqueio/ADR honesto se I/O full continuar inviável; sem `TOKENS` fingidos; ≠ tratar BlockIO como metal; ≠ `METAL_OK` fabricado.
