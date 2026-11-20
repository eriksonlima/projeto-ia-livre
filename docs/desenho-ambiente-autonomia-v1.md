# Desenho — Ambiente de autonomia v1

Primeira versão **utilizável** da camada 3 além do protótipo Etapa 7.  
**Nível:** desenho (Etapa 15). **Não** implementação. O `agent/` atual **não** é v1.

ADR: [`docs/adr/0005-ambiente-autonomia-v1.md`](adr/0005-ambiente-autonomia-v1.md).  
Protótipo E7: [`docs/ambiente-autonomia-prototipo.md`](ambiente-autonomia-prototipo.md).

## Motivação vs protótipo E7

| E7 (protótipo) | v1 (desenho) |
|----------------|--------------|
| Prompt fixo de prova | `--goal` + contexto |
| 1 turno | Até N turnos (ex. 3) |
| Só `note` (append) | `note` + `recall` / listagem |
| Marcadores AGENT/TOOL/MEMORY | + `GOAL_OK` + `RECALL_OK` (futuro) |

## Modelo de sessão

```
cargo run -p ia-livre-agent -- --goal "…" --memory … --max-turns N --model …
  → carrega JSONL
  → turnos 1..=N: runtime subprocesso → tools note|recall → persiste
  → emite marcadores
```

## Critério verificável mínimo (v1 — implementação futura)

Gate futuro / extensão de `verify-agent` deve exigir:

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_RUNTIME_USED=1` | (E7) |
| `IA_LIVRE_TOOL_OK` | (E7) |
| `IA_LIVRE_MEMORY_OK` | (E7) |
| `IA_LIVRE_AGENT_OK` | (E7) |
| `IA_LIVRE_GOAL_OK` | Objetivo CLI aceito / refletido na sessão |
| `IA_LIVRE_RECALL_OK` | Segunda ferramenta / consulta à memória executada |

`make verify-agent` **atual** permanece válido para o protótipo E7.

## Fronteira do próximo protótipo (implementação)

**Entra:**

- [ ] `--goal` + `--max-turns`
- [ ] Ferramenta `recall` / `list_notes`
- [ ] Marcadores `GOAL_OK` + `RECALL_OK`
- [ ] Gate estendido

**Fora:**

- Multi-agente, P2P, kernel/QEMU, RAG/embeddings, UI, sandbox OS, LangChain-like

## Alternativas rejeitadas (agora)

| Alternativa | Motivo |
|-------------|--------|
| Código “mínimo” nesta etapa | Spec fixou doc-only |
| Novo crate | Evoluir `agent/` |
| Exigir SO IA Livre | Contradiz ADR 0001 / manifesto |
