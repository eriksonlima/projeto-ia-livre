# Corrida quieta do harness A vs B (Etapa 28)

Protocolo de **medição serial** para o instrumento comparável (`make verify-harness-comparable` / `scripts/run-harness-a-b-comparable.sh`).

Ponte: [`harness-a-b-comparavel.md`](harness-a-b-comparavel.md) · Linha B: [`runtime-nativo-linha-b.md`](runtime-nativo-linha-b.md) · CPU serial: [`runtime-inferencia-cpu-metricas.md`](runtime-inferencia-cpu-metricas.md).

> **Não prova a hipótese.** Enquanto `B_BLOCK=no_gguf_decode` (E32; tokenize/embed/camada ok, sem Prefill/Decode — ADR [`0013`](adr/0013-geracao-canonica-fatiada-linha-b.md)), o veredito válido é **`INCONCLUSIVO`**. Proibido inventar métricas em B.

## Por quê

Gates/QEMU/runtime em **paralelo** no mesmo host deprimem T/s da Linha A e misturam ruído com o instrumento A vs B. Uma corrida “limpa” exige **um alvo por vez** e host sem carga concorrente de verificação.

## Pré-condições

Antes de rodar o comparable (ou A e B separados):

1. Nenhum outro `make verify*` / `verify-*.sh` em execução neste host.
2. Nenhum QEMU do projeto (`qemu-system-x86_64` com ESP/`gguf-canon`) em paralelo.
3. Nenhum `cargo run -p ia-livre-runtime` / `ia-livre-agent` pesado concorrente.
4. Preferência: host ocioso; se houver carga residual, anotar `loadavg` e o motivo.

Checklist rápido (opcional):

```bash
pgrep -af 'qemu-system-x86|verify-(boot|runtime|harness|agent|node)' || true
cat /proc/loadavg
```

Preflight no comparable: **aviso** se houver `qemu-system-x86_64` ou `scripts/verify-*` / `run-harness-*` reais (ignora shells sandbox).  
- Falha dura só com `IA_LIVRE_HARNESS_QUIET_STRICT=1`.  
- Override: `IA_LIVRE_HARNESS_QUIET_FORCE=1` (anotar no registro).

## Ordem

1. Garantir GGUF canônico: `./scripts/fetch-model.sh`
2. **Uma** corrida: `make verify-harness-comparable`  
   (internamente: Linha A → Linha B; não lançar A e B em shells paralelos)
3. Não misturar com `make verify-runtime` / `verify-agent` / `verify` no mesmo intervalo

Timeout: `VERIFY_HARNESS_COMPARABLE_TIMEOUT` (default = `VERIFY_HARNESS_TIMEOUT`, 300s).

## O que registrar

| Campo | Exemplo |
|-------|---------|
| Data (UTC) | `2026-03-20T…Z` |
| Host / loadavg | `0.12 0.34 0.50` |
| Timeout | `300` |
| `VERDICT` | `INCONCLUSIVO` |
| `VERDICT_REASON` | `…E32_no_gguf_decode` |
| Métricas A | `HARNESS_LOAD_S=` / `HARNESS_TOKENS_PER_S=` |
| B | `LOADER=blockio_full`, `B_BLOCK=no_gguf_decode` — **sem** `TOKENS_PER_S` |

## O que NÃO fazer

- Rodar gates/QEMU/runtime em paralelo “para ir mais rápido”
- Inventar `TOKENS_PER_S` em B (proxy + stub ≠ geração)
- Declarar `COMPROVA` / `REFUTA` sob `no_gguf_decode`
- Tratar métricas E5/E8 (CPU/GPU host) como veredito A vs B
- Converter `PROXY_MS` / microbench em tokens

## Expectativa atual (pós-E32)

| Lado | Estado |
|------|--------|
| A | GGUF host real → load + tokens |
| B | tokenize + embed + camada parcial; `LOAD_KIND=proxy`; `B_BLOCK=no_gguf_decode` |
| Veredito | **`INCONCLUSIVO`** (obrigatório até tokens reais em B) |

Quando existir motor GGUF real em B com `TOKENS_PER_S` medidos, este protocolo continua válido; só então `COMPROVA`/`REFUTA` podem entrar (checklist em `harness-a-b-comparavel.md`).

## Tooling

- Preflight leve no comparable: avisa se detectar QEMU/`verify-*` concorrente; não bloqueia com `IA_LIVRE_HARNESS_QUIET_FORCE=1`.
- Evidência da re-corrida quieta desta etapa: seção abaixo (preenchida na fatia de execução).

## Evidência — re-corrida quieta (Etapa 28)

| Campo | Valor |
|-------|-------|
| Data (UTC) | `2026-11-21T02:07:51Z` (registro pós-gate) |
| loadavg (início) | `1.76 1.67 1.70` (`IA_LIVRE_HARNESS_QUIET_LOADAVG`) |
| Timeout | `300` s |
| `IA_LIVRE_HARNESS_VERDICT` | `INCONCLUSIVO` |
| `IA_LIVRE_HARNESS_VERDICT_REASON` | `B_proxy_sem_TOKENS_PER_S_E27_no_gguf_infer_engine` (histórico E28; pós-E32: `…E32_no_gguf_decode`) |
| Métricas A | `HARNESS_LOAD_S=1.029` · `HARNESS_TOKENS_PER_S=15.409` |
| B | `blockio_full` / stub E27 / `B_BLOCK=no_gguf_infer_engine` (histórico; atual = `no_gguf_decode`) — **sem** `TOKENS_PER_S` |
| Contenção | QEMU órfãos mortos antes; preflight = aviso (default não-strict) |
| Force override | não |
| Gate | `make verify-harness-comparable` → `GATE_OK` |

## Como rodar (quieto)

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"

./scripts/fetch-model.sh
# Confirmar host quieto (checklist acima)
make verify-harness-comparable
```

Gate do instrumento: permanece o de Etapa 22 — aceita `INCONCLUSIVO` com B sem geração.
