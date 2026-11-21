# Spec — Autonomia além de v1 (tool sandboxed `calc`)

Etapa 40 · Issue [#39](https://github.com/eriksonlima/projeto-ia-livre/issues/39) (ex-B33)  
Depende: Etapa 7 (protótipo), Etapa 15/24 (desenho + impl. v1 em `agent/`).

---

## Resultado visível

O crate `agent/` (`ia-livre-agent`) ganha **≥1 ferramenta nova em sandbox explícito**, sem exigir o SO IA Livre (ADR 0001), **sem** shell irrestrito e **sem** HTTP/rede:

1. **Ferramenta `calc`** — avalia expressões aritméticas **puras** (subset fixo: dígitos, `.`, `+`, `-`, `*`, `/`, parênteses, espaços); resultado em stdout e kind `tool` no JSONL.
2. **Allowlist v1 preservada** — `note` / `recall` / `help` inalterados; política memória N=8 e `--prompt` one-shot mantidos.
3. **Cenário de prova estendido** — invocação **determinística** de `calc` (não depende do SLM) no path sem `--prompt`; regressão E7 + v1 intacta.
4. **Gate** — `make verify-agent` estendido com evidência de `calc` + marcador de sandbox; **sem** QEMU/UEFI/nó P2P.

**REPL interativo:** fora desta etapa (ver decisão abaixo); permanece no backlog.

Marcadores novos (mínimo): `IA_LIVRE_TOOL=calc`, `IA_LIVRE_TOOL_SANDBOX_OK` (ou equivalente fixado na Task 1) quando `calc` concluir com expressão permitida.

---

## Contexto fixo (não reinventar)

- v1 implementada: [`docs/desenho-autonomia-v1.md`](../../docs/desenho-autonomia-v1.md), ADR [`0005`](../../docs/adr/0005-autonomia-v1-utilizavel.md), spec E24 `specs/autonomia-v1-impl/`.
- Protótipo E7: [`docs/ambiente-autonomia-prototipo.md`](../../docs/ambiente-autonomia-prototipo.md).
- Gate atual: `scripts/verify-agent.sh` / `make verify-agent` — E7 + `MEMORY_POLICY_OK` + ≥2 tools.
- Runtime: subprocesso `ia-livre-runtime`; GGUF canônico; GPU **não** é critério.
- Independente de `kernel/`, `node/`, harness Linha A/B.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho (única — obrigatória)

### Avaliação REPL vs tool sandboxed

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A** | REPL interativo mínimo (`--repl`, stdin/stdout) | **Rejeitada nesta etapa** — gate CI não interativo; UX e timeouts mais frágeis que extensão da allowlist |
| **B** | Tool `calc` (expressão aritmética pura, parser restrito) | **Escolhida** — sandbox auditável, prova determinística, alinha ao padrão v1 |
| **C** | Tool `read_local` (leitura allowlisted de arquivos) | **Adiada** — superfície de FS maior; candidata a etapa/backlog seguinte |
| **D** | Shell / `sh -c` / HTTP client | **Rejeitada** — contradiz Pronto quando e ADR 0005 |
| **E** | Só documentar sem código | **Rejeitada** — roadmap exige gate |

### Escolha: **B — ferramenta `calc` sandboxed**

| Peça | Escolha nesta etapa |
|------|---------------------|
| Superfície nova | Uma tool: `calc` |
| Args | `expr: string` — expressão única; rejeitar vazio, overflow não tratado e divisão por zero com erro honesto |
| Charset permitido | `0-9`, `.`, `+`, `-`, `*`, `/`, `(`, `)`, espaço — **rejeitar** qualquer outro byte (letras, `=`, `^`, `,`, `;`, newline em `expr`, etc.) |
| Avaliação | Parser próprio ou crate mínima **sem** `eval` de código arbitrário; **proibido** `std::process::Command`, `unsafe` FFI, rede, leitura de arquivo |
| Saída | Linha legível `calc: <expr> = <resultado>` + registro JSONL kind `tool` |
| Integração SLM | Opcional no futuro; **critério de prova** = invocação determinística no binário (como `note`/`recall` hoje) |
| `help` | Atualizar texto da allowlist incluindo `calc` |
| Prova sem `--prompt` | Manter sequência E7/v1 existente **e** chamar `calc` com expressão fixa documentada (ex. `1+2*3`) antes de `IA_LIVRE_AGENT_OK` |
| Marcadores | `IA_LIVRE_TOOL=calc`; `IA_LIVRE_TOOL_SANDBOX_OK` após sucesso; preservar todos os marcadores E7/v1 |
| Independência SO | Host Linux `std` apenas |

### Fluxo canônico (prova — gate)

```
agent (sem --prompt)
  → runtime subprocess (inalterado)
  → note + recall + help (v1)
  → calc("1+2*3") → 7
  → IA_LIVRE_TOOL=calc
  → IA_LIVRE_TOOL_SANDBOX_OK
  → … IA_LIVRE_AGENT_OK
```

---

## Conteúdo obrigatório

### 1. Documentação

- Novo contrato: `docs/autonomia-alem-v1.md` — tool `calc`, subset de expressão, erros, marcadores, limites e futuro (REPL, `read_local`).
- Ponte em `docs/desenho-autonomia-v1.md` (tabela «futuro» → «E40 implementado: calc»).
- `AGENTS.md`: **Como rodar** / **Como verificar** com menção a `calc` e extensão do gate.
- ADR 0005: addendum curto («sandbox `calc` E40») **ou** só doc se não alterar fronteira v1 — preferir addendum mínimo.

### 2. Código em `agent/`

- `tool_calc` (módulo ou função) com validação de charset + avaliação segura.
- Atualizar `tool_help` e cenário de prova.
- **Sem** novas deps pesadas (evitar LangChain); crate de expr pura só se auditável e sem `eval` dinâmico de linguagem completa.

### 3. Gate

- `scripts/verify-agent.sh`: exigir `IA_LIVRE_TOOL=calc` e `IA_LIVRE_TOOL_SANDBOX_OK`; regressão E7/v1.
- Teste negativo opcional no script ou unit test: rejeitar `expr` com `;` ou letras (documentar onde vive o check).

---

## Fora de escopo

- REPL interativo (`--repl`), RAG/embeddings, multi-agente, integração `node/` / P2P-tools
- `read_local`, shell, HTTP, write fora do JSONL de memória
- `kernel/`, harness, runtime refactor em lib, GPU obrigatória
- Agente no SO IA Livre / QEMU no gate do agente
- Promover etapa a `feita` (agente principal após gate)

---

## Critérios de aceite

- [ ] `calc` na allowlist; expressões fora do subset falham com erro claro (sem panic)
- [ ] Prova sem `--prompt` chama `calc` de forma determinística e emite `IA_LIVRE_TOOL=calc` + `IA_LIVRE_TOOL_SANDBOX_OK`
- [ ] Marcadores E7 + v1 preservados no gate
- [ ] `make verify-agent` verde com GGUF; sem QEMU
- [ ] `docs/autonomia-alem-v1.md` + pontes; README avaliado
- [ ] **Sem** shell/HTTP irrestrito; **sem** dependência do SO IA Livre

---

## Riscos e rollback

- **Risco:** `calc` vira passarela para código arbitrário → charset fechado + sem `Command`/`eval` de linguagem; revisão na Task 2.
- **Risco:** quebrar gate v1 → adicionar checks **sem** remover greps existentes.
- **Risco:** dep numérica / float → documentar precisão (f64 aceitável); prova usa inteiros simples.
- **Rollback:** reverter `agent/` + script/doc; v1 volta a ser contrato.

---

## Etapa do roadmap

- Etapa 40 — Autonomia além de v1 (REPL ou tool sandboxed) (`em_andamento`, Issue [#39](https://github.com/eriksonlima/projeto-ia-livre/issues/39))
- Spec: `specs/autonomia-alem-v1/`
- Pronto quando: REPL ou ≥1 tool nova sandboxed + gate; sem shell/HTTP irrestrito.