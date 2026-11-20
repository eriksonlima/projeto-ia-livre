# Plan — Runtime nativo / Linha B real (mínimo)

## Abordagem

1. **Fixar o contrato** (Task 1): atualizar o doc do harness e (se útil) um doc curto do caminho nativo — desenho único = proxy pós-ExitBoot no QEMU; tabela do que B emite; proibições; ponte architecture / kernel-pos-boot; AGENTS intenção; README avaliado.
2. **Implementar o proxy no kernel** (Task 2): após a cadeia `EXIT_BOOT_OK`, microbenchmark bare-metal com ops + tempo (ou ops + medição de janela documentada), marcadores `IA_LIVRE_NATIVE_BENCH_*` na UART COM1; `make verify` do kernel não regride.
3. **Substituir o stub e o gate** (Task 3): `run-harness-line-b.sh` orquestra build/QEMU/captura → `HARNESS_*` LINE=B; `verify-harness` exige A GGUF + B proxy (sem `B_SKIP`, sem `TOKENS_PER_S` em B); AGENTS Como verificar; README reavaliado.

Ordem: docs → kernel → scripts/gate (o script B depende dos marcadores kernel; o gate depende do script).

## Arquivos prováveis

- `docs/harness-linha-a-b.md` — estado B, marcadores proxy, não-comparabilidade
- `docs/runtime-nativo-linha-b.md` — opcional se a seção no harness ficar longa; senão seção no harness basta
- `docs/kernel-pos-boot-services.md` — ponte pós-EXIT → native bench
- `docs/architecture.md` — uma linha: B mínimo = proxy; hipótese aberta
- `kernel/src/main.rs` (e módulos mínimos se já existir estrutura) — microbenchmark pós-exit
- `scripts/run-harness-line-b.sh` — QEMU + parse/reemit
- `scripts/verify-harness.sh` — política A + B
- `Makefile` — só se precisar de alvo auxiliar (preferir reusar `make build` / lógica de `verify-boot.sh`)
- `AGENTS.md` — Como rodar / Como verificar
- `README.md` — só se a capa ficar enganosa
- `specs/runtime-nativo-linha-b/tasks.md` — marcar fatias

## Dependências

- Etapas 9–11 feitas (harness A, ExitBoot + COM1, `make verify` kernel).
- QEMU/OVMF no host (mesmo pré-requisito do gate do kernel).
- GGUF ainda necessário **só** para a Linha A no `verify-harness`.
- Sem CUDA/Vulkan, sem llama.cpp no target UEFI.

## Verificação

Por fatia, conforme `tasks.md`. Gate final da etapa:

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
make verify                 # regressão kernel + NATIVE_BENCH se incluído no gate kernel (opcional)
./scripts/fetch-model.sh
make verify-harness         # A GGUF + B proxy QEMU
```

Critério de pronto da etapa: evidência de `IA_LIVRE_HARNESS_LINE=B` + `HARNESS_OK` + proxy; docs sem declaração de hipótese comprovada.
