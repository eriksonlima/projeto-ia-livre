# Plan — Carga GGUF canônica na Linha B (mínimo honesto)

## Abordagem

1. **Contrato primeiro (paralelo-seguro):** documentar o caminho canônico GGUF em B, pré-requisitos B13/B14, e os dois desfechos (métricas em espécie **ou** bloqueio honesto), sem tocar kernel/runtime das etapas irmãs.
2. **Instrumento honesto:** alinhar scripts/gate do harness para distinguir `proxy` (Etapa 12), `blocked` e `gguf` — rejeitar métricas inventadas; manter o proxy como default de sucesso mínimo até GGUF real.
3. **Integração condicionada:** só quando B13 + B14 estiverem mergeados/verificáveis no branch adotado, ligar harness B ao contrato nativo (sem fingir tokens se a carga ainda não existir).
4. **Carga ou bloqueio final:** tentar a carga canônica (modelo, prompt, `n-predict=32`) com métricas medidas; se inviável, fechar a etapa com bloqueio documentado — ambos cumprem o Pronto quando.

Ordem das fatias = tasks.md. Não implementar B13/B14 aqui. Não declarar hipótese comprovada.

## Arquivos prováveis

- `docs/runtime-nativo-linha-b.md` — seção GGUF em B + bloqueio + deps
- `docs/harness-linha-a-b.md` — estado do slot B; comparabilidade condicionada
- `docs/architecture.md` — ponte mínima (se necessário)
- `AGENTS.md` — Como rodar / verificar cenários B
- `README.md` — só se a capa ficar enganosa (`readme-por-fatia`)
- `scripts/run-harness-line-b.sh` — proxy / bloqueio / GGUF honesto
- `scripts/verify-harness.sh` (+ `Makefile` só se o agente principal autorizar fora desta spec de docs — implementação de gate na fatia de produto)
- Possível doc curto dedicado (ex. `docs/carga-gguf-linha-b.md`) **somente** se a seção em `runtime-nativo-linha-b.md` ficar grande demais — preferir estender o existente

**Não editar nesta etapa (outras issues/branches):** `specs/memoria-scheduler-impl-minima/`, `specs/runtime-contrato-nativo/`, implementação exclusiva de B13/B14, `memory-bank/AGENT_CLAIM.md`.

## Dependências

| Dependência | Papel |
|-------------|--------|
| Etapa 12 | Proxy B vivo; baseline do harness B |
| Etapa 19 / B13 (#19) | Memória/scheduler mínima no kernel — **bloqueia** carga GGUF real |
| Etapa 20 / B14 (#20) | Runtime falando contrato nativo — **bloqueia** carga GGUF real |
| GGUF canônico + `fetch-model.sh` | Pesos locais (mesmo arquivo da Linha A) |
| QEMU/OVMF | Ambiente Linha B |
| Etapa 22 / B16 | Consome o resultado; **não** faz parte desta etapa |

Se B13/B14 não mergeados: avançar Tasks 1–2 e, nas Tasks 3–4, documentar bloqueio + stubs — **sem** inventar `TOKENS_PER_S`.

## Verificação

- Checklist do `Pronto quando` da Issue #21 / Etapa 21.
- Gate: `make verify-harness` (após Task 2+) — A inalterado em espírito; B = proxy **ou** bloqueio honesto **ou** GGUF real com métricas medidas.
- Regressões: `make verify` (kernel) e Linha A GGUF não devem quebrar por esta etapa.
- Evidência explícita no relato da fatia: o que foi e o que **não** foi verificado (especialmente se B13/B14 ausentes).
- Proibido no gate verde: números GGUF inventados em B; declaração de hipótese comprovada.
