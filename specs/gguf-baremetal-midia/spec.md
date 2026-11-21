# Spec — GGUF canônico completo em mídia bare-metal (+ path I/O)

Etapa 36 · Issue [#35](https://github.com/eriksonlima/projeto-ia-livre/issues/35)  
Depende: E30 (artefato ESP), E35 (gate metal/SKIP).

---

## Resultado visível

O modelo canônico (TinyLlama 1.1B Q4_K_M, ~638 MiB) pode ser **incluído opcionalmente** na
mídia bare-metal (ESP/USB) via flag `IA_LIVRE_BAREMETAL_FULL_GGUF=1`, com gate que valida
presença, tamanho e SHA. O caminho I/O para o loader UEFI (SimpleFileSystem Protocol) é
**documentado** e os limites honestos (artefato ≠ boot metal; sem `TOKENS_PER_S`) são preservados.

Dois modos de entrega coexistem:

| Modo | Trigger | Validação |
|------|---------|-----------|
| **(a) ESP/tar completo** | `IA_LIVRE_BAREMETAL_FULL_GGUF=1` | GGUF presente na árvore `build/baremetal-esp/IA_LIVRE/` + tar ≥ 638 MiB + SHA confere |
| **(b) USB externo / path doc** | padrão (sem flag) | Protocolo `EFI_SIMPLE_FILE_SYSTEM_PROTOCOL` documentado em `docs/gguf-baremetal-midia.md`; checklist de montagem manual |

---

## Fora de escopo

- Inferência (`TOKENS_PER_S`) no kernel em bare-metal
- Motor de forward em freestanding na ESP
- Secure Boot / assinatura de código
- Partição separada / filesystem ext4/btrfs na ESP
- Inclusão automática do GGUF sem opt-in (`FULL_GGUF=1` obrigatório para o staging)
- Gravar automaticamente em dispositivo USB real (passo manual permanece)
- Gate `BAREMETAL_METAL_OK` sem log de PC (skip honesto preservado)

---

## Critérios de aceite

- [x] `docs/gguf-baremetal-midia.md` descreve os dois modos (a) e (b), path UEFI
  `EFI_SIMPLE_FILE_SYSTEM_PROTOCOL`, limites honestos e tabela de ambientes atualizada
- [x] `scripts/make-baremetal-esp.sh` com suporte a `IA_LIVRE_BAREMETAL_FULL_GGUF=1`:
  copia `models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf` → `build/baremetal-esp/IA_LIVRE/model.gguf`
  e emite `IA_LIVRE_BAREMETAL_GGUF_SIZE=<bytes>` + `IA_LIVRE_BAREMETAL_GGUF_SHA256=<sha>`
- [x] `scripts/verify-baremetal.sh` com gate GGUF quando `FULL_GGUF=1`:
  valida presença + tamanho ≥ 600 MiB + SHA confere → emite `IA_LIVRE_BAREMETAL_GGUF_OK`
- [x] Gate **sem** `FULL_GGUF=1` continua verde (`IMAGE_OK`) sem exigir GGUF
- [x] `README.txt` da ESP atualizado quando GGUF presente (menciona `model.gguf`)
- [x] `docs/boot-hardware-real.md` atualizado: seção "GGUF na mídia" com referência ao novo doc
- [x] `AGENTS.md` atualizado: referência ao doc + marcador `BAREMETAL_GGUF_OK`
- [x] `make verify-baremetal` continua passando com e sem `FULL_GGUF=1`

---

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| GGUF ausente quando `FULL_GGUF=1` | Script aborta com mensagem clara; gate FAIL honesto |
| Tar com 638 MiB excede espaço em CI | Modo opt-in; gate default não usa FULL_GGUF |
| SHA divergente entre staging e gate | Gate re-calcula na árvore `baremetal-esp/`; não confia só no tar |
| Confusão com `gguf.hdr` existente (4 KiB) | Arquivos distintos: `gguf.hdr` (4 KiB, sem flag) e `model.gguf` (completo, com flag) |

Rollback: flag opt-in; reversão trivial se necessário.

---

## Etapa do roadmap

- Etapa 36 `em_andamento` — GGUF canônico completo em mídia bare-metal (+ path I/O)
- Depende: E30 (`IMAGE_OK`) + E35 (`METAL_OK`/`SKIP`)
- Não prova hipótese A vs B; sem `TOKENS_PER_S`
