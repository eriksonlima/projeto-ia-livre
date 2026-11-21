# Plan — Loader GGUF nativo mínimo na Linha B

## Abordagem

1. **Contrato e decisão I/O:** documentar ESP (FAT já usado pelo boot) como mecanismo canônico; leitura em Boot Services → cópia para buffer/`Weights` antes de ExitBoot; cabeçalho/prefixo suficiente vs 638 MiB / 256M RAM; ADR curta; tabela de marcadores que substitui `GGUF_NATIVE_LOADER=absent` / `B_BLOCK=no_gguf_path`.
2. **I/O guest mínimo:** empacotar artefato GGUF (completo ou prefixo) no ESP no host; no kernel UEFI, abrir/ler magic+bytes, copiar para região documentada, emitir marcadores serial — **sem** decode/geração.
3. **Harness:** `run-harness-line-b.sh` observa serial e reemite `GGUF_NATIVE_LOADER` ≠ `absent` + status coerente; preserva proxy + `HARNESS_CONTRACT_*`; **não** emite `TOKENS_PER_S`.
4. **Gate:** atualizar `verify-harness.sh` / `make verify` (se aplicável) para o contrato novo; rejeitar fraude; alinhar `AGENTS.md`.

Ordem das fatias = `tasks.md`. Não implementar inferência completa. Não declarar hipótese comprovada.

## Arquivos prováveis

- `docs/runtime-nativo-linha-b.md` — seção loader nativo; evolução do bloqueio E21
- `docs/harness-linha-a-b.md` — slot B com loader parcial
- `docs/adr/0008-…` (ou próximo número livre) — ESP-pré-ExitBoot vs fw_cfg/virtio
- `docs/architecture.md` — ponte mínima
- `docs/memoria-scheduler-impl-minima.md` — ponte curta se `Weights` for destino dos bytes (sem reabrir E19)
- `AGENTS.md` — Como rodar / verificar
- `README.md` — só se a capa ficar enganosa
- `Makefile` / script de prep ESP — copiar GGUF ou prefixo para `build/esp/`
- `kernel/src/…` — leitura UEFI + marcadores serial
- `scripts/run-harness-line-b.sh` — reemissão loader
- `scripts/verify-harness.sh` (+ possivelmente `scripts/verify-boot.sh`) — gate novo
- Skill `verificar-harness` se o contrato do gate mudar de forma estável

**Não editar nesta etapa:** `node/`, `agent/` (produto), `runtime/` host como se fosse B, specs de etapas irmãs fechadas (exceto pontes docs).

## Dependências

| Dependência | Papel |
|-------------|--------|
| Etapa 12 | Proxy B + ESP/QEMU baseline |
| Etapa 19 | Contrato `Weights`/`KvCache` (destino preferencial dos bytes) |
| Etapa 20/21 | `CONTRACT_READY` + bloqueio `no_gguf_path` a desbloquear |
| GGUF canônico + `fetch-model.sh` | Fonte dos bytes no host |
| QEMU/OVMF + `make esp` | Ambiente Linha B |
| Inferência em B / Etapa futura | **Fora** — consome este loader depois |

## Verificação

- Checklist do `Pronto quando` da Issue #26 / Etapa 26.
- Após Task 2+: evidência serial de magic/bytes no QEMU.
- Após Task 3–4: `make verify-harness` verde com `GGUF_NATIVE_LOADER` ≠ `absent` e **sem** `TOKENS_PER_S` em B.
- Regressões: `make verify` (kernel), Linha A (`verify-runtime` / harness A) não devem quebrar.
- Relato da fatia: o que foi e o que **não** foi verificado (ex. arquivo completo vs só cabeçalho).
- Proibido no gate verde: números de geração inventados; `COMPROVA` da hipótese.
