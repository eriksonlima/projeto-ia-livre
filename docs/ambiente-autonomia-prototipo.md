# Ambiente de autonomia — protótipo (Etapa 7)

Contrato **mínimo** da **camada 3**. Público e aberto.  
Este protótipo roda no **host Linux** (`std`) e **não exige** o SO **IA Livre**, QEMU nem UEFI (ADR 0001).

P2P (`node/` / Rede IA Livre) está **fora** desta entrega.

## Independência

| Precisa | Não precisa |
|---------|-------------|
| Rust no host (`std`) | Kernel UEFI / QEMU / `IA_LIVRE_BOOT_OK` |
| Runtime CPU + GGUF canônico (Etapa 5) | Nó P2P / `IA_LIVRE_PEER_OK` |

Crate: `agent/` (`ia-livre-agent`). Sem dependência de `kernel/` ou `node/` no `Cargo.toml`.

## Loop do agente

Cenário de prova canônico (gate):

1. Carregar memória (arquivo JSONL; pode estar vazio na 1ª run).
2. Montar prompt fixo curto.
3. Chamar o runtime CPU (`ia-livre-runtime`) via **subprocesso** CLI (`--model`, `--prompt`, `--n-predict` baixo).
4. Decisão de ferramenta: no cenário de prova a invocação é **garantida** (não depende só do SLM emitir tool-call).
5. Executar a ferramenta de prova.
6. Persistir memória e **re-ler** para confirmação.
7. Emitir marcadores na stdout.

## Memória persistente

| Item | Valor |
|------|-------|
| Path default | `build/agent-memory/memory.jsonl` (gitignored via `build/`) |
| Formato | JSONL — uma linha JSON por turno/nota |
| Campos mínimos | `ts` (ISO-8601 ou unix), `kind` (`note` / `turn`), `text` |

Prova: após escrita, re-leitura na mesma execução (ou segunda invocação no script de verify) confirma o conteúdo → `IA_LIVRE_MEMORY_OK`.

## Ferramenta (mínimo)

| Nome | Argumentos | Efeito |
|------|------------|--------|
| `note` | `text: string` | Appenda uma linha `{kind:"note", text, …}` ao arquivo de memória |

Registro: só esta ferramenta no protótipo. Sucesso → `IA_LIVRE_TOOL_OK`.

## Consumo do runtime

- Binário/crate existente: `ia-livre-runtime` (subprocesso preferido).
- Modelo: mesmo GGUF da Etapa 5 (`models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf`); `./scripts/fetch-model.sh`.
- Flags típicas: `--model … --prompt "…" --n-predict 16` (default do agente).
- O agente **não** reimplementa llama.cpp; **não** exige refactor do `runtime/` em lib nesta etapa.
- Marcador opcional: `IA_LIVRE_RUNTIME_USED=1`.

## Prompt de prova (fixado)

```
Complete em uma frase: O Projeto IA Livre é
```

(Alinhado ao runtime; o gate não exige qualidade do texto gerado.)

## Marcadores (stdout)

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_AGENT_OK` | Cenário de prova concluído |
| `IA_LIVRE_TOOL_OK` | Ferramenta `note` executou com sucesso |
| `IA_LIVRE_MEMORY_OK` | Memória escrita e re-lida / confirmada |

## Defaults canônicos

| Item | Valor |
|------|-------|
| Crate / binário | `agent/` / `ia-livre-agent` |
| Memória | `build/agent-memory/memory.jsonl` |
| Ferramenta | `note` |
| Nota de prova | `prova-autonomia-ia-livre` |
| `--n-predict` | `16` |
| Timeout do gate | 300s (`VERIFY_AGENT_TIMEOUT`) |

## Fora deste protótipo

Multi-agente, ReAct robusto, RAG/vetores, sandbox OS-level, integração P2P/kernel, GPU, UI.

> **Etapa 22 (implementação):** autonomia v1 (`--prompt`, `note`/`recall`/`help`, política N=8) está em `agent/` — ver [`desenho-autonomia-v1.md`](desenho-autonomia-v1.md) / ADR [`0005`](adr/0005-autonomia-v1-utilizavel.md). Este doc permanece o contrato do **protótipo Etapa 7**; o gate `make verify-agent` agora também cobre a v1 (política + ≥2 tools) sem exigir QEMU/SO IA Livre.

## Fluxo canônico

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
./scripts/fetch-model.sh
cargo build -p ia-livre-runtime -p ia-livre-agent
cargo run -p ia-livre-agent -- \
  --model models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
  --memory build/agent-memory/memory.jsonl
# Esperado: IA_LIVRE_TOOL_OK, IA_LIVRE_MEMORY_OK, IA_LIVRE_AGENT_OK
```

Gate: `make verify-agent` (não exige QEMU/UEFI).
