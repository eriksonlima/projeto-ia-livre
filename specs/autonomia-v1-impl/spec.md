# Spec — Autonomia v1 utilizável (impl. em agent/)

## Resultado visível

Implementação no **host** (`agent/` / `ia-livre-agent`) da autonomia v1 definida na Etapa 15:

1. **CLI one-shot** — flag `--prompt` (texto do usuário); sem `--prompt`, comportamento de prova E7 permanece.
2. **Allowlist** — ferramentas `note`, `recall` e `help` (contratos do desenho); **sem** shell/HTTP/REPL/RAG.
3. **Política de memória N=8** — últimas 8 entradas do JSONL injetadas no prompt montado; kinds `note` / `turn` / `tool`.
4. **Cenário de prova v1** — ≥2 ferramentas da allowlist de forma **determinística** + marcadores E7 **e** `IA_LIVRE_MEMORY_POLICY_OK` + evidência de ferramentas (ex. `IA_LIVRE_TOOLS_USED=2` ou marcadores por ferramenta).
5. **Gate** — `make verify-agent` preservado ou estendido de forma documentada; **sem** exigir SO IA Livre / QEMU / UEFI.

## Contexto fixo (não reinventar)

- Desenho canônico: [`docs/adr/0005-autonomia-v1-utilizavel.md`](../../docs/adr/0005-autonomia-v1-utilizavel.md), [`docs/desenho-autonomia-v1.md`](../../docs/desenho-autonomia-v1.md).
- Protótipo E7: [`docs/ambiente-autonomia-prototipo.md`](../../docs/ambiente-autonomia-prototipo.md); crate `agent/`; gate `scripts/verify-agent.sh` / `make verify-agent`.
- ADR 0001: autonomia **fora** do kernel; **não** exige o SO IA Livre.
- Runtime: subprocesso `ia-livre-runtime` (CPU default); GGUF canônico; sem exigir refactor em lib; GPU **não** é critério.
- Independente de kernel / harness / `node/` / P2P.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`; se não precisar, registrar.

## Decisão de implementação (única)

| Peça | Escolha |
|------|---------|
| Onde | Só `agent/` (+ docs/scripts/AGENTS/Makefile do gate do agente) |
| UX | `--prompt` one-shot; flags existentes (`--model` / `--memory` / `--n-predict` / `--runtime-bin`) |
| Sem `--prompt` | Cenário de prova compatível com E7 (marcadores `TOOL_OK` / `MEMORY_OK` / `AGENT_OK` + nota canônica) |
| Memória | JSONL; N=**8** entradas recentes no prompt; emitir `IA_LIVRE_MEMORY_POLICY_OK` quando a política for aplicada |
| Ferramentas | `note` (já existe), `recall` (listar/filtrar recentes), `help` (listar allowlist + contratos curtos) |
| Prova v1 | Invocação **determinística** de `note` **e** (`recall` **ou** `help`); ≥2 ferramentas; evidência stdout |
| Gate | Estender `verify-agent` **ou** documentar extensão explícita; não remover checks E7; não exigir QEMU |
| Docs | Atualizar ponte E7→v1 impl; AGENTS Como rodar/verificar; honestidade: desenho E15 agora tem código |

### Marcadores-alvo (stdout)

| Marcador | Papel |
|----------|--------|
| `IA_LIVRE_RUNTIME_USED=1` | Opcional E7 (manter se já emitido) |
| `IA_LIVRE_TOOL_OK` | E7 — pelo menos uma tool ok (`note`) |
| `IA_LIVRE_MEMORY_OK` | E7 — escrita + re-leitura |
| `IA_LIVRE_AGENT_OK` | E7 — cenário concluído |
| `IA_LIVRE_MEMORY_POLICY_OK` | **Novo** — política N=8 aplicada no prompt montado |
| Evidência ≥2 tools | Ex.: `IA_LIVRE_TOOLS_USED=2` e/ou `IA_LIVRE_TOOL=note` + `IA_LIVRE_TOOL=recall` (ou `help`) |

### Rejeitado

- Shell arbitrário, HTTP/rede, write fora do path de memória/workspace documentado
- REPL interativo, RAG/embeddings, multi-agente, marketplace, P2P-tools
- Agente no kernel / exigir SO IA Livre / QEMU no gate do agente
- Trocar modelo canônico ou exigir GPU
- Parsing espontâneo do SLM como **único** caminho do critério de prova

## Fora de escopo

- `kernel/`, `node/`, harness Linha A/B, GPU manager
- Refactor do `runtime/` em biblioteca compartilhada
- REPL, sandbox OS-level, integração Rede IA Livre
- Promover esta etapa a `em_andamento` / marcar `feita` (agente principal)
- Mudança de manifesto ou ADR 0001 / 0005 (só pontes “implementado”)

## Critérios de aceite

- [x] `ia-livre-agent` aceita `--prompt` e monta prompt com últimas N=8 entradas do JSONL
- [x] Allowlist `note` / `recall` / `help` implementada; proibidos shell/HTTP/RAG
- [x] Cenário de prova emite marcadores E7 + `IA_LIVRE_MEMORY_POLICY_OK` + evidência de ≥2 ferramentas
- [x] `make verify-agent` preservado ou estendido documentado; exit 0 com GGUF; sem QEMU
- [x] Docs (ambiente-autonomia e/ou desenho + AGENTS) refletem a v1 implementada; README avaliado
- [x] Sem dependência do SO IA Livre

## Riscos e rollback

- **Risco:** quebrar compat E7 (gate antigo falha) → manter path sem `--prompt` + checks E7; estender só com marcadores novos.
- **Risco:** prova depender do SLM emitir tool-call → invocação determinística no cenário (como E7).
- **Risco:** allowlist inchada (shell) → rejeitar; só as 3 ferramentas.
- **Risco:** N confuso (configurável vs fixo) → N=8 **fixado** no código/docs nesta etapa (sem flag `--memory-n` obrigatória).
- **Rollback:** reverter `agent/` + script/docs da extensão; protótipo E7 volta a ser o contrato.

## Etapa do roadmap

- Etapa 24 — Autonomia v1 utilizável (impl. em agent/) (`pendente`, Issue [#24](https://github.com/eriksonlima/projeto-ia-livre/issues/24))
- Spec: `specs/autonomia-v1-impl/`
- Pronto quando (roadmap): implementação no host em `agent/` com `--prompt` one-shot, allowlist `note`/`recall`/`help`, política de memória N=8 no prompt, cenário de prova com ≥2 ferramentas e marcadores (`IA_LIVRE_MEMORY_POLICY_OK` + evidência de ferramentas); `make verify-agent` preservado ou estendido documentado; sem exigir SO IA Livre; sem shell/HTTP/REPL/RAG.
