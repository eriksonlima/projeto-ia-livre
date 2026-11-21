# Tasks — Autonomia v1 utilizável (impl. em agent/)

Uma task = uma fatia. Ordem sequencial.

- [x] Task 1 — CLI `--prompt` one-shot + política de memória N=8
  - **Pronto quando:** `ia-livre-agent` aceita `--prompt <texto>`; sem a flag, usa o prompt de prova E7; carrega o JSONL e injeta as últimas **N=8** entradas no prompt montado enviado ao runtime; kinds mínimos `note` / `turn` / `tool` documentados no código ou doc; emite `IA_LIVRE_MEMORY_POLICY_OK` quando a política for aplicada; mantém ferramenta `note` + marcadores E7 (`TOOL_OK` / `MEMORY_OK` / `AGENT_OK`) no path de prova; **sem** shell/HTTP/REPL/RAG; **sem** exigir SO IA Livre. README avaliado (`readme-por-fatia`).
  - **Arquivos típicos:** `agent/src/main.rs`; opcional ponte curta em `docs/desenho-autonomia-v1.md` ou comentário no protótipo.
  - **Fora:** `recall`/`help` completos (Task 2); mudança do gate (Task 3); kernel/node/harness.
  - **Nota:** README considerado — capa não menciona agent; sem mudança.

- [x] Task 2 — Ferramentas `recall` e `help` + prova com ≥2 tools
  - **Pronto quando:** allowlist implementada com `recall` (listar/filtrar entradas recentes do JSONL) e `help` (listar ferramentas + contratos curtos); cenário de prova invoca de forma **determinística** `note` **e** (`recall` **ou** `help`); stdout prova ≥2 ferramentas (ex. `IA_LIVRE_TOOLS_USED=2` e/ou `IA_LIVRE_TOOL=…` por ferramenta); write só no path de memória documentado; **sem** shell/HTTP/rede. README reavaliado.
  - **Arquivos típicos:** `agent/src/main.rs`.
  - **Fora:** extensão do `verify-agent.sh` / AGENTS gate (Task 3); REPL; novas tools além da allowlist.
  - **Nota:** prova exerce note+recall+help (`TOOLS_USED=3`); README sem mudança.

- [x] Task 3 — Gate `verify-agent` estendido + docs da v1
  - **Pronto quando:** `scripts/verify-agent.sh` (e `make verify-agent`) exige marcadores E7 **e** `IA_LIVRE_MEMORY_POLICY_OK` **e** evidência de ≥2 ferramentas; regressão E7 (nota canônica / memória) preservada; `AGENTS.md` documenta `--prompt`, allowlist, política N=8 e o gate estendido; docs (`ambiente-autonomia-prototipo.md` e/ou `desenho-autonomia-v1.md`) deixam claro que a v1 está **implementada** no host (Etapa 22), sem exigir SO IA Livre; README reavaliado; etapa pronta para revisão (não marcar `feita` aqui).
  - **Arquivos típicos:** `scripts/verify-agent.sh`, `AGENTS.md`, docs de autonomia; `Makefile` só se necessário.
  - **Fora:** kernel/harness/node; promoção da etapa no ROADMAP (agente principal).
  - **Nota:** README reavaliado — sem mudança (AGENTS cobre operacional).
