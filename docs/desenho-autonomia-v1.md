# Desenho — Autonomia v1 utilizável (camada 3)

Primeira versão **utilizável** da camada 3, além do protótipo Etapa 7.  
**Nível:** desenho (Etapa 15) + **implementação** (Etapa 24) em `agent/` / `ia-livre-agent`.  
Host only; **não** exige o SO IA Livre.

ADR: [`docs/adr/0005-autonomia-v1-utilizavel.md`](adr/0005-autonomia-v1-utilizavel.md).  
Protótipo E7: [`docs/ambiente-autonomia-prototipo.md`](ambiente-autonomia-prototipo.md).  
ADR 0001: autonomia fora do kernel; sem exigir o SO IA Livre.

## Motivação vs protótipo E7

| Limite do protótipo (E7) | Resposta v1 (desenho) |
|--------------------------|------------------------|
| Prompt fixo de prova apenas | `--prompt` one-shot (usuário); prompt fixo = default de prova |
| Só ferramenta `note` | Allowlist `note` / `recall` / `help` |
| Memória append + re-leitura | Política: injetar últimas **N=8** entradas no prompt |
| Um cenário de prova | Critério verificável com ≥2 ferramentas + política |

## Fronteira E7 × v1 × futuro

| Tema | E7 (protótipo) | v1 (desenho) | Futuro |
|------|----------------|--------------|--------|
| Host Linux / sem SO IA Livre | sim | sim | — |
| Subprocesso `ia-livre-runtime` | sim | sim | lib opcional |
| `--prompt` usuário | não | sim | REPL |
| Ferramentas | `note` | `note`/`recall`/`help` | allowlist maior / sandbox |
| Memória | JSONL mínimo | kinds + N=8 no prompt | RAG / vetores |
| P2P / kernel | fora | fora | etapas próprias |
| Gate | `verify-agent` | E7 intacto; extensão na implementação | gate v1 |

## UX CLI mínima

```bash
cargo run -p ia-livre-agent -- \
  --model models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
  --memory build/agent-memory/memory.jsonl \
  --prompt "Resuma as notas recentes"
```

Flags canônicas: `--model`, `--memory`, `--n-predict`, `--prompt` (novo na v1).  
Sem `--prompt`: comportamento de **prova** alinhado ao E7 (compatibilidade).

## Ferramentas (contratos)

| Nome | Args | Efeito | Marcador (alvo) |
|------|------|--------|-----------------|
| `note` | `text: string` | Append `{kind:"note", …}` ao JSONL | `IA_LIVRE_TOOL_OK` (E7) |
| `recall` | opcional `n` / filtro | Lista entradas recentes (stdout e/ou kind `tool`) | conta como 2ª ferramenta na prova v1 |
| `help` | — | Lista allowlist + contratos curtos | alternativa à 2ª ferramenta |

**Proibido na v1:** shell, HTTP, write fora do dir de memória/workspace documentado.

## Política de memória

| Item | Valor |
|------|--------|
| Formato | JSONL (uma linha JSON por evento) |
| Kinds | `note`, `turn`, `tool` |
| Path default | `build/agent-memory/memory.jsonl` (gitignored) |
| Injeção | Últimas **N=8** entradas no prompt montado |
| Fora | Embeddings, RAG, sumarização automática obrigatória |

## Critério verificável mínimo (próxima implementação)

Cenário de prova v1 (documental):

1. Rodar agente com `--prompt` curto.
2. Executar `note` **e** (`recall` **ou** `help`) de forma determinística no cenário.
3. Confirmar JSONL escrito/re-lido e política N aplicada.
4. Emitir: `IA_LIVRE_TOOL_OK`, `IA_LIVRE_MEMORY_OK`, `IA_LIVRE_AGENT_OK` (E7) **e** evidência de política (ex. `IA_LIVRE_MEMORY_POLICY_OK`) + prova de ≥2 ferramentas (ex. `IA_LIVRE_TOOLS_USED=2` ou marcadores por ferramenta).

`make verify-agent` (Etapa 24) exige marcadores E7 **e** `IA_LIVRE_MEMORY_POLICY_OK` **e** evidência de ≥2 ferramentas (`IA_LIVRE_TOOLS_USED` + `IA_LIVRE_TOOL=…`).

## Alternativas consideradas

| Alternativa | Por que não agora |
|-------------|-------------------|
| REPL-first | Mais UX; atrasa critério mínimo one-shot |
| Shell tool | Superfície de risco; fora do manifesto “mínimo utilizável” |
| LangChain / framework | Dependência pesada; controle e auditoria piores |
| Agente no kernel | Contradiz ADR 0001 |

## Não-objetivos

- Produção / multi-agente / marketplace / P2P-tools / RAG / GPU obrigatória
- Obsolecer E7 sem etapa de implementação da v1

## Implementação

1. **Etapa 24** (`specs/autonomia-v1-impl/`): `--prompt`, `recall`/`help`, política N=8, gate estendido — **feito** em `agent/`.
2. Depois: REPL, sandbox, integração Rede (ADR própria)
