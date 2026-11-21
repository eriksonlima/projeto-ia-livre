# Plan — GGUF canônico completo em mídia bare-metal (+ path I/O)

Etapa 36 · Spec: `specs/gguf-baremetal-midia/`

---

## Abordagem

Três fatias verticais, da menor dependência para a maior:

### Fatia 1 — Contrato e doc
Criar `docs/gguf-baremetal-midia.md` com:
- Modos (a) ESP/tar + flag e (b) USB externo / path doc
- Protocolo UEFI de acesso ao GGUF: `EFI_SIMPLE_FILE_SYSTEM_PROTOCOL` → `OpenVolume` →
  `Open(L"IA_LIVRE\\model.gguf")` → `Read` em blocos (BlockIO ou FileIO)
- Tabela de ambientes atualizada (QEMU / artefato / PC real + GGUF)
- Checklist de staging manual (cp para USB, path esperado `IA_LIVRE/model.gguf`)
- Limites honestos: sem `TOKENS_PER_S`, sem motor nesta etapa

Atualizar `docs/boot-hardware-real.md`: adicionar seção "GGUF na mídia" apontando para o novo doc.

### Fatia 2 — Script de staging + gate de artefato (tamanho/SHA)
Estender `scripts/make-baremetal-esp.sh`:
- Se `IA_LIVRE_BAREMETAL_FULL_GGUF=1` e GGUF presente → copiar para
  `$OUT_DIR/IA_LIVRE/model.gguf`; emitir `GGUF_SIZE` + `GGUF_SHA256`
- Se `FULL_GGUF=1` mas GGUF ausente → abortar com mensagem clara
- Se `FULL_GGUF=1` → atualizar `README.txt` da ESP mencionando `model.gguf`

Estender `scripts/verify-baremetal.sh`:
- Se `FULL_GGUF=1`: checar `IA_LIVRE/model.gguf` na árvore; tamanho ≥ 600 MiB;
  SHA coincide com cálculo ao vivo → emitir `IA_LIVRE_BAREMETAL_GGUF_OK`
- Se `FULL_GGUF=0` (default): pular validação GGUF; `IMAGE_OK` inalterado
- Atualizar `AGENTS.md` + checar grep em `verify-baremetal.sh`

### Fatia 3 — Glue loader + atualização final de docs
Atualizar `docs/gguf-baremetal-midia.md` com exemplo de pseudocódigo/Rust do loader UEFI
(seção "Glue loader") descrevendo:
- Descoberta de volume via `LocateProtocol(EFI_SIMPLE_FILE_SYSTEM_PROTOCOL_GUID)`
- Abertura do arquivo `IA_LIVRE\model.gguf`
- Leitura do header GGUF (magic + version) para validação antes de qualquer I/O pesado
- Fallback documentado: se arquivo ausente → emite `GGUF_BAREMETAL_PATH=absent` (honesto)

Atualizar `AGENTS.md` com referência completa ao doc e ao gate `BAREMETAL_GGUF_OK`.

Verificar README.md: mudança é interna (gate + script); capa GitHub não precisa mudar.

---

## Arquivos prováveis

| Arquivo | Ação |
|---------|------|
| `docs/gguf-baremetal-midia.md` | criar (Fatia 1 + Fatia 3) |
| `docs/boot-hardware-real.md` | atualizar — seção GGUF (Fatia 1) |
| `scripts/make-baremetal-esp.sh` | estender — flag FULL_GGUF (Fatia 2) |
| `scripts/verify-baremetal.sh` | estender — gate GGUF_OK (Fatia 2) |
| `AGENTS.md` | atualizar — marcador + doc (Fatia 2 + 3) |
| `docs/evidence/boot-metal/README.md` | atualizar — nota GGUF (Fatia 3, opcional) |

**Fora de toque nas fatias:**
- Código de produto do kernel (`kernel/src/main.rs`)
- `runtime-native/`, `runtime/`, `node/`, `agent/`
- Gates existentes: `verify`, `verify-runtime`, `verify-node`, `verify-agent`, `verify-harness`

---

## Dependências

- `scripts/fetch-model.sh` já existente e GGUF local em `models/` (gitignored)
- `scripts/make-baremetal-esp.sh` e `scripts/verify-baremetal.sh` já existentes (E30/E35)
- `docs/boot-hardware-real.md` já existente (E30/E35)

---

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Gate padrão (sem GGUF) — deve continuar verde
make verify-baremetal

# Gate com GGUF (requer modelo local)
./scripts/fetch-model.sh
IA_LIVRE_BAREMETAL_FULL_GGUF=1 make verify-baremetal

# Checar marcadores nos scripts
grep -q 'IA_LIVRE_BAREMETAL_GGUF_OK' scripts/verify-baremetal.sh
grep -q 'IA_LIVRE_BAREMETAL_FULL_GGUF' scripts/make-baremetal-esp.sh
grep -q 'IA_LIVRE_BAREMETAL_GGUF_OK' AGENTS.md
test -f docs/gguf-baremetal-midia.md
```
