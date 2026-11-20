# ADR 0005 — Escopo da autonomia v1 (host)

- Status: aceita (nível **desenho / escopo**; implementação = etapa/backlog futuro)
- Data: 2026-11-20

## Contexto

O protótipo da Etapa 7 (`agent/`, `docs/ambiente-autonomia-prototipo.md`) prova loop single-shot, ferramenta `note`, memória JSONL e subprocesso `ia-livre-runtime`. Em `docs/architecture.md` restava aberta a lacuna «forma e escopo do ambiente de autonomia na primeira versão utilizável».

ADR 0001: agentes **fora** do kernel; autonomia **não exige** o SO IA Livre.

## Decisão

1. **Autonomia v1** evolui o crate `agent/` no **host** — sem exigir QEMU/UEFI.
2. **Sessão:** objetivo CLI (`--goal` ou equivalente) + até **N turnos** (N documentado, ex. 3).
3. **Memória:** JSONL permanece; v1 exige **consulta** (recall / listar últimos K), não só append `note`.
4. **Ferramentas:** registro explícito; mínimo = `note` + **recall/list_notes`.
5. **Runtime:** continua via subprocesso CLI + GGUF canônico.
6. **Esta etapa (15):** **doc-only** — sem alterar código de produto; `make verify-agent` permanece o floor do protótipo.
7. **Critério verificável da v1 (implementação futura):** além de `AGENT_OK`/`TOOL_OK`/`MEMORY_OK`, candidatos `IA_LIVRE_GOAL_OK` + `IA_LIVRE_RECALL_OK`.
8. **Fora:** multi-agente, P2P, kernel, RAG vetorial, UI, sandbox OS.

Doc: [`docs/desenho-ambiente-autonomia-v1.md`](../desenho-ambiente-autonomia-v1.md).

## Consequências

### Positivas

- Fecha a lacuna de architecture no nível escopo
- Critério de gate futuro explícito (não ambíguo)
- Mantém ADR 0001 (host, sem exigir SO)

### Negativas

- SLM pequeno pode falhar em tool-calling confiável — parsing e prompts precisarão de cuidado na implementação
- Sem UI, “utilizável” = CLI verificável, não produto de consumo geral
