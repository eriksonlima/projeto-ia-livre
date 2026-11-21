# Plan — I/O GGUF no path metal (Etapa 63)

## Abordagem

Desbloquear (ou documentar honestamente) I/O GGUF **além** de `no_gguf_metal_io` no caminho SFS/ESP, sem fingir que BlockIO é metal e sem exigir `METAL_OK`.

1. **Contrato + marcadores** — Estender docs (ponte ADR 0017); fixar o que conta como loader full / geração mínima no path `esp_sfs`; definir critérios medidos para fallback ADR 0023; listar deps FAT32/`mtools`/tamanho de img.
2. **Implementação A→B** — Preferir QEMU FAT32 + `FULL_GGUF` + glue SFS full → RAM → (opcional) `runtime-native` subset. Se inviável após tentativa medida: ADR nova + marcador de bloqueio honesto.
3. **Gate + pontes** — Atualizar `verify-metal-infer` (ou sucessor) para provar A **ou** B; `AGENTS.md`; avaliar README; ajustar bridge autonomia se o marcador metal mudar; não regredir `make verify`.

Ordem: Task 1 → Task 2 → Task 3. Task 2 escolhe o ramo com evidência; Task 3 fecha o gate do ramo escolhido.

## Arquivos prováveis

| Arquivo | Ação |
|---------|------|
| `docs/gguf-baremetal-midia.md` | estender — FAT32 / I/O full além E48; ponte E63 |
| `docs/adr/0017-…` | ponte “supersedido em parte” / ponte E63 (não reescrever história E48) |
| `docs/adr/0023-…` (nome a fixar) | **só se** ramo B — inviabilidade I/O full SFS após FAT32 |
| `docs/boot-hardware-real.md` / `runtime-nativo-linha-b.md` | pontes curtas (path metal ≠ BlockIO; ≠ METAL_OK) |
| `scripts/make-baremetal-esp.sh` / img FAT | FAT32 + `IMG_MB` ≥ ~700 para A |
| `kernel/src/main.rs` (e/ou loader SFS) | leitura full SFS; marcadores; **não** emitir `blockio` como metal |
| `runtime-native/` | reuso geração subset **se** dados SFS chegarem; sem inventar tokens |
| `scripts/verify-metal-infer.sh` (+ runner se necessário) | gate A ou B |
| `scripts/run-autonomia-bridge.sh` / docs bridge | só se marcador `B_BLOCK_METAL` mudar |
| `Makefile` / `AGENTS.md` | alvos e seção Como verificar |
| `README.md` | avaliar (`readme-por-fatia`) |
| `ROADMAP.md` / issue #63 | desfecho A ou B |

**Evitar tocar sem necessidade:** harness comparable veredito, evidência `METAL_OK` (E62), node/agent/runtime host (exceto pontes), espécie canônica / ADR 0022.

## Dependências

- E36: `FULL_GGUF` + contrato SFS na mídia
- E48 / ADR 0017: baseline `esp_sfs` + `no_gguf_metal_io` (ponto de partida)
- E44: motor Decode subset (reuso só no ramo A com dados na RAM)
- GGUF local (`./scripts/fetch-model.sh`) para ramo A
- QEMU/OVMF + preferencialmente `mtools` (img FAT32); PC **não** obrigatório
- E62: SKIP metal — não bloquear E63

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Regressão BlockIO (não é prova metal)
make verify

# Artefato com GGUF completo (ramo A)
./scripts/fetch-model.sh
IA_LIVRE_BAREMETAL_FULL_GGUF=1 IA_LIVRE_BAREMETAL_IMG_MB=700 make baremetal-esp

# Gate desta etapa — A (loader full / geração) OU B (bloqueio ADR)
make verify-metal-infer
# esperado: marcadores A ou B; sem TOKENS fingidos; sem METAL_OK; sem PATH=blockio como metal

# METAL_OK permanece E62 / SKIP
make verify-baremetal   # default SKIP → IMAGE_OK
```

Critério: exit 0 do gate metal-infer no desfecho A **ou** B **e** ausência de fraude BlockIO-as-metal / tokens inventados.
