# Spec — Autonomia consumindo runtime/evidência nativa

Etapa 70 · Issue [#70](https://github.com/eriksonlima/projeto-ia-livre/issues/70) (ex-B65)  
Depende: Etapa 49 (bridge host↔nativo — [`docs/autonomia-bridge-nativo.md`](../../docs/autonomia-bridge-nativo.md) / ADR [`0018`](../../docs/adr/0018-autonomia-bridge-host-nativo.md)); `agent/` host (E7/E24/E40); evidência nativa E44 (blockio) / E48 (`metal_block`) / E63 (SFS full — **fora** do path bridge legado).

---

## Resultado visível

Existe um caminho **verificável** em que a autonomia no **host** **consome** evidência nativa já validada pela bridge E49 (além de só emitir `BRIDGE_OK`) **ou**, se A for inviável com evidência registrada, um contrato honesto **«bridge = máximo até X»** — **sem** agente no guest, **sem** shell irrestrito, **sem** inventar `TOKENS_PER_S` / `METAL_OK` / `COMPROVA`, e com **ADR 0001 preservada** (`make verify-agent` continua **independente** do SO / QEMU / UEFI).

| Caminho | Condição | Esperado |
|---------|----------|----------|
| **A — One-shot host consome evidência nativa (escolhido)** | Bridge E49 (`BRIDGE_OK` + `BRIDGE_NATIVE_SRC`) disponível via log/fixture ou subprocesso allowlisted | Consumidor host injeta/usa a evidência no loop de autonomia (ou script dedicado) + marcadores `IA_LIVRE_NATIVE_CONSUME_*` + gate aditivo |
| **B — Bridge = máximo até X (só se A colapsar)** | Consumir além de validar exigir agente no guest / TCP guest / fraudar host-as-native | Contrato + ADR curto: teto = E49; critérios de reabertura; gate prova o contrato — **sem** fingir consume |

**Preferência:** **A** (factível com scripts/`agent` host + evidência E49).

---

## Contexto fixo (não reinventar)

- **E49 / ADR 0018:** bridge valida serial/log e emite `BRIDGE_MODE=host_native`, `BRIDGE_NATIVE_SRC=blockio|metal_block`, `BRIDGE_OK`. **Não** é agente no guest. **Não** substitui `verify-agent`.
- Lacuna B65: bridge **só valida**; autonomia ainda **não usa** a evidência nativa no loop (memória/prompt/tools).
- **ADR 0001:** agentes **fora** do kernel; autonomia host **não exige** o SO IA Livre.
- **E44:** geração nativa subset BlockIO (`DECODE_OK` / `RUNTIME_NATIVE_OK`); espécie ≠ canônica.
- **E48:** path metal legado `B_BLOCK_METAL=no_gguf_metal_io` (bridge força `METAL_INFER_MODE=legacy`).
- **E63:** `esp_sfs_full` — outro desfecho; **não** confundir com `metal_block` da bridge.
- Hipótese A vs B / comparable: **não** forçar `COMPROVA`.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A — One-shot host consome evidência nativa** | Após `BRIDGE_OK`, injetar SRC/marcadores no caminho de autonomia (memória/`--prompt`/tools allowlist) ou script dedicado; emitir `NATIVE_CONSUME_*`; gate aditivo | **Escolhida** |
| **B — Contrato «bridge = máximo até X»** | Documentar teto = E49 + ADR se A exigir guest/TCP/fraude | **Reserva** — só se Task 1 provar inviabilidade honesta de A |
| **C — Agente no guest / kernel** | Loop autonomia pós-ExitBoot | **Rejeitada** — ADR 0001; inviável (sem shell/rede/FS) |
| **D — Fingir host-llama como nativo** | `INFER_OK` host = “consumo nativo” | **Rejeitada** — fraude de path |
| **E — Inventar `TOKENS_PER_S` / `METAL_OK` / `COMPROVA`** | Métricas ou veredito falso a partir da bridge | **Rejeitada** |
| **F — Shell irrestrito / HTTP** | Orquestrar QEMU via `sh -c` genérico no agente | **Rejeitada** — ADR 0005 / allowlist |

### Escolha: **A — consumo host da evidência bridge (além de validar)**

| Peça | Nesta etapa |
|------|-------------|
| Onde | **Host** apenas — script dedicado (`scripts/run-autonomia-nativa.sh` ou nome fixado na Task 1) **e/ou** extensão mínima de `agent/` (flag/entrada de evidência). **Proibido** embutir agente no `kernel/` |
| O que é «consumir» (≠ E49) | E49 = **validar** log → `BRIDGE_*`. E70 = **usar** essa evidência no caminho de autonomia: gravar/injetar `BRIDGE_NATIVE_SRC` (+ resumo honesto dos marcadores nativos) em memória/`--prompt`/tool allowlist (`note`/`recall`/…) **antes ou durante** um one-shot, e provar o uso com marcadores `NATIVE_CONSUME_*` |
| Fonte | Reusar bridge: `blockio` (fixture/log) e/ou `metal_block` (subprocesso documentado). Default do gate: path rápido com fixture/log (como E49 blockio) — **sem** exigir PC físico |
| Marcadores (mínimo) | Família `IA_LIVRE_NATIVE_CONSUME_*` — Task 1 fixa nomes; mínimo sugerido: `MODE=host_bridge`, `SRC=blockio\|metal_block`, `OK`; **não** emitir `TOKENS_PER_S` nativo inventado |
| Relação com `BRIDGE_*` | Consumo **exige** `BRIDGE_OK` (subprocesso bridge ou log já bridged). `NATIVE_CONSUME_OK` **≠** substituto de `BRIDGE_OK` |
| Allowlist | Tools E40 intactas; **proibido** shell/HTTP; subprocesso allowlisted = scripts do repo (bridge / metal-infer), não shell do usuário |
| Gate | Novo `make verify-autonomia-nativa` (ou nome fixado) **aditivo**; **não** altera `verify-agent` para exigir QEMU/UEFI |
| ADR | Estender contrato E49 (novo doc ou seção em `autonomia-bridge-nativo.md` + ponte); ADR novo **só** se pivot B ou se a fronteira «consume ≠ validate» precisar de decisão estrutural além de 0018 |
| ADR 0001 | Intacta: `verify-agent` sem SO; consumo nativo é caminho **adicional** |

### Justificativa (por que A, não B agora)

- Bridge E49 já entrega evidência estruturada no host — falta só o elo autonomia→evidência (B65).
- Não exige agente no guest, TCP pós-Exit, nem GPU/metal full.
- Fecha o Pronto quando com one-shot verificável sem fraudar métricas.
- B só se «consumir» for redefinido como agente no guest ou caminho que viole ADR 0001 — aí documentar teto = E49.

### Pivot B (obrigatório se A colapsar)

Se na Task 1 ficar claro que o único «consumo» útil exige agente no guest, TCP guest, ou fingir host-as-native:

1. Parar implementação teatral de A.
2. Contrato «bridge = máximo até X» (X = E49 / ADR 0018) + ADR curto (próximo número livre) com critérios de reabertura.
3. Gate prova presença do contrato + marcador de teto (ex. `NATIVE_CONSUME_BLOCK=bridge_is_max`); **sem** `NATIVE_CONSUME_OK` fingido.
4. `verify-agent` / `verify-autonomia-bridge` permanecem.

---

## Conteúdo obrigatório

### 1. Documentação / contrato

- Contrato (sugestão): `docs/autonomia-nativa.md` **ou** seção «Consumo além da bridge» em `docs/autonomia-bridge-nativo.md` — o que E70 prova vs E49; marcadores `NATIVE_CONSUME_*`; fontes; proibições; pontes ADR 0001 / 0018.
- Se pivot B: ADR + critérios de reabertura explícitos.
- `AGENTS.md`: Como rodar / Como verificar o gate aditivo (Task 3).

### 2. Implementação mínima (A)

- Runner host que:
  1. obtém `BRIDGE_OK` (+ `BRIDGE_NATIVE_SRC`) via `./scripts/run-autonomia-bridge.sh` ou log equivalente;
  2. injeta evidência no caminho de autonomia (memória/`--prompt`/tool allowlist — Task 1 fixa o mecanismo mínimo);
  3. emite `IA_LIVRE_NATIVE_CONSUME_*` e encerra com sucesso/falha honesta.
- One-shot: preferir reusar `ia-livre-agent` com evidência injetada; script puro só é ok se provar «consumo» (não só reimprimir `BRIDGE_OK`).

### 3. Gate

- `make verify-autonomia-nativa` (nome final na Task 1).
- Exige `NATIVE_CONSUME_OK` + `SRC=` coerente com bridge + evidência de uso (não só eco de `BRIDGE_OK`).
- Regressão: `make verify-agent` verde **sem** QEMU; `make verify-autonomia-bridge` intacto.
- Default CI: fixture/log — **sem** PC físico; **sem** exigir `METAL_OK`.

---

## Fora de escopo

- Agente no guest / kernel; REPL UEFI; TCP Rede no guest (E66).
- Alterar `verify-agent` para depender de QEMU/UEFI/GGUF nativo.
- Inventar `TOKENS_PER_S` / `METAL_OK` / `COMPROVA` a partir da bridge.
- Shell irrestrito, HTTP, marketplace de tools.
- Trocar path bridge `metal_block` por E63 `esp_sfs_full` como fonte desta etapa (pode documentar diferença; não é o critério).
- Inferência multi-GPU; espécie canônica Linha B.
- Promover etapa a `feita` (agente principal após gate).

---

## Critérios de aceite

- [ ] Decisão A vs B registrada; desfecho **A** (ou pivot B com contrato/ADR e critérios de reabertura).
- [ ] Contrato documenta «consumir ≠ só validar» (E70 vs E49) + marcadores + proibições.
- [ ] One-shot/script host consome evidência bridge e emite `NATIVE_CONSUME_*` com prova de uso.
- [ ] Gate aditivo verde no host de referência; `verify-agent` independente do SO (ADR 0001).
- [ ] Sem shell irrestrito; sem `TOKENS_PER_S`/`METAL_OK`/`COMPROVA` inventados; sem agente no guest.
- [ ] `AGENTS.md` atualizado; `README.md` avaliado (`readme-por-fatia`).

---

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| Confundir «eco de BRIDGE_OK» com consumo | Critério: evidência injetada + uso observável (memória/tool/`--prompt`); gate falha se só reimprimir bridge |
| Quebrar ADR 0001 (`verify-agent` + QEMU) | Gate novo **aditivo**; regressão explícita sem SO |
| Fraudar host-llama como nativo | Exigir `BRIDGE_OK` + `NATIVE_CONSUME_SRC` alinhado a `blockio`/`metal_block` |
| Gate pesado (QEMU sempre) | Default fixture/log como E49 blockio |
| Pressão por agente no guest | A rejeita C; pivot B documenta teto |
| Shell «só para bridge» | Subprocesso = scripts do repo allowlisted; sem `sh -c` genérico no agent |

Rollback: remover runner/gate E70; E49/`agent`/gates clássicos intactos.

---

## Etapa do roadmap

- Etapa 70 `em_andamento` — Autonomia consumindo runtime/evidência nativa
- Pronto quando: one-shot que consome fonte nativa **ou** contrato “bridge = máximo até X”; ADR 0001 preservada (`verify-agent` independente do SO).
