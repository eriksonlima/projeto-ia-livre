# Plan — Inferência mínima / TOKENS_PER_S na Linha B

## Abordagem

1. **Contrato e decisão:** fixar por escrito a escolha **A em fatia mínima** (RAM + GGUF completo no ESP + parse stub); rejeitar opção B (tokens de microbench) e fraude host-como-B; nomear bloqueio residual `no_gguf_infer_engine`; ADR 0009; atualizar docs/AGENTS.
2. **Infra guest/host:** subir `-m` QEMU; staging do GGUF canônico completo no ESP; leitura Boot Services (ADR 0008) além do prefixo 4 KiB; marcadores de progresso — **sem** geração.
3. **Parse stub:** metadados/tabela de tensores GGUF mínima + marcador honesto; ponte para `Weights` se couber; **sem** matmul/decode.
4. **Harness + gate:** reemitir loader/status/`B_BLOCK=no_gguf_infer_engine`; atualizar `verify-harness` / boot / comparable; timeout se necessário; **proibido** `TOKENS_PER_S`.

Ordem das fatias = `tasks.md`. Não portar motor de inferência completo. Não declarar hipótese comprovada. Se ao fim das tasks o motor ainda não existir (esperado), a etapa **fecha** pelo braço “bloqueio honesto” do Pronto quando — com avanço real de I/O/RAM/parse.

## Arquivos prováveis

- `docs/runtime-nativo-linha-b.md` — seção Etapa 27; evolução `B_BLOCK` / loader / RAM
- `docs/harness-linha-a-b.md` — slot B pós-E26
- `docs/harness-a-b-comparavel.md` — ponte bloqueio residual / ainda INCONCLUSIVO
- `docs/adr/0009-…` — fatia A mínima; rejeição de tokens de microbench
- `docs/architecture.md` — ponte mínima se ainda disser só `no_gguf_infer` / 256M
- `AGENTS.md` — Como rodar / verificar; `-m`; timeouts
- `README.md` — só se a capa ficar enganosa
- `Makefile` / scripts QEMU (`run-qemu`, verify-boot) — `-m`
- `scripts/esp-stage-gguf-prefix.sh` (evoluir ou irmão) — staging arquivo completo
- `kernel/src/main.rs` (ou módulos) — carga + parse stub + marcadores
- `scripts/run-harness-line-b.sh` / `run-harness-a-b-comparable.sh`
- `scripts/verify-harness.sh` / `scripts/verify-boot.sh`
- Skill `verificar-harness` se o contrato do gate mudar de forma estável

**Não editar nesta etapa:** `node/`, `agent/` (produto), `runtime/` host como se fosse B, GPU manager.

## Dependências

| Dependência | Papel |
|-------------|--------|
| Etapa 26 / ADR 0008 | Loader ESP pré-ExitBoot; prefixo → evoluir para arquivo completo |
| Etapa 19/20 | `Weights`/`KvCache` + `CONTRACT_READY` |
| Etapa 12 | Proxy B preservado |
| GGUF canônico + `fetch-model.sh` | Fonte ~638 MiB no host |
| QEMU/OVMF | Ambiente Linha B; precisa `-m` maior |
| Motor de inferência nativo | **Fora** — consome esta fatia depois |

## Verificação

- Checklist do `Pronto quando` da Issue #27 / Etapa 27 (braço bloqueio honesto + avanço A).
- Após Task 2+: evidência serial de carga além de 4 KiB / arquivo no ESP.
- Após Task 3–4: `make verify-harness` verde com loader/status novos + `B_BLOCK=no_gguf_infer_engine` e **sem** `TOKENS_PER_S` em B.
- `make verify-harness-comparable` → `INCONCLUSIVO`.
- Regressões: `make verify` (kernel); Linha A intacta.
- Relato: o que foi e o que **não** foi verificado (ex. arquivo completo carregado vs só parse parcial; motor ausente).
- Proibido no gate verde: números de geração inventados; `COMPROVA`.
