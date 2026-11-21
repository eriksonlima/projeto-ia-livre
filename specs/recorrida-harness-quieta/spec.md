# Spec — Re-corrida harness A vs B quieta (COMPROVA/REFUTA ou INCONCLUSIVO limpo)

## Resultado visível

Existe um **procedimento de medição serial/quieto** documentado e uma **corrida A+B verificável** sob esse protocolo, emitindo `IA_LIVRE_HARNESS_VERDICT` honesto (`COMPROVA` / `REFUTA` / `INCONCLUSIVO`) **sem contenção de benchmarks concorrentes** no host.

Enquanto `B_BLOCK=no_gguf_infer_engine` (Etapa 27): o veredito esperado e válido continua **`INCONCLUSIVO`**, com reason explícita (ex. `…E27_no_gguf_infer_engine`). **Proibido** inventar `TOKENS_PER_S` / `LOAD_S` na Linha B.

A etapa entrega **protocolo + evidência limpa** do instrumento já existente (`run-harness-a-b-comparable` / `verify-harness-comparable`), não um motor de inferência em B.

## Contexto fixo (não reinventar)

- Etapas **1–27 feitas**. E27: `GGUF_NATIVE_LOADER=blockio_full`, `GGUF_STATUS=tensors_stub_ok`, `B_BLOCK=no_gguf_infer_engine` — GGUF completo no guest via BlockIO + stub; **sem** motor de geração.
- Instrumento comparável (Etapa 22): [`docs/harness-a-b-comparavel.md`](../../docs/harness-a-b-comparavel.md); scripts `scripts/run-harness-a-b-comparable.sh` / `make verify-harness-comparable` — já emite `VERDICT=INCONCLUSIVO` com reason `…E27_no_gguf_infer_engine`.
- Métricas CPU serial limpas: [`docs/runtime-inferencia-cpu-metricas.md`](../../docs/runtime-inferencia-cpu-metricas.md) (~13,4 tok/s mediana sob medição serial).
- Motivação: corridas/gates em paralelo deprimiram T/s; protocolo quieto = **um gate por vez**, sem carga concorrente (outro `verify-*`, QEMU, runtime pesado, agent).
- Harness v1: [`docs/harness-linha-a-b.md`](../../docs/harness-linha-a-b.md); Linha B: [`docs/runtime-nativo-linha-b.md`](../../docs/runtime-nativo-linha-b.md).
- Hipótese de pesquisa: product-context / architecture — **não** declarar vitória sem GGUF comparável em B com geração real.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`; se não precisar, registrar.

## Decisão de desenho (obrigatória)

| Peça | Escolha nesta etapa |
|------|---------------------|
| Objetivo | Protocolo quieto + re-corrida A+B sob esse protocolo + `VERDICT` honesto sem contenção |
| Doc | Preferir `docs/harness-corrida-quieta.md` **ou** seção inequívoca em `docs/harness-a-b-comparavel.md` + ponte; pré-condições, ordem, o que NÃO fazer, como registrar carga do host |
| Tooling | Flag/wrapper mínimo **opcional** (ex. recusar se detectar outro QEMU/`verify-*`); se over-engineering → **doc + checklist** no gate existente basta |
| Re-corrida | Registrar saída: `VERDICT` + `VERDICT_REASON` + métricas A; B **sem** `TOKENS_PER_S` |
| Veredito atual | Com `no_gguf_infer_engine` → **`INCONCLUSIVO` limpo** (não fraude de `COMPROVA`/`REFUTA`) |
| Gate | `make verify-harness-comparable` sob protocolo quieto deve passar com `INCONCLUSIVO` honesto |
| AGENTS/README | Atualizar só se a home/`Como verificar` ficar enganosa sem o protocolo |
| Kernel / E19–E27 | **Não** alterar contratos nem motor B |

### Rejeitado (explícito)

- Implementar motor de inferência / emitir `TOKENS_PER_S` em B.
- Mudar hipótese para `COMPROVA`/`REFUTA` fingindo números ou convertendo proxy/stub em throughput.
- GPU / multi-GPU / alterar contratos das Etapas 19–27.
- Gate que falha **só** porque o veredito é `INCONCLUSIVO` (enquanto sem motor B, `INCONCLUSIVO` = sucesso do instrumento quieto).
- Over-engineering de orquestrador de “fila de gates” além do mínimo útil.

## Conteúdo obrigatório

### 1. Protocolo de corrida quieta

Documentar:

1. **Pré-condições:** sem outro `make verify*` / QEMU / `cargo run -p ia-livre-runtime` / agent pesado concorrente; preferência por host ocioso ou carga residual documentada.
2. **Ordem:** A depois B (via comparable, ou linha a linha na ordem documentada); **um** alvo de verificação por vez.
3. **Registro:** carga do host (ex. `loadavg` / nota qualitativa), timeout usado, data, saída grepável (`VERDICT`, `VERDICT_REASON`, métricas A).
4. **O que NÃO fazer:** gates em paralelo; inventar tokens em B; declarar `COMPROVA` sob `no_gguf_infer_engine`; misturar esta medição com E5/E8 como se fossem o veredito A vs B.
5. Ponte para `harness-a-b-comparavel.md`, métricas CPU serial e Linha B / `B_BLOCK`.

### 2. Tooling mínimo (opcional) + evidência da re-corrida

- Se útil sem over-engineering: wrapper/flag que **avisa ou recusa** se detectar outro QEMU/`verify-*` (ou checklist shell no início do comparable).
- Senão: checklist no doc + instrução no gate/AGENTS.
- Executar e **registrar** uma corrida quieta (saída canônica no doc ou anexo curto em docs — sem inventar métricas B).

### 3. Gate sob protocolo + pontes

- `make verify-harness-comparable` sob o protocolo deve passar com `VERDICT=INCONCLUSIVO` + reason honesta; **sem** `TOKENS_PER_S` em B.
- `AGENTS.md` / `README.md` só se omitir o protocolo deixar o visitante enganado; senão registrar que foi considerado.
- Não regredir `make verify-harness` (v1) nem inventar mudança de contrato E27.

## Fora de escopo

- Motor de inferência / geração / `TOKENS_PER_S` em B (nova etapa de backlog)
- Declarar hipótese comprovada ou refutada sem métricas GGUF comparáveis em espécie
- GPU / multi-GPU / GPU manager
- Alterar contratos E19–E27 (`MEM_SCHED`, loader BlockIO, stub, `B_BLOCK`)
- Embarcar GGUF no git
- Marcar Etapa 28 como `feita` nesta spec (agente principal após gate + revisor)

## Critérios de aceite

- [ ] Procedimento de medição serial/quieto documentado (pré-condições, ordem, registro, proibições)
- [ ] Corrida A+B verificável sob esse protocolo; saída com `VERDICT` + `VERDICT_REASON` + métricas A; B sem `TOKENS_PER_S` inventados
- [ ] `VERDICT` honesto: com `no_gguf_infer_engine` → `INCONCLUSIVO` limpo (não `COMPROVA`/`REFUTA` forjados)
- [ ] Sem contenção documentada como requisito (um gate por vez); tooling opcional só se justificar
- [ ] `make verify-harness-comparable` passa sob o protocolo quieto
- [ ] Pontes AGENTS/README avaliadas (`readme-por-fatia`)
- [ ] Sem motor B novo; sem alterar contratos E19–E27
- [ ] Etapa 28 permanece `em_andamento` até o agente principal fechar (especificador **não** marca `feita`)

## Riscos e rollback

- **Risco:** leitor tratar re-corrida quieta como prova da hipótese → doc + `INCONCLUSIVO` obrigatório enquanto `no_gguf_infer_engine`.
- **Risco:** wrapper de detecção falso-positivo (QEMU de outro projeto) → preferir aviso + override documentado, ou só checklist.
- **Risco:** over-engineering de fila de gates → doc + checklist basta se o wrapper não couber limpo.
- **Risco:** reintroduzir contenção no CI/local → protocolo deve ser explícito em AGENTS/doc.
- **Rollback:** remover doc/seção quieta e qualquer wrapper; instrumento E22 permanece; etapa volta a depender só do comparable atual.

## Etapa do roadmap

- Etapa 28 — Re-corrida harness A vs B quieta (COMPROVA/REFUTA ou INCONCLUSIVO limpo) (`em_andamento`, Issue [#28](https://github.com/eriksonlima/projeto-ia-livre/issues/28))
- Spec: `specs/recorrida-harness-quieta/`
- Pronto quando (roadmap): procedimento de medição serial/quieto documentado; corrida A+B verificável sob esse protocolo; `VERDICT` honesto (`COMPROVA`/`REFUTA`/`INCONCLUSIVO`) sem contenção de benchmarks concorrentes; sem inventar `TOKENS_PER_S` em B enquanto `no_gguf_infer_engine`.
