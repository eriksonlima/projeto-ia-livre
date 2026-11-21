# Spec — Tool `read_local` allowlisted (host)

Etapa 54 · Issue [#54](https://github.com/eriksonlima/projeto-ia-livre/issues/54) (ex-B48)  
Depende: Etapa 40 (`calc` sandboxed); Etapa 53 (REPL) já feita — integração REPL desejável, não bloqueante do Pronto quando.

---

## Resultado visível

O crate `agent/` (`ia-livre-agent`) ganha a ferramenta **`read_local`** na allowlist, no host Linux (`std`), **sem** exigir o SO IA Livre (ADR 0001), **sem** shell e **sem** HTTP/rede:

1. **Tool `read_local`** — lê o conteúdo (ou trecho documentado) de um path **só** se estiver sob a allowlist de roots (ex.: `build/agent-memory/` e/ou diretório de fixtures versionado, documentado no contrato).
2. **Rejeição honesta** — path fora da allowlist, traversal (`..`), symlink escapando o root, ou path inexistente → erro claro **sem** panic e **sem** vazar conteúdo de fora.
3. **Sem write arbitrário** — esta tool é **somente leitura**; write continua restrito ao JSONL de memória (`note` / kinds `tool`); **proibido** criar/alterar arquivos arbitrários.
4. **Gate** — `make verify-agent` estendido (estágio e/ou fixture) com evidência `read_local` **além** da regressão E7/v1/E40/E53; GGUF ainda exigido; **sem** QEMU/UEFI/nó P2P.
5. **REPL (desejável)** — comando `read_local <path>` no modo scripted (`--repl-script`), atualizando fixture se couber na mesma fatia de implementação.

Marcadores novos (mínimo a fixar na Task 1): `IA_LIVRE_TOOL=read_local`, `IA_LIVRE_READ_LOCAL_OK` (após leitura allowlisted bem-sucedida). Opcional: `IA_LIVRE_READ_LOCAL_BYTES=` ou path canônico ecoado.

---

## Contexto fixo (não reinventar)

- v1: [`docs/desenho-autonomia-v1.md`](../../docs/desenho-autonomia-v1.md), ADR [`0005`](../../docs/adr/0005-autonomia-v1-utilizavel.md).
- E40 `calc`: [`docs/autonomia-alem-v1.md`](../../docs/autonomia-alem-v1.md) — `read_local` estava **adiado**; esta etapa cumpre o item.
- E53 REPL: [`docs/autonomia-repl.md`](../../docs/autonomia-repl.md) — allowlist atual `note`/`recall`/`help`/`calc`; estender com `read_local`.
- Bridge E49 / Rede E52: **independentes** — `verify-agent` não depende do SO.
- Gate atual: `scripts/verify-agent.sh` / `make verify-agent` — E7 + v1 + `calc`/`TOOL_SANDBOX_OK` + `REPL_OK`.
- Runtime: subprocesso `ia-livre-runtime`; GGUF canônico; GPU **não** é critério.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho

### Superfície `read_local`

| Peça | Escolha nesta etapa |
|------|---------------------|
| Superfície | Uma tool: `read_local` |
| Args | `path: string` — relativo ao CWD do processo **ou** absoluto; normalizado antes do check |
| Allowlist de roots | Documentar **≥1** root canônico; default sugerido: (a) diretório pai do `--memory` **ou** `build/agent-memory/` e (b) `agent/fixtures/` (leitura de fixture de prova) — roots exatos fixados na Task 1 |
| Resolução | Canonicalizar (`canonicalize` / equivalente) e exigir que o resultado **comece** com um root allowlisted; rejeitar `..` e symlink que escape |
| Conteúdo | Texto UTF-8; limite de tamanho documentado (ex. 64 KiB) — truncar com aviso **ou** rejeitar se maior (escolher na Task 1; preferir rejeitar com erro honesto) |
| Saída | Eco legível (prefixo `read_local:`) + registro JSONL kind `tool`; **não** dumpar binário |
| Write | **Proibido** nesta tool; sem flags de escrita |
| Integração prova | Invocação **determinística** (path fixture versionado) no path sem `--prompt` **e/ou** via `--repl-script` |
| `help` | Incluir `read_local` na lista |
| Independência SO | Host Linux `std` apenas |

### Fluxo canônico (prova — gate)

```
# Opção A — prova clássica estendida
agent (sem --prompt)
  → … E7/v1/E40 …
  → read_local(<fixture allowlisted>)
  → IA_LIVRE_TOOL=read_local
  → IA_LIVRE_READ_LOCAL_OK
  → IA_LIVRE_AGENT_OK

# Opção B — estágio REPL (desejável)
agent --repl-script <fixture com read_local …>
  → IA_LIVRE_REPL_MODE=scripted
  → read_local …
  → IA_LIVRE_TOOL=read_local + READ_LOCAL_OK
  → IA_LIVRE_REPL_OK
```

O gate deve exigir marcadores `read_local` **sem** enfraquecer E7/v1/E40/E53. Preferir: (1) fixture de conteúdo sob `agent/fixtures/` (ex. `read-local-smoke.txt`) + (2) estágio ou chamada determinística que leia esse arquivo; teste negativo documentado (path fora da allowlist) no script ou unit test.

### Fixture mínima

Arquivo versionado sob root allowlisted (ex. `agent/fixtures/read-local-smoke.txt`) com texto curto estável. Fixture REPL (se Task 2 incluir): linha `read_local agent/fixtures/read-local-smoke.txt` (+ `quit`).

---

## Conteúdo obrigatório

### 1. Documentação

- Atualizar `docs/autonomia-alem-v1.md` (Futuro `read_local` → implementado E54) **e/ou** contrato curto `docs/autonomia-read-local.md` + pontes — preferir **um** contrato canônico claro + ponte em `autonomia-alem-v1.md` / `autonomia-repl.md` / `desenho-autonomia-v1.md`.
- Fixar roots da allowlist, limite de bytes, erros e marcadores.
- `AGENTS.md`: Como rodar / Como verificar com `read_local`.
- README: avaliar `readme-por-fatia`.

### 2. Código em `agent/`

- `tool_read_local` (módulo ou função) com check de allowlist + leitura segura.
- Atualizar `tool_help` e allowlist do REPL (`repl.rs`).
- Prova determinística e/ou fixture scripted.
- **Sem** `std::process::Command` para a tool; **sem** HTTP; **sem** write de arquivo arbitrário.

### 3. Gate

- `scripts/verify-agent.sh`: exigir `IA_LIVRE_TOOL=read_local` + `IA_LIVRE_READ_LOCAL_OK`; regressão E7/v1/E40/E53 intacta.
- Negativo: path fora da allowlist documentado (unit test ou check no script).

---

## Fora de escopo

- Shell, HTTP, write arbitrário, edição in-place de arquivos, upload/download
- RAG, multi-agente, tools via parsing espontâneo do SLM como critério de gate
- `kernel/`, `node/`, harness, bridge E49/E52, GPU obrigatória
- Leitura de `/etc`, `$HOME` genérico, secrets, `.env` — **fora** da allowlist
- Agente no guest UEFI / exigir SO IA Livre
- Marketplace / P2P-tools
- Promover etapa a `feita` (agente principal após gate + revisor)

---

## Critérios de aceite

- [ ] `read_local` na allowlist; leitura só sob roots documentados
- [ ] Path fora da allowlist / traversal rejeitado com erro honesto (sem panic)
- [ ] **Sem** write arbitrário via esta tool
- [ ] Prova/gate emite `IA_LIVRE_TOOL=read_local` + `IA_LIVRE_READ_LOCAL_OK`
- [ ] `make verify-agent` verde com GGUF; regressão E7/v1/E40/E53 preservada
- [ ] Contrato + pontes; README avaliado
- [ ] REPL scripted com `read_local` **desejável** (aceite pleno se gate cobrir via prova clássica; preferir ambos)
- [ ] **Sem** shell/HTTP; **sem** dependência do SO IA Livre

---

## Riscos e rollback

- **Risco:** path traversal / symlink escape → canonicalize + prefix check obrigatório; review na Task 2.
- **Risco:** allowlist larga demais (`/` ou `$HOME`) → roots **fechados** e versionados no contrato; default só memory-dir + fixtures.
- **Risco:** dump de arquivo grande no gate → limite de bytes + fixture pequena.
- **Risco:** quebrar REPL E53 → estender parser; manter `REPL_OK` nos greps existentes.
- **Rollback:** reverter tool + estágio do script + doc; E40/E53 permanecem contrato.

---

## Etapa do roadmap

- Etapa 54 — Tool `read_local` allowlisted (host) (`em_andamento`, Issue [#54](https://github.com/eriksonlima/projeto-ia-livre/issues/54))
- Spec: `specs/read-local-allowlisted/`
- Pronto quando: leitura só sob allowlist de paths; rejeição honesta fora; gate; sem write arbitrário.
