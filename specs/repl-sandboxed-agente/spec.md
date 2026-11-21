# Spec — REPL sandboxed no agente (host)

Etapa 53 · Issue [#53](https://github.com/eriksonlima/projeto-ia-livre/issues/53) (ex-B47)  
Depende: Etapa 40 (`calc` sandboxed + allowlist `note`/`recall`/`help`/`calc`).

---

## Resultado visível

O crate `agent/` (`ia-livre-agent`) ganha um **REPL sandboxed** no host Linux (`std`), **sem** exigir o SO IA Livre (ADR 0001), **sem** shell e **sem** HTTP/rede:

1. **Flag `--repl`** — loop interativo stdin/stdout que aceita apenas comandos da allowlist existente (`note` / `recall` / `help` / `calc`); demais linhas rejeitadas com erro honesto (sem panic).
2. **Modo scripted (não interativo)** — `--repl-script <FILE>` **ou** linhas via stdin não-TTY / equivalente documentado, para o gate CI não depender de teclado.
3. **Allowlist intacta** — mesmas tools e sandboxes de E24/E40; `calc` permanece charset-fechado; **proibido** `Command`, shell, HTTP, FS arbitrário, `read_local`.
4. **Gate** — `make verify-agent` estendido com evidência REPL (marcadores novos) **além** da regressão E7/v1/E40; GGUF ainda exigido; **sem** QEMU/UEFI/nó P2P.

Marcadores novos (mínimo a fixar na Task 1): `IA_LIVRE_REPL_MODE=` ∈ {`interactive`,`scripted`}, `IA_LIVRE_REPL_OK` após sessão scripted bem-sucedida com ≥1 tool da allowlist.

---

## Contexto fixo (não reinventar)

- v1: [`docs/desenho-autonomia-v1.md`](../../docs/desenho-autonomia-v1.md), ADR [`0005`](../../docs/adr/0005-autonomia-v1-utilizavel.md).
- E40 `calc`: [`docs/autonomia-alem-v1.md`](../../docs/autonomia-alem-v1.md) — REPL estava **adiado**; esta etapa cumpre o item futuro.
- Bridge E49 / Rede E52: **independentes** — `verify-agent` não depende do SO.
- Gate atual: `scripts/verify-agent.sh` / `make verify-agent` — E7 + v1 + `TOOL=calc` + `TOOL_SANDBOX_OK`.
- Runtime: subprocesso `ia-livre-runtime`; GGUF canônico; GPU **não** é critério.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho

### Superfície REPL

| Peça | Escolha nesta etapa |
|------|---------------------|
| Flag | `--repl` ativa o loop |
| Scripted | `--repl-script <FILE>` (preferido no gate); alternativa documentada: stdin com EOF |
| Precedência | Com `--repl-script`: modo scripted (não interativo). `--repl` sozinho: interativo. Sem ambos: comportamento atual (prova / `--prompt`) |
| Conflito | `--prompt` + `--repl` / `--repl-script`: rejeitar com erro claro **ou** documentar precedência única (preferir: erro) |
| Linha de comando | Formato mínimo: `tool <args…>` alinhado à allowlist (ex. `help`, `note texto`, `recall`, `calc 1+2*3`); linhas vazias ignoradas; `quit`/`exit` encerra |
| SLM no loop | **Opcional** nesta etapa — critério de aceite **não** exige inferência por turno; prova scripted pode ser **só tools** (determinística). Se o loop chamar runtime, reutilizar flags `--model` / `--n-predict` existentes |
| Saída | Eco legível por comando + marcadores ao fim; kinds JSONL `tool` inalterados |
| Independência SO | Host Linux `std` apenas |

### Fluxo canônico (prova — gate)

```
agent --repl-script <fixture>
  → IA_LIVRE_REPL_MODE=scripted
  → help (ou note/recall/calc da fixture)
  → … allowlist only …
  → IA_LIVRE_REPL_OK
  → (regressão E7/v1/E40 permanece no path sem --repl)
```

O gate pode: (a) rodar a prova clássica **e** um estágio REPL scripted, ou (b) incorporar linhas scripted no mesmo processo — desde que marcadores E7/v1/E40 **e** `REPL_OK` sejam exigidos. Preferir **estágio adicional** curto no `verify-agent.sh` se simplificar timeouts.

### Fixture scripted (mínimo)

Arquivo versionado (ex. `agent/fixtures/repl-smoke.txt` ou `scripts/fixtures/…`) com ≥2 linhas allowlist (ex. `help` + `calc 1+2*3`) e `quit`. **Sem** shell/HTTP nas linhas.

---

## Conteúdo obrigatório

### 1. Documentação

- Atualizar `docs/autonomia-alem-v1.md` (seção Futuro REPL → implementado E53) **ou** novo `docs/autonomia-repl.md` com ponte clara — preferir **um** contrato canônico curto (`docs/autonomia-repl.md`) + ponte em `autonomia-alem-v1.md` / `desenho-autonomia-v1.md`.
- `AGENTS.md`: Como rodar (`--repl` / `--repl-script`) + Como verificar (marcadores REPL).
- README: avaliar `readme-por-fatia` (menção curta se a capa omitir a superfície nova).

### 2. Código em `agent/`

- Parser CLI: `--repl`, `--repl-script`.
- Loop sandboxed reutilizando `tool_*` existentes; **sem** novas tools.
- Rejeição honesta fora da allowlist.
- **Sem** `std::process::Command` para tools; **sem** HTTP.

### 3. Gate

- `scripts/verify-agent.sh`: estágio scripted exige `IA_LIVRE_REPL_MODE=scripted` + `IA_LIVRE_REPL_OK`; regressão E7/v1/E40 intacta.
- Timeout: reutilizar `VERIFY_AGENT_TIMEOUT` ou documentar sub-timeout se houver segundo processo.

---

## Fora de escopo

- Shell, HTTP, `read_local`, write fora do JSONL de memória
- RAG, multi-agente, tools via parsing espontâneo do SLM como critério de gate
- `kernel/`, `node/`, harness, bridge E49/E52, GPU obrigatória
- REPL no guest UEFI / exigir SO IA Livre
- Marketplace / P2P-tools
- Promover etapa a `feita` (agente principal após gate + revisor)

---

## Critérios de aceite

- [ ] `--repl` inicia loop sandboxed; allowlist `note`/`recall`/`help`/`calc` apenas
- [ ] `--repl-script FILE` (ou equivalente documentado) roda sem TTY e emite `IA_LIVRE_REPL_MODE=scripted` + `IA_LIVRE_REPL_OK`
- [ ] Comando fora da allowlist / tentativa shell-like rejeitada sem panic
- [ ] `make verify-agent` verde com GGUF; exige marcadores REPL **e** regressão E7/v1/E40
- [ ] Contrato documentado + pontes; README avaliado
- [ ] **Sem** shell/HTTP; **sem** dependência do SO IA Livre

---

## Riscos e rollback

- **Risco:** gate interativo trava CI → modo scripted obrigatório no verify; interativo só manual.
- **Risco:** REPL vira shell → allowlist fechada + review; nenhum `Command` novo para tools.
- **Risco:** timeout duplo (prova + REPL) → fixture curta; só tools no scripted se possível.
- **Risco:** conflito `--prompt`/`--repl` → rejeição explícita na CLI.
- **Rollback:** reverter flags/loop + estágio do script; E40 permanece contrato.

---

## Etapa do roadmap

- Etapa 53 — REPL sandboxed no agente (host) (`em_andamento`, Issue [#53](https://github.com/eriksonlima/projeto-ia-livre/issues/53))
- Spec: `specs/repl-sandboxed-agente/`
- Pronto quando: `--repl` com allowlist; modo scripted para `verify-agent`; sem shell/HTTP.
