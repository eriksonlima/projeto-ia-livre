# Tool `read_local` allowlisted (Etapa 54)

Leitura de arquivo **somente** sob roots allowlisted. Sem write; sem shell/HTTP. ADR 0001: host, sem exigir SO.

## Roots (relativos ao cwd do processo)

| Root | Uso |
|------|-----|
| `agent/fixtures/` | Fixtures versionadas (prova) |
| `build/agent-memory/` | Memória local do agente |

Path deve resolver **dentro** de um root (canonicalizado). Symlink/escape → rejeição.

## Limites

- Máx. **64 KiB** por leitura
- Texto UTF-8; binário → erro honesto
- Sem flags de escrita

## Marcadores

```
IA_LIVRE_TOOL=read_local
IA_LIVRE_READ_LOCAL_OK
```

## REPL

`read_local <path>` no `--repl` / `--repl-script`.

## Gate

`make verify-agent` exige `READ_LOCAL_OK` (prova e/ou REPL).
