# Plan — Inferência mínima no metal (Etapa 48)

## Abordagem

Fechar a lacuna **ESP/SimpleFileSystem → motor nativo** sem fingir que o path BlockIO (E44) é metal.

1. **Contrato + marcadores** — Documentar divergência BlockIO vs SFS/ESP; definir QEMU-espelho como prova suficiente do Pronto quando; fixar marcadores de sucesso (geração mínima) vs `B_BLOCK` metal-específico; ADR só se a decisão for estrutural.
2. **Implementação A→B** — Preferir QEMU bootando ESP/FAT com `model.gguf` + glue SFS → RAM → `runtime-native` (reuso subset Decode E44). Se I/O metal inviável após tentativa: emitir bloqueio honesto (sem tokens).
3. **Gate + pontes** — Script/`make verify-*` que prova A **ou** B; atualizar `AGENTS.md`; avaliar README; não tocar `METAL_OK` / não regredir `make verify`.

Ordem: Task 1 → Task 2 → Task 3. Task 2 escolhe o ramo A vs B com evidência; Task 3 fecha o gate do ramo escolhido.

## Arquivos prováveis

| Arquivo | Ação |
|---------|------|
| `docs/gguf-baremetal-midia.md` | estender — path metal vs BlockIO; QEMU-espelho; ponte E48 |
| `docs/boot-hardware-real.md` | ponte curta E48 (inferência ≠ METAL_OK) |
| `docs/runtime-nativo-linha-b.md` | nota path metal / loader distinto |
| `docs/adr/0017-…` (nome a fixar) | **só se** Task 1 decidir ADR (QEMU-espelho / B_BLOCK metal) |
| `kernel/src/main.rs` (e/ou módulo loader) | glue SFS/ESP metal; marcadores; **não** fingir BlockIO=metal |
| `runtime-native/` | reuso geração subset se dados chegarem; sem inventar tokens |
| `scripts/make-baremetal-esp.sh` / img FAT | suporte espelho (FAT32 / tamanho) se necessário ao A |
| `scripts/run-qemu-*.sh` ou novo runner espelho | boot QEMU a partir de ESP/img com `model.gguf` |
| `scripts/verify-*.sh` + `Makefile` | gate A ou B (`IA_LIVRE_*_OK` ou exigência de `B_BLOCK` metal) |
| `AGENTS.md` | Como rodar / Como verificar |
| `README.md` | avaliar (`readme-por-fatia`) |
| `ROADMAP.md` / issue #48 | desfecho A ou B |

**Evitar tocar sem necessidade:** harness comparable veredito, `verify-baremetal` `METAL_OK`, node/agent/runtime host.

## Dependências

- E36: `FULL_GGUF` + contrato SFS
- E44: motor Decode subset em `runtime-native` (reuso)
- E30/E47: artefato ESP / writer (consumo)
- GGUF local (`./scripts/fetch-model.sh`) para ramo A opt-in
- QEMU/OVMF no host (espelho); PC **não** obrigatório

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Regressão BlockIO (não é prova metal)
make verify

# Artefato ESP (opcional FULL_GGUF para ramo A)
./scripts/fetch-model.sh
IA_LIVRE_BAREMETAL_FULL_GGUF=1 make baremetal-esp

# Gate desta etapa (nome fixado na Task 3) — exige geração mínima OU B_BLOCK metal
make verify-…   # esperado: marcadores A ou B; sem TOKENS fingidos; sem METAL_OK fabricado

# METAL_OK permanece E46 / SKIP
make verify-baremetal   # default SKIP=1 → IMAGE_OK
```

Critério: exit 0 do gate E48 **e** ausência de `TOKENS_PER_S` sem loop no path metal sob teste.
