# REPL sandboxed no agente (Etapa 53)

Extensão da autonomia host (`ia-livre-agent`): loop stdin/arquivo **só** com allowlist `note` / `recall` / `help` / `calc`.  
**Sem** shell, HTTP, FS arbitrário. ADR 0001: **não** exige o SO IA Livre.

Ponte E40: [`autonomia-alem-v1.md`](autonomia-alem-v1.md).

## Flags

| Flag | Efeito |
|------|--------|
| `--repl` | Loop interativo (stdin TTY) |
| `--repl-script <FILE>` | Modo scripted (gate); não interativo |
| `--prompt` + REPL | **Erro** (conflito) |

Linhas: `tool [args…]`; vazias ignoradas; `quit`/`exit` encerra. Fora da allowlist → erro honesto.

## Marcadores

```
IA_LIVRE_REPL_MODE=scripted|interactive
IA_LIVRE_REPL_OK
```

## Fixture

`agent/fixtures/repl-smoke.txt` — `help` + `calc 1+2*3` + `quit`.

## Gate

`make verify-agent` inclui estágio `--repl-script` (além da prova E7/v1/E40).
