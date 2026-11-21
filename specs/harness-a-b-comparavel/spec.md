# Spec — Harness A vs B comparável (prova ou refutação da hipótese)

## Resultado visível

Existe uma **corrida lado a lado** Linha A vs Linha B, **reproduzível e documentada**, que emite um **relatório honesto** com veredito explícito:

| Veredito | Quando |
|----------|--------|
| `COMPROVA` | Ambas as linhas rodaram a **mesma carga GGUF canônica** com métricas **comparáveis**; evidência sustenta a hipótese (B ≥ A no critério fixado) **sem** inventar números |
| `REFUTA` | Mesma pré-condição de comparabilidade; evidência contraria a hipótese (B claramente inferior a A no critério fixado) |
| `INCONCLUSIVO` | Comparabilidade **ausente** (ex.: B ainda é proxy pós-ExitBoot; GGUF nativo em B indisponível; falha de corrida; limites que impedem julgamento) — **resultado esperado e válido** enquanto Etapas 20–21 / B14–B15 não entregarem carga canônica real em B |

Gate ou script verificável cobre a corrida + relatório. **Proibido** declarar vitória da hipótese sem evidência comparável. **Sem** GPU manager.

## Contexto fixo (não reinventar)

- Hipótese: [`docs/product-context.md`](../../docs/product-context.md) e [`docs/architecture.md`](../../docs/architecture.md) — mesmo hardware/modelo/quantização/carga; A = Linux + runtime; B = IA Livre + runtime nativo; **não** declarar vitória sem benchmark comparável.
- Harness v1 (Etapas 9/12): [`docs/harness-linha-a-b.md`](../../docs/harness-linha-a-b.md) — A = GGUF host (`TOKENS_PER_S`); B = proxy pós-ExitBoot (`PROXY_MS`) → **não comparáveis** hoje.
- Contrato B mínimo: [`docs/runtime-nativo-linha-b.md`](../../docs/runtime-nativo-linha-b.md) — proxy; **não** TinyLlama.
- Perfis A otimizada / GPU (metodologia; Etapa 18): [`docs/harness-perfis-a-otimizada-gpu.md`](../../docs/harness-perfis-a-otimizada-gpu.md) — **não** substituem comparabilidade GGUF A/B; GPU-B só com GGUF/acelerador real em B.
- Carga canônica (inalterada salvo desvio documentado): TinyLlama 1.1B Chat v1.0 Q4_K_M; prompt `Complete em uma frase: O Projeto IA Livre é`; `n-predict=32`; harness v1 = CPU.
- Scripts atuais: `scripts/run-harness-line-a.sh`, `scripts/run-harness-line-b.sh`, `scripts/verify-harness.sh` / `make verify-harness` (A GGUF + B proxy).
- Dependência crítica: **B15 / Etapa 21** (carga GGUF canônica em B) e, a montante, **B14 / Etapa 20** (runtime falando contrato nativo). B13–B15 podem estar em paralelo — esta etapa **avança com metodologia/scripts honestos** mesmo se B ainda for proxy.
- Etapa 19 (`em_andamento` em outra trilha): memória/scheduler no kernel — **fora** desta spec; **não** editar `kernel/` nem paths da Etapa 19 nesta entrega.
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`; se não precisar, registrar.

## Decisão de desenho (obrigatória)

| Peça | Escolha nesta etapa |
|------|---------------------|
| Objetivo | Instrumento de **comparação honesta** A vs B + veredito `COMPROVA` / `REFUTA` / `INCONCLUSIVO` + limites |
| Comparabilidade | Só quando A **e** B executam a **mesma** carga GGUF (modelo/quant/prompt/`n-predict`) e emitem métricas do **mesmo tipo** (ex.: ambos `HARNESS_TOKENS_PER_S` / load GGUF) |
| B ainda proxy | Relatório **deve** emitir `INCONCLUSIVO` (motivo: carga não comparável / `LOAD_KIND=proxy`); **proibido** converter `PROXY_MS` em `TOKENS_PER_S` ou inventar throughput B |
| B com GGUF real | Quando B15+ existir: script usa o entrypoint B GGUF; aí sim métricas lado a lado e possibilidade de `COMPROVA`/`REFUTA` |
| Critério numérico | Fixar na metodologia um critério mínimo e explícito (ex.: comparação de `TOKENS_PER_S` no mesmo host/carga; margem/limite de ruído documentado). Sem critério → só `INCONCLUSIVO` mesmo com duas corridas GGUF |
| Doc | Doc dedicada (ex. `docs/harness-a-b-comparavel.md`) **ou** seção clara em `harness-linha-a-b.md` + ponte; critérios e limites legíveis |
| Scripts | Corrida A+B + relatório (ex. `scripts/run-harness-a-b-comparable.sh`) que **nunca** finge comparabilidade |
| Gate | Extensão de `verify-harness` **ou** alvo novo (ex. `verify-harness-comparable`) documentado em `AGENTS.md`; deve passar com `INCONCLUSIVO` honesto se B=proxy (não exige vitória) |
| Hipótese | **Não** declarar comprovada por default; só `COMPROVA` com evidência comparável |
| GPU manager | **Fora** (ADR 0006 permanece desenho) |
| Kernel / Etapa 19 | **Não tocar** nesta etapa |

### Rejeitado (explícito)

- Declarar hipótese comprovada sem A e B GGUF comparáveis.
- Inventar métricas lado a lado (`TOKENS_PER_S` em B proxy; “equivalência” PROXY↔tokens).
- Tratar `make verify-harness` atual (A GGUF + B proxy) como se já fosse prova A vs B.
- GPU manager / multi-GPU real; joules/p95 como critério obrigatório.
- Editar `kernel/` ou contratos da Etapa 19.
- Trocar carga canônica sem documentar desvio.
- Gate que falha **só** porque o veredito é `INCONCLUSIVO` (enquanto B=proxy, `INCONCLUSIVO` = sucesso do instrumento).

## Conteúdo obrigatório

### 1. Metodologia comparável + critérios de veredito

Documentar:

1. **Pré-condição de comparabilidade** (checklist): mesmo modelo/quant/arquivo (ou equivalente nativo da mesma quant); mesmo prompt; mesmo `n-predict`; mesmo modo de aceleração no par (CPU↔CPU no mínimo v1); mesmo host de medição; B com `LOAD_KIND` ≠ `proxy` (GGUF real).
2. **Critérios** `COMPROVA` / `REFUTA` / `INCONCLUSIVO` — tabela inequívoca + **limites** (ruído de SO, uma corrida vs N, A pragmática vs A otimizada, ausência de GPU-B, etc.).
3. **O que não conta:** proxy B; métricas E5/E8 como substituto; host A disfarçado de B; números inventados.
4. Ponte para harness v1 / runtime-nativo-linha-b / perfis Etapa 18 / product-context.

### 2. Script de corrida A vs B + relatório

- Orquestra Linha A (existente) + Linha B (proxy **ou** GGUF quando disponível).
- Detecta honestamente se B é comparável (marcadores: ausência de `PROXY=` / presença de load+tokens GGUF em B, ou flag/contrato documentado pós-B15).
- Emite relatório com: marcadores A; marcadores B; `IA_LIVRE_HARNESS_VERDICT=COMPROVA|REFUTA|INCONCLUSIVO`; motivo/limites em texto grepável (ex. `IA_LIVRE_HARNESS_VERDICT_REASON=`).
- Se B=proxy → `INCONCLUSIVO` + reason explícita; exit 0 do instrumento (não fingir prova).

### 3. Gate / verify + pontes AGENTS/README

- Gate ou extensão: corre o script; exige relatório com veredito ∈ {COMPROVA, REFUTA, INCONCLUSIVO}; **aceita** `INCONCLUSIVO` quando B não comparável; **falha** se inventar tokens em B proxy, omitir reason, ou declarar `COMPROVA` sem pré-condição.
- `AGENTS.md`: Como rodar / Como verificar a corrida comparável.
- `README.md`: avaliar (`readme-por-fatia`).
- Atualizar ponte em `harness-linha-a-b.md` (A/B ainda não comparáveis **até** B GGUF + este instrumento).

## Fora de escopo

- Implementar carga GGUF em B (Etapas 20–21 / B14–B15) — só **consumir** quando existir
- Editar `kernel/` / allocator/scheduler da Etapa 19
- GPU manager; multi-GPU; marketplace / P2P / agent
- Campanha completa de A otimizada ou GPU espelhado como único critério (podem ser *limites* no relatório)
- Embarcar GGUF no git
- Marcar Etapa 22 (ou 19) como `feita` nesta spec

## Critérios de aceite

- [ ] Metodologia documentada com pré-condição de comparabilidade e critérios `COMPROVA` / `REFUTA` / `INCONCLUSIVO` + limites
- [ ] Script de corrida A vs B + relatório honesto; com B proxy → `INCONCLUSIVO` (sem métricas falsas)
- [ ] Gate/alvo verificável documentado; passa com `INCONCLUSIVO` honesto; falha se `COMPROVA` sem comparabilidade ou se inventar tokens em proxy
- [ ] Pontes em docs do harness / `AGENTS.md`; README avaliado
- [ ] Hipótese **não** declarada comprovada sem evidência comparável
- [ ] Sem GPU manager; sem editar kernel da Etapa 19
- [ ] Etapa 22 permanece `pendente` até o agente principal fechar a etapa (especificador **não** marca `feita`)

## Riscos e rollback

- **Risco:** leitor tratar `verify-harness` (proxy) como prova → doc + veredito `INCONCLUSIVO` explícitos; namespace/reason no relatório.
- **Risco:** B15 atrasar → etapa ainda entregável via metodologia + script + gate com `INCONCLUSIVO`.
- **Risco:** critério numérico ambíguo → fixar na Task 1; sem critério = só `INCONCLUSIVO`.
- **Risco:** colisão com Etapa 19 → arquivos desta spec **não** incluem `kernel/**`.
- **Rollback:** remover doc/script/gate novos; restaurar pontes; etapa continua `pendente`.

## Etapa do roadmap

- Etapa 22 — Harness A vs B comparável (prova ou refutação da hipótese) (`pendente`, Issue [#22](https://github.com/eriksonlima/projeto-ia-livre/issues/22))
- Spec: `specs/harness-a-b-comparavel/`
- Pronto quando (roadmap): corrida lado a lado (mesmo modelo/quantização/carga) Linha A vs Linha B reproduzível e documentada, com relatório honesto (comprova / refuta / inconclusivo + limites); gate ou script verificável; sem declarar vitória sem evidência comparável (carga GGUF real em B — depende das Etapas 20–21 / B14–B15); sem GPU manager.
