# Spec — Inferência mínima no metal (GGUF ESP → geração ou bloqueio honesto)

Etapa 48 · Issue [#48](https://github.com/eriksonlima/projeto-ia-livre/issues/48) (ex-B42)  
Depende: E36 (FULL_GGUF / SimpleFileSystem) · E44 (Decode+`TOKENS_PER_S` no path BlockIO QEMU, subset) · E46 (SKIP metal) · E47 (writer USB).

---

## Resultado visível

Após boot com ESP/`model.gguf`, o caminho **nativo no path metal** (SimpleFileSystem / mídia ESP — **não** o disco raw BlockIO do harness QEMU atual) emite **geração mínima verificável** **ou** um **bloqueio honesto** documentado (`B_BLOCK`/`metal`), **sem** `TOKENS_PER_S` fingido e **sem** inventar `METAL_OK`.

A prova **não exige PC físico** se existir **QEMU-espelho** do path ESP/SimpleFileSystem (ou equivalência documentada e exercitada no gate). PC real permanece opt-in / evidência futura — fora do mínimo desta etapa.

| Caminho | Condição | Esperado |
|---------|----------|----------|
| **A — Geração mínima (path metal)** | I/O GGUF via SFS/ESP (QEMU-espelho ou PC) alimenta `runtime-native` | Marcadores de geração mínima (subset ok) **medidos**; `LOAD_KIND=gguf` só com loop real; `B_BLOCK` omitido **ou** residual preciso ≠ “path metal ausente” |
| **B — Bloqueio honesto** | I/O GGUF no path metal inviável após tentativa documentada | `B_BLOCK` **novo** metal-específico (ex. `no_gguf_metal_io` / `B_BLOCK_METAL=…`) + gate prova o bloqueio; **proibido** `TOKENS_PER_S` |

**Regra dura:** QEMU BlockIO (`GGUF_NATIVE_LOADER=blockio_full`, E26–E44) **≠** path metal. Não reutilizar serial BlockIO como prova de metal. Não emitir `IA_LIVRE_BAREMETAL_METAL_OK` nesta etapa.

---

## Contexto fixo (não reinventar)

- **E44:** Decode + `TOKENS_PER_S` medidos no guest QEMU via **BlockIO** raw; espécie subset (`2L×1`); `LOAD_KIND=gguf`; hipótese A vs B permanece **INCONCLUSIVO**.
- **E36:** `IA_LIVRE/model.gguf` na ESP via `FULL_GGUF=1`; contrato I/O **`EFI_SIMPLE_FILE_SYSTEM_PROTOCOL`** em [`docs/gguf-baremetal-midia.md`](../../docs/gguf-baremetal-midia.md). Doc já diz: QEMU BlockIO ≠ path em PC.
- **Kernel hoje:** loader completo prioriza BlockIO para caber GGUF ~638 MiB (FAT16 QEMU limitado); path ESP/`esp_file` é parcial / legado.
- **E46:** sem PC neste host → `SKIP=1`; `METAL_OK` pendente. **E47:** writer USB ≠ metal ≠ inferência.
- **ADR 0001 / 0010:** motor em `runtime-native/`; kernel = glue/serial.
- Hipótese A vs B / harness comparable: **não** forçar `COMPROVA`; espécie metal/subset pode permanecer `INCONCLUSIVO`.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A — QEMU-espelho SFS/ESP + geração mínima** | Boot QEMU a partir de ESP/FAT (ou equivalente) com `model.gguf`; loader SimpleFileSystem → RAM → `runtime-native` (reuso subset E44); emite geração mínima **ou** bloqueio se I/O falhar | **Preferida** |
| **B — Só docs + gate do bloqueio** | Se A inviável: documentar divergência + emitir/exigir `B_BLOCK` metal-específico no gate **sem** inventar tokens | **Fallback aceitável** |
| **C — Exigir PC físico + METAL_OK** | Inferência só conta com log de PC | **Rejeitada** para o Pronto quando — QEMU-espelho basta; E46 já cobre metal boot |
| **D — Tratar BlockIO como metal** | Reusar serial E44 como “inferência no metal” | **Rejeitada** — fraude de path |
| **E — Inventar TOKENS / METAL_OK** | Métricas sem loop; `METAL_OK` sem evidência E46 | **Rejeitada** |

### Escolha: **A preferida; B só com inviabilidade documentada**

| Peça | Nesta etapa |
|------|-------------|
| Path I/O | SimpleFileSystem / árvore ESP (`\\IA_LIVRE\\model.gguf`) — **não** BlockIO raw como prova |
| Ambiente de prova | QEMU-espelho do path metal **suficiente**; PC opcional |
| Motor | `runtime-native/` (reuso Prefill/Decode subset E43/E44 se dados chegarem à RAM tipada) |
| Kernel | Glue: descobrir volume → ler GGUF (parcial ou full conforme viável) → handoff; serial honesto |
| Sucesso A | Geração mínima (≥1 token real / subset documentado) + marcadores; **sem** `B_BLOCK` de “path metal” |
| Fallback B | `B_BLOCK` metal-específico (nome fixado na Task 1) + doc + gate; **sem** `TOKENS_PER_S` |
| Equivalência | Se QEMU-espelho ≠ bit-a-bit PC: documentar diferenças (FAT size, ExitBoot, serial) e o que o gate **prova** vs o que fica opt-in metal |
| ADR | Novo ADR **somente** se a escolha QEMU-espelho vs BlockIO / marcadores metal for decisão estrutural estável (sugerido na Task 1) |
| `METAL_OK` | **Intocado** — continua E35/E46 |
| Harness A vs B v1 | Não substituir; gate metal/espelho é **adicional** (ou extensão baremetal documentada) |

### Justificativa

- Fecha o buraco E36→inferência sem fingir que BlockIO = USB.
- Permite CI/host sem PC (alinha E46 SKIP).
- Preserva honestidade de métricas (E44/ADR 0015).

### Rejeitado (explícito)

- `TOKENS_PER_S` / `LOAD_KIND=gguf` sem loop de geração real no path sob teste.
- Emitir `IA_LIVRE_BAREMETAL_METAL_OK` ou fingir evidência de PC.
- Declarar hipótese A vs B comprovada só com subset metal.
- Embutir llama.cpp no kernel; host-as-B como prova metal.
- Exigir 22L×32 canônico nesta etapa (subset E44 ok se documentado).

---

## Fora de escopo

- Boot metal real / `METAL_OK` (E46).
- Writer USB (E47) — só consumo do artefato ESP.
- Prefill/Decode 22L×32 canônico; veredito `COMPROVA` no comparable.
- GPU nativa; autonomia no SO (B43); rede no SO.
- Secure Boot assinado; FAT32 redesign completo além do necessário ao espelho.
- Alterar gates host (runtime/node/agent) salvo pontes textuais.

---

## Critérios de aceite

### Comuns (sempre)

- [ ] Documento de contrato (novo ou extensão de `gguf-baremetal-midia.md` / `boot-hardware-real.md` / `runtime-nativo-linha-b.md`) descreve: path metal = SFS/ESP; BlockIO ≠ metal; QEMU-espelho como prova desta etapa; tabela sucesso A vs bloqueio B; proibição de tokens fingidos e de `METAL_OK` nesta etapa.
- [ ] Marcadores serial fixados (sucesso vs `B_BLOCK`/`B_BLOCK_METAL`) — namespace `IA_LIVRE_*` coerente com o restante do projeto.
- [ ] Gate automatizado (novo `make verify-…` **ou** extensão documentada de baremetal/verify) prova **A ou B**; default CI **não** exige PC nem GGUF 638 MiB se o ramo B for o desfecho (ou opt-in claro).
- [ ] `make verify` (BlockIO/QEMU atual) **não** regride; harness comparable **não** força `COMPROVA`.
- [ ] `AGENTS.md` atualizado (como rodar / como verificar); `README.md` avaliado (`readme-por-fatia`).
- [ ] Motor permanece em `runtime-native/` (ADR 0001).

### Caminho A — geração mínima

- [ ] QEMU (ou PC) boota ESP com `model.gguf`; loader path metal carrega o suficiente para o motor.
- [ ] Serial: geração mínima real (marcadores Decode/native alinhados ao subset) **sem** `B_BLOCK` de I/O metal.
- [ ] Se emitir `TOKENS_PER_S` / `LOAD_S`: valores **medidos** no path sob teste (não copiados do BlockIO).

### Caminho B — bloqueio honesto

- [ ] Tentativa de path metal documentada (por que inviável: FAT size, pós-ExitBoot, memória, etc.).
- [ ] `B_BLOCK` metal-específico **≠** reutilizar só `no_gguf_path` / motivos BlockIO sem avanço.
- [ ] Gate exige o marcador de bloqueio (e **falha** se aparecer `TOKENS_PER_S` sem geração).
- [ ] **Ausência** de `METAL_OK` fabricado.

---

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| FAT16 QEMU não cabe ~638 MiB | Espelho com FAT32/`mtools` img maior; ou leitura parcial + B_BLOCK se full inviável; ou bloquear honesto |
| Confundir gate BlockIO com metal | Marcadores/`LOADER=` distintos; gate separado; docs explícitos |
| Timeout QEMU com GGUF full | Subset + opt-in; timeout documentado; fallback B |
| Pressão por `METAL_OK` | Critério escrito: E48 ≠ E46 |
| Tokens “herdados” do path BlockIO | Proibido; path sob teste deve emitir a métrica |

Rollback: flag/opt-in do espelho; gates existentes intactos se o novo gate for adicional.

---

## Etapa do roadmap

- Etapa 48 `em_andamento` — Inferência mínima no metal (GGUF ESP → geração ou bloqueio honesto)
- Pronto quando: no PC (**ou QEMU espelhando path metal**), após boot USB/ESP com `model.gguf`, caminho nativo emite geração mínima **ou** `B_BLOCK`/`metal` honesto documentado; sem `TOKENS_PER_S` fingido.
