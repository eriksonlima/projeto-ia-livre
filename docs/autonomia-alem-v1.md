# Autonomia além de v1 — tool sandboxed `calc` (Etapa 40)

Extensão do ambiente de autonomia: **uma** ferramenta nova em sandbox explícito. **Sem** REPL nesta etapa. **Sem** shell/HTTP/FS. **Sem** exigir o SO IA Livre.

v1: [`desenho-autonomia-v1.md`](desenho-autonomia-v1.md) · ADR [`0005`](adr/0005-autonomia-v1-utilizavel.md).  
Protótipo: [`ambiente-autonomia-prototipo.md`](ambiente-autonomia-prototipo.md).

## Decisão

| Peça | Escolha |
|------|---------|
| Superfície | Tool **`calc`** |
| REPL | **Fora** (backlog) |
| `read_local` | **Fora** (backlog) |
| Shell/HTTP | **Proibido** |

## Sandbox `calc`

| Regra | Valor |
|-------|--------|
| Args | `expr: string` |
| Charset | `0-9 . + - * / ( )` e espaço |
| Prova | `1+2*3` → `7` |
| Erros | charset inválido, vazio, divisão por zero — rejeição honesta |
| Avaliação | Parser próprio (sem `eval` de linguagem, sem `Command`) |

Allowlist completa: `note` / `recall` / `help` / **`calc`**.

## Marcadores

```
IA_LIVRE_TOOL=calc
IA_LIVRE_CALC_RESULT=7
IA_LIVRE_TOOL_SANDBOX_OK
```

Preserva E7/v1: `TOOL_OK`, `MEMORY_OK`, `AGENT_OK`, `MEMORY_POLICY_OK`, `TOOLS_USED≥2`.

## Gate

`make verify-agent` exige `IA_LIVRE_TOOL=calc` + `IA_LIVRE_TOOL_SANDBOX_OK` além da regressão v1.

## Ponte Etapa 49 (bridge nativo)

Validação de evidência do runtime nativo (serial BlockIO / path metal) fica em bridge **host**, não neste agente: [`autonomia-bridge-nativo.md`](autonomia-bridge-nativo.md). `make verify-agent` **não** depende do SO (ADR 0001).

## Ponte Etapa 70 (consumo nativo)

Além de validar: o host **usa** `BRIDGE_NATIVE_SRC` via allowlist (`note`/`recall`) e emite `NATIVE_CONSUME_*` — [`autonomia-nativa.md`](autonomia-nativa.md). Ainda **sem** agente no guest; gate aditivo `verify-autonomia-nativa`.

## Futuro

| Item | Nota |
|------|------|
| REPL | **Etapa 53** — [`autonomia-repl.md`](autonomia-repl.md) (`--repl` / `--repl-script`) |
| `read_local` | **Etapa 54** — [`autonomia-read-local.md`](autonomia-read-local.md) |
| Tools via SLM | Parsing espontâneo — não critério deste gate |

## Como rodar

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
./scripts/fetch-model.sh
cargo build -p ia-livre-runtime -p ia-livre-agent
cargo run -p ia-livre-agent -- --model models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
make verify-agent
```
