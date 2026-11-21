# Spec — Autonomia mínima no caminho nativo (ou bridge SO↔host)

Etapa 49 · Issue [#49](https://github.com/eriksonlima/projeto-ia-livre/issues/49) (ex-B43)  
Depende: E7/E24/E40 (`agent/` host) · E20 (contrato nativo / marcadores) · E44 (geração nativa BlockIO subset) · E48 (`B_BLOCK_METAL=no_gguf_metal_io`).

---

## Resultado visível

Existe um caminho **verificável** em que a camada de autonomia (one-shot ou bridge) **consome evidência do runtime nativo / path metal** **ou** um **contrato explícito host↔nativo** com gate automatizado — **sem** shell irrestrito, **sem** rede guest, **sem** mover o agente para dentro do kernel, e com **ADR 0001 preservada** (autonomia fora do kernel; autonomia host **não exige** o SO IA Livre).

| Caminho | Condição | Esperado |
|---------|----------|----------|
| **A — Agente mínimo no guest** | Guest pós-ExitBoot com loop de agente + allowlist **sem** shell/rede | Marcadores de agente no serial nativo + gate QEMU |
| **B — Bridge / contrato host↔nativo** | Host consome serial/log nativo (BlockIO E44 e/ou metal E48) **ou** subprocesso documentado que prova o vínculo | Contrato + marcadores `IA_LIVRE_BRIDGE_*` (ou equivalente) + gate; allowlist intacta |
| **C — Só documentação** | A e B inviáveis após tentativa registrada | Doc de inviabilidade + critérios; **não** fecha o Pronto quando sozinho (só se A/B bloqueados com evidência) |

**Preferência:** **B** se A for inviável (estado atual: guest sem shell/rede/FS de agente; metal sem I/O GGUF completo).

---

## Contexto fixo (não reinventar)

- **ADR 0001** ([`docs/adr/0001-separacao-camadas-e-p2p.md`](../../docs/adr/0001-separacao-camadas-e-p2p.md)): agentes **fora** do kernel; participar da Rede / usar o SO **não** são pedágio da autonomia host.
- **ADR 0005** / E7–E40: `agent/` no host consome `ia-livre-runtime` (subprocesso); allowlist `note`/`recall`/`help`/`calc`; **proibido** shell/HTTP; gate `make verify-agent`.
- **E44:** geração nativa subset só no path **BlockIO QEMU** (`LOAD_KIND=gguf`, `TOKENS_PER_S` medidos); espécie ≠ canônica.
- **E48 / ADR 0017:** path metal = SFS/ESP; desfecho `B_BLOCK_METAL=no_gguf_metal_io`; `make verify-metal-infer` — **≠** geração metal; **≠** `METAL_OK`.
- **E20:** shim/contrato nativo host (`RUNTIME_CONTRACT_*`) ≠ Linha B; harness B reemite `HARNESS_CONTRACT_*`.
- Hipótese A vs B / comparable: **não** forçar `COMPROVA` nesta etapa.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A — Agente no guest UEFI** | Loop autonomia pós-ExitBoot no kernel/runtime-native com tools | **Improvável nesta etapa** — sem shell/rede/FS de agente; violaria ADR 0001 se embutir agente no kernel; custo alto vs valor |
| **B — Bridge host↔nativo** | Contrato + consumidor host que prova vínculo com serial/log nativo (QEMU BlockIO e/ou metal) ou subprocesso documentado; allowlist preservada | **Preferida / escolhida se A inviável** |
| **C — Só docs** | Documentar fronteira sem gate de bridge | **Rejeitada como desfecho único** — Pronto quando exige gate; aceitável só como registro de bloqueio se B também falhar |
| **D — Agente chama llama.cpp e finge “nativo”** | Reusar só `verify-agent` / runtime host como prova nativa | **Rejeitada** — fraude de path |
| **E — Shell / `sh -c` / HTTP no bridge** | Ferramentas irrestritas para “orquestrar” QEMU | **Rejeitada** — contradiz Pronto quando e ADR 0005 |

### Escolha: **B — bridge / contrato host↔nativo** (default desta etapa)

| Peça | Nesta etapa |
|------|-------------|
| Onde vive o agente | Continua no **host** (`agent/` e/ou binário/script de bridge fino documentado) — **não** no kernel |
| O que é “consumir nativo” | Ler e validar marcadores de uma corrida nativa **já existente** (serial QEMU Line B / `verify-metal-infer` / log capturado) **ou** invocar **um** subprocesso documentado cujo stdout é o contrato (ex. harness B / metal-infer) e então emitir marcadores de bridge |
| Fonte nativa mínima | **BlockIO QEMU (E44)** como evidência de geração nativa; path **metal (E48)** como evidência honesta de bloqueio (`B_BLOCK_METAL`) — bridge deve distinguir os dois |
| Allowlist | Reusar tools E40 (`note`/`recall`/`help`/`calc`) se o one-shot passar pelo `agent/`; bridge puro **não** precisa de tools novas — **proibido** shell/HTTP |
| Marcadores (mínimo) | Namespace `IA_LIVRE_BRIDGE_*` (nomes fixados na Task 1), ex.: `BRIDGE_MODE=host_native`, `BRIDGE_NATIVE_SRC=blockio\|metal_block`, `BRIDGE_OK` |
| Gate | Novo `make verify-…` **adicional** (não substitui `verify-agent`); default CI **não** exige PC físico |
| ADR | Novo ADR **somente** se a fronteira bridge for decisão estrutural estável (recomendado na Task 1); senão doc de contrato + ponte ADR 0001/0005 |
| ADR 0001 | Intacta: autonomia host sem SO; bridge **não** torna o SO obrigatório para `verify-agent` |
| Hipótese A vs B | Não comprovada; bridge ≠ prova comparable |

### Justificativa

- Fecha B43 sem exigir SO completo nem agente no guest.
- Reusa evidência nativa já paga (E44/E48) em vez de reinventar inferência.
- Mantém sandbox de ferramentas e independência do SO para o caminho host clássico.

### Rejeitado (explícito)

- Embutir loop de agente / allowlist no `kernel/`.
- Declarar autonomia “nativa” só com `ia-livre-runtime` host.
- Shell irrestrito, HTTP, ou escrita fora dos paths já allowlisted.
- Inventar `TOKENS_PER_S` / `METAL_OK` / geração metal inexistente.
- Forçar `COMPROVA` no harness comparable.
- Exigir PC físico no gate default.

---

## Conteúdo obrigatório

### 1. Documentação / contrato

- Novo contrato (sugestão): `docs/autonomia-bridge-nativo.md` — o que a bridge prova e o que **não** prova; tabela fontes (`blockio` vs `metal_block`); marcadores; fluxo one-shot; relação com E7/E24/E40 e ADR 0001.
- Pontes em `docs/desenho-autonomia-v1.md` / `docs/autonomia-alem-v1.md` / `docs/runtime-nativo-linha-b.md` (ou equivalentes).
- ADR novo **ou** addendum curto em 0001/0005 se a fronteira bridge for estável.
- `AGENTS.md`: Como rodar / Como verificar o gate da bridge.

### 2. Implementação mínima

- Consumidor host (extensão de `agent/` **ou** script/`crate` fino sob `scripts/` / workspace) que:
  1. obtém evidência nativa (arquivo de log **ou** subprocesso documentado);
  2. valida marcadores mínimos da fonte escolhida;
  3. emite `IA_LIVRE_BRIDGE_*` + encerra com sucesso/falha honesta.
- One-shot opcional: `--prompt` do agente **após** bridge OK **não** é obrigatório se o Pronto quando for cumprido só com bridge+gate; se implementado, allowlist intacta.

### 3. Gate

- `make verify-…` (nome fixado na Task 1, ex. `verify-agent-bridge` / `verify-bridge-nativo`).
- Exige `BRIDGE_OK` (ou equivalente) + fonte nativa válida.
- Regressão: `make verify-agent` permanece verde e **independente** do SO.
- Gates kernel/harness/metal-infer **não** regridem.

---

## Fora de escopo

- Agente completo no SO / REPL no guest / rede no guest.
- Remover `B_BLOCK_METAL` ou implementar I/O GGUF metal completo (já E48).
- Prefill/Decode 22L×32; veredito `COMPROVA`.
- Integração Rede IA Livre / P2P-tools no agente.
- Shell, HTTP, `read_local` (B48), REPL host (B47).
- GPU nativa; alterar `verify-agent` para exigir QEMU.
- Promover etapa a `feita` (agente principal após gate).

---

## Critérios de aceite

- [ ] Decisão A vs B vs C registrada; desfecho **B** (ou inviabilidade documentada com evidência).
- [ ] Contrato host↔nativo em `docs/` com marcadores, fontes (`blockio` / `metal_block`) e proibições (shell, fraude host-as-native).
- [ ] Bridge/one-shot verificável emite marcadores de bridge e consome evidência nativa real (serial/log/subprocesso documentado).
- [ ] Gate automatizado adicional verde no host de referência; **sem** exigir PC; ADR 0001 preservada (`verify-agent` sem SO).
- [ ] **Sem** shell irrestrito; allowlist E40 não expandida para shell/HTTP.
- [ ] `AGENTS.md` atualizado; `README.md` avaliado (`readme-por-fatia`).
- [ ] Não inventa `METAL_OK` / tokens metal / hipótese comprovada.

---

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| Confundir runtime host com nativo | Marcadores `BRIDGE_NATIVE_SRC=`; docs explícitos; gate falha se só houver `INFER_OK` host |
| Gate frágil (QEMU lento) | Opt-in timeout; reusar log fixture gerado por script existente; ou subprocesso com timeout documentado |
| Pressão por agente no kernel | Critério escrito: A rejeitada nesta etapa |
| Shell “só para QEMU” | Subprocesso allowlisted (scripts do repo) ≠ shell irrestrito do usuário; sem `sh -c` genérico |
| Colisão com `verify-agent` | Gate novo adicional; não exigir QEMU no gate clássico |

Rollback: remover gate/scripts da bridge; `agent/` e gates E40/E44/E48 intactos.

---

## Etapa do roadmap

- Etapa 49 `em_andamento` — Autonomia mínima no caminho nativo (ou bridge SO↔host)
- Pronto quando: agente one-shot (ou bridge verificável) consome runtime nativo/metal **ou** contrato explícito host↔nativo com gate; sem shell irrestrito; ADR 0001 preservada.
