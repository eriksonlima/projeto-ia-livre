# Spec — Sincronizar architecture/product pós-E58

Etapa 72 · Issue [#72](https://github.com/eriksonlima/projeto-ia-livre/issues/72) (ex-B67)  
Deps: Etapas **42–71** `feita` (incl. E58 checklist, E61 `BLOQUEIO_FINAL`, E63–E71).

---

## Resultado visível

`docs/architecture.md`, `docs/product-context.md` e `docs/glossario.md` descrevem o ecossistema **pós-E71**, com decisões **abertas reais** (não listar REPL / GPU harness / multi-GPU host / relay como se ainda pendentes).

1. **Architecture** — mapa e “decisões tomadas/abertas” alinhados a E42–E71; hipótese A/B = `BLOQUEIO_FINAL` (ADR 0022), sem reabrir B55.
2. **Product-context** — estado de produto e ferramentas/Rede refletem o que o usuário já tem no host; ponte ao checklist E58.
3. **Glossário** — âncoras faltantes (REPL, `read_local`, mDNS, relay, KNOW, `host_multi`, bridges) sem virar dump de marcadores.
4. **Gate** — `make verify-docs-consistency` (ou extensão leve do script) rejeita regressões textuais listadas abaixo.

**Proibido:** código de produto; inventar `COMPROVA` / `METAL_OK`; promover/reabrir B55; ADR novo cosmético; reescrever manifesto.

---

## Contexto fixo (não reinventar)

- Meta / pilares: [`docs/prototipo-objetivo-atingido.md`](../../docs/prototipo-objetivo-atingido.md) (E58) + ADR [`0022`](../../docs/adr/0022-bloqueio-final-hipotese-ab.md).
- Sync anterior (E42): [`specs/sync-architecture-glossario/`](../sync-architecture-glossario/) — esta etapa **atualiza** o mesmo trio de docs para o estado pós-E58…E71.
- Brief operacional: [`AGENTS.md`](../../AGENTS.md) — architecture/product **resumem e ponteam**, não substituem gates.
- Backlog Abertas: só **B55** (adiada ADR 0021/0022) — **não** inventar reabertura na narrative de “aberto”.
- Manifesto intocado.

### Lacunas conhecidas (auditoria — corrigir na implementação)

| Área | Sintoma atual | Alvo pós-sync |
|------|----------------|---------------|
| `architecture.md` — Decisões abertas | REPL/`read_local` **abertos**; DHT/NAT/relay **abertos**; multi-GPU / harness GPU **abertos**; prova A/B “aberta” por subset E44 | Fechar o que E50–E71 entregou; abertos **reais** só (ver abaixo) |
| `architecture.md` — Decisões tomadas | Para ~E41 (+ menção E44); GPU “multi-GPU completo ainda aberto” | Incluir entregas materiais E42–E71 (pontes, não romance) |
| `architecture.md` — Estado do mapa | Título **pós-E41**; linhas sem E58/E61/E63–E71 | Mapa **pós-E71** |
| `product-context.md` | Agente só `note`/`recall`/`help`/`calc`; Rede só “v1 + bootstrap”; sem path metal / ABI / consumo nativo | Espelhar E53–E54, E50/E67/E68, E63, E70–E71 sem inventar vitória |
| `glossario.md` | Tem ADR 0020–0024 / ABI / `sym_cpu` / `esp_sfs`; **faltam** REPL, `read_local`, mDNS, relay, KNOW, `host_multi` | Completar âncoras estáveis + links |
| Gate `verify-docs-consistency` | Greps E42 (`no_gguf_full_prefill`, “Implementação continua aberta”) — **não** cobrem “REPL abertos” / mapa pós-E41 | Estender greps de regressão + âncoras pós-E58 |

### Decisões abertas **reais** (manter / redigir com honestidade)

| Tema | Estado honesto |
|------|----------------|
| Hipótese A vs B / espécie canônica | **`BLOQUEIO_FINAL`** (ADR 0022; encadeia 0020/0021). Comparable permanece teto/`INCONCLUSIVO`. Reabertura só com critérios da ADR — **B55 adiada**, não listar como “próximo passo aberto” casual. |
| `METAL_OK` em PC | Pendente — E62 `STATUS-SKIP` (`no_pc_serial_log_on_this_host`); artefato/guia/path SFS ok. |
| DHT WAN | Adiado (E67 = relay intro; DHT fora). |
| Simetria GPU A/B no guest | Inviável até passthrough real (ADR 0023); E64 = `sym_cpu`; E65 tipicamente `need_vfio`. |
| TCP Rede no guest | **Fechado como inviável** (ADR 0024 / `NET_GUEST_BLOCK`) — não listar como “aberto a implementar” sem qualificar o bloqueio. |

### Já feitos — **não** listar como abertos

- Autonomia: REPL (E53), `read_local` (E54), bridge host (E49), consumo nativo host (E70).
- Rede: mDNS (E50), TASK (E51), bridge UEFI↔host (E52), relay intro (E67), KNOW (E68).
- GPU / harness: perfil GPU assimétrico (E56), `sym_cpu` (E64), GPU real host (E55), guest passthrough gate/skip (E65), `host_multi` (E69).
- Linha B / hipótese: Decode subset (E44), perf/espécie (E59–E60), bloqueio final (E61), ABI (E71).
- Metal path: `esp_sfs_full` (E63); ≠ `METAL_OK`.

---

## Conteúdo obrigatório

### 1. `docs/architecture.md`

- Atualizar **Decisões tomadas** com entregas E42–E71 materiais (checklist E58, ADR 0020–0024, path metal SFS, `sym_cpu`, relay/KNOW, `host_multi`, `NATIVE_CONSUME`, ABI) — links curtos a contratos.
- Reescrever **Decisões abertas** só com a tabela “reais” acima; remover REPL/`read_local`/harness GPU/multi-GPU host/relay como “abertos”.
- Substituir **Estado do mapa (pós-E41)** por **pós-E71** (ou equivalente) refletindo pilares E58 + bloqueios honestos.
- Manter camadas / hipótese / o-que-não-assumir; não virar cópia do `ROADMAP.md`.

### 2. `docs/product-context.md`

- **Estado atual (produto):** agente com REPL/`read_local`; Rede com mDNS/relay/KNOW; path metal SFS; ABI; consumo bridge — sem declarar `COMPROVA`/`METAL_OK`.
- Manter ponte ao checklist E58 e `BLOQUEIO_FINAL`.
- Métricas / não-objetivos: coerentes com ADR 0022 (não celebrar subset).

### 3. `docs/glossario.md`

- Acrescentar âncoras faltantes: REPL, `read_local`, mDNS, relay/`RELAY_OK`, KNOW, `host_multi` (e bridges se ainda ambíguas).
- Não duplicar contratos inteiros; linkar fontes.
- Opcional: alinhar nota ADR 0023 (“até B60”) → E65/`need_vfio` se ainda citar só backlog.

### 4. Gate documental

Estender [`scripts/verify-docs-consistency.sh`](../../scripts/verify-docs-consistency.sh) (e/ou checklist na última task) para:

- Exigir menção a `BLOQUEIO_FINAL` **ou** ADR `0022` em `architecture.md` e `product-context.md`.
- Falhar se `architecture.md` ainda disser `REPL`/`read_local` como **abertos** (padrão tipo `REPL/`…`abertos`).
- Falhar se o mapa ainda for só `pós-E41` sem atualização pós-E58+.
- Preservar greps E42 úteis (`glossario` presente, etc.) ou atualizá-los se o texto canônico de Linha B mudou (Decode E44 / `BLOQUEIO_FINAL` — não exigir `no_gguf_full_prefill` como **estado corrente** se a narrativa já o trata só como histórico).

Pontes curtas em README/`AGENTS.md` **só** se a capa ou brief ficar enganoso (rule `readme-por-fatia`); default = não mexer.

---

## Fora de escopo

- Código em `kernel/`, `runtime*`, `node/`, `agent/`
- Reabrir B55 / espécie canônica / `COMPROVA`
- Fabricar `METAL_OK` ou log de PC
- Novos ADRs; issues; Memory Bank (agente principal)
- Reescrever todos os contratos satélite
- Tradução EN

---

## Critérios de aceite

- [ ] `architecture.md` não lista REPL/`read_local`/harness GPU/`host_multi`/relay como decisões **abertas**
- [ ] `architecture.md` documenta `BLOQUEIO_FINAL` (ADR 0022) e mapa pós-E71 (ou pós-E58+) com entregas E63–E71 pontuais
- [ ] `product-context.md` espelha ferramentas/Rede/metal/ABI atuais sem inventar vitória
- [ ] `glossario.md` tem âncoras REPL, `read_local`, mDNS, relay, KNOW, `host_multi`
- [ ] `make verify-docs-consistency` verde com greps atualizados
- [ ] Nenhum código de produto; sem `COMPROVA`/`METAL_OK` fabricados; B55 permanece adiada
- [ ] README considerado (`readme-por-fatia`); se não tocado, registrar na fatia

---

## Riscos e rollback

- **Risco:** architecture vira changelog do ROADMAP → mapa curto + links.
- **Risco:** apagar histórico útil de bloqueios → manter uma linha “histórico” (E33/E43/E44) sem tratar como estado corrente.
- **Risco:** gate E42 quebra se remover `no_gguf_full_prefill` do texto → ajustar script na mesma fatia do gate.
- **Rollback:** reverter diffs nos três docs + script; etapa permanece `em_andamento`.

---

## Etapa do roadmap

- Etapa 72 — Sincronizar architecture/product pós-E58 (`em_andamento`, Issue [#72](https://github.com/eriksonlima/projeto-ia-livre/issues/72))
- Pronto quando (roadmap): architecture + product-context + glossário refletem E42–E71 e decisões abertas **reais** (sem listar REPL/GPU harness/etc. como abertos se já feitos).
