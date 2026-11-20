# Spec — Runtime nativo / Linha B real (mínimo)

## Resultado visível

A **Linha B** do harness deixa de ser stub puro (`IA_LIVRE_HARNESS_B_SKIP` sem execução no IA Livre) e passa a ter um **caminho documentado e verificável** no ambiente IA Livre (QEMU/UEFI):

1. **Contrato** do que “runtime nativo / Linha B mínimo” significa **nesta** etapa — e o que **não** é (carga TinyLlama completa, prova da hipótese).
2. **Execução real mínima pós-`ExitBootServices`** no kernel (proxy mensurável), com métricas **reais** na serial.
3. `scripts/run-harness-line-b.sh` sobe QEMU/kernel (ou ESP), captura a serial e emite `IA_LIVRE_HARNESS_LINE=B` + `IA_LIVRE_HARNESS_OK` com marcadores **honestos** do proxy.
4. `make verify-harness` continua a exigir Linha A completa; Linha B exige **OK real mínimo** (proxy), **sem** tratar A≻B / B≻A.

A entrega **não** declara a hipótese comprovada. A carga canônica GGUF (TinyLlama) no IA Livre permanece **fora de alcance** desta etapa.

## Contexto fixo (não reinventar)

- Harness Etapa 9: [`docs/harness-linha-a-b.md`](../../docs/harness-linha-a-b.md) — A = host + `ia-livre-runtime`; B hoje = stub `scripts/run-harness-line-b.sh` → `HARNESS_B_SKIP`.
- Kernel pós-Boot Services (Etapa 11): ExitBoot + UART COM1; marcadores `EXIT_*` — [`docs/kernel-pos-boot-services.md`](../../docs/kernel-pos-boot-services.md).
- ADR 0001: inferência **fora** do kernel; kernel fornece mecanismos — [`docs/adr/0001-separacao-camadas-e-p2p.md`](../../docs/adr/0001-separacao-camadas-e-p2p.md).
- Portar llama.cpp + GGUF TinyLlama completo para UEFI pós-ExitBoot (sem FS maduro, sem `std`) **não é viável** nesta etapa.
- Rodar `ia-livre-runtime` no Linux host = **Linha A**, **nunca** conta como B.
- Inventar `TOKENS_PER_S` / fingir TinyLlama no kernel = **proibido**.
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`; se não precisar, registrar.

## Decisão de desenho (única — obrigatória)

| Peça | Escolha nesta etapa |
|------|---------------------|
| Forma da Linha B | **Execução real mínima no IA Livre (QEMU)** — não stub textual; não host Linux |
| Carga canônica GGUF | **Ainda impossível** no kernel UEFI pós-exit → **não** fingir |
| Proxy | Microbenchmark **pós-`ExitBootServices`** (CPU e/ou memória) no `kernel/`, com métricas **medidas** na serial COM1 |
| Entrypoint B | `scripts/run-harness-line-b.sh` sobe build/ESP/QEMU (reuso de `make build` / caminhos do gate do kernel), captura serial, traduz progresso kernel → `IA_LIVRE_HARNESS_*` com `LINE=B` |
| `HARNESS_OK` em B | Só se o proxy pós-exit concluiu e emitiu marcadores de prova no kernel **e** o script reemitiu o contrato harness |
| Hipótese A vs B | **Não comprovada** — B ≠ carga TinyLlama; métricas B **não** são comparáveis a `LOAD_S` / `TOKENS_PER_S` da Linha A |
| ADR nova | **Não** nesta etapa (proxy no kernel = mecanismo + instrumento; runtime de inferência nativo completo continua fora do kernel, ADR 0001 intacta) |

### Rejeitado (explícito)

- Portar llama.cpp / carregar GGUF TinyLlama no UEFI nesta etapa.
- Emitir `HARNESS_OK` + `TOKENS_PER_S` inventados “como se” fosse TinyLlama.
- Chamar corrida host de `ia-livre-runtime` de Linha B.
- Manter só `HARNESS_B_SKIP` sem trabalho real no QEMU (o Pronto quando pede substituir o stub por execução real mínima).
- Declarar vitória/refutação da hipótese no gate ou nos docs.

### O que a Linha B emite (contrato de marcadores)

Namespace `IA_LIVRE_HARNESS_*` (reemitido pelo script a partir da serial, ou ecoado de forma inequívoca):

| Marcador | Obrigatório | Significado nesta etapa |
|----------|-------------|-------------------------|
| `IA_LIVRE_HARNESS_LINE=B` | sim | Linha B |
| `IA_LIVRE_HARNESS_OK` | sim | Proxy pós-exit concluiu com sucesso |
| `IA_LIVRE_HARNESS_PROXY=post_exit_microbench` | sim | Carga **não** é a canônica GGUF; é o proxy documentado |
| `IA_LIVRE_HARNESS_LOAD_KIND=proxy` | sim | Distingue de load de modelo |
| `IA_LIVRE_HARNESS_PROXY_MS=` | sim | Duração **medida** do trabalho proxy (ms, inteiro ou decimal estável) |
| `IA_LIVRE_HARNESS_PROXY_OPS=` | sim | Contagem **medida** de operações do microbenchmark (ex.: iterações / bytes tocados) |
| `IA_LIVRE_HARNESS_MODEL=proxy-post-exit-v1` | sim | Identificador honesto — **não** o nome do GGUF TinyLlama |
| `IA_LIVRE_HARNESS_N_PREDICT=0` | sim | Sem geração de tokens; deixa explícito que não há `n-predict` canônico |
| `IA_LIVRE_HARNESS_ACCEL=cpu` | opcional | Ambiente bare-metal CPU no QEMU |

**Proibido em B nesta etapa:**

- `IA_LIVRE_HARNESS_TOKENS_PER_S=` (não há tokens; inventar = fraude)
- `IA_LIVRE_HARNESS_LOAD_S=` como se fosse load do GGUF (usar `PROXY_MS` / `LOAD_KIND=proxy`)
- `IA_LIVRE_HARNESS_MODEL=` apontando o arquivo TinyLlama GGUF
- `IA_LIVRE_HARNESS_B_SKIP` no caminho de sucesso (skip só se política de ambiente documentada — default desta etapa = **sem skip**: QEMU é pré-requisito do gate B, como `make verify` do kernel)

Marcadores **kernel** (serial, pós-exit, COM1) — nomes canônicos a fixar na Task 1 e implementar na Task 2 (prefixo sugerido `IA_LIVRE_NATIVE_` ou reuso claro documentado):

| Marcador kernel (orientador) | Papel |
|------------------------------|--------|
| Pré-condição | Cadeia Etapa 11 até `IA_LIVRE_EXIT_BOOT_OK` (regressão) |
| `IA_LIVRE_NATIVE_BENCH_BEGIN` | Início do proxy pós-exit |
| `IA_LIVRE_NATIVE_BENCH_OPS=` / `IA_LIVRE_NATIVE_BENCH_MS=` | Métricas medidas |
| `IA_LIVRE_NATIVE_BENCH_OK` | Proxy concluído |

O script B **só** emite `HARNESS_OK` se vir `EXIT_BOOT_OK` + `NATIVE_BENCH_OK` (e métricas) na captura.

### Limites vs carga canônica completa

| Item harness v1 (A) | Linha B nesta etapa |
|---------------------|---------------------|
| TinyLlama Q4_K_M GGUF | **Ausente** — proxy |
| Prompt canônico | **N/A** |
| `--n-predict 32` | `N_PREDICT=0` |
| `LOAD_S` / `TOKENS_PER_S` | Substituídos por `PROXY_MS` / `PROXY_OPS` |
| Mesmo hardware host | QEMU no **mesmo** host de referência (documentar); não é paridade de carga |

Documento do harness deve dizer em linguagem clara: **dados A e B desta etapa não são lado a lado comparáveis para a hipótese**; B prova só que há caminho nativo mínimo + instrumento vivo.

## Conteúdo obrigatório

### 1. Documentação

- Atualizar [`docs/harness-linha-a-b.md`](../../docs/harness-linha-a-b.md): estado B = execução real mínima (proxy); tabela do que B emite; aviso de não-comparabilidade; o que ainda falta para carga canônica.
- Doc de caminho nativo (pode ser seção no harness **ou** `docs/runtime-nativo-linha-b.md` curto): proxy, marcadores kernel, limites, como observar.
- Ponte mínima em `docs/architecture.md` (decisão aberta / harness) e em `docs/kernel-pos-boot-services.md` (ponte “após EXIT → native bench”).
- `AGENTS.md`: Como rodar / Como verificar Linha B (QEMU) + gate.
- README: avaliar (`readme-por-fatia`).

### 2. Kernel — proxy pós-exit

- Após `EXIT_BOOT_OK` (ou imediatamente após a base estável pós-exit, na mesma fase COM1): microbenchmark determinístico (ex.: loops de leitura/escrita em buffer pré-alocado + contagem de ops + tempo via TSC ou PIT/HPET mínimo — escolher o timer **mais simples e honesto** disponível no bare-metal atual; se só contagem de ops for fiável sem timer maduro, documentar e emitir `PROXY_MS` via medição no **host** a partir da janela serial entre `BENCH_BEGIN` e `BENCH_OK` — preferir medição no kernel se trivial).
- Emitir marcadores `NATIVE_BENCH_*` só com valores medidos.
- **Não** regressar Etapa 10/11 (`make verify` do kernel continua a passar).

### 3. Harness B + gate

- Substituir o stub: `run-harness-line-b.sh` executa caminho QEMU (timeout próprio), exige marcadores kernel, imprime contrato `HARNESS_*` LINE=B.
- `scripts/verify-harness.sh` / `make verify-harness`:
  - A: inalterado em espírito (OK + load/tokens do GGUF).
  - B: **exige** `LINE=B` + `HARNESS_OK` + `PROXY=` + `PROXY_MS=` + `PROXY_OPS=` + `LOAD_KIND=proxy` + `MODEL=proxy-post-exit-v1` + `N_PREDICT=0`.
  - B: **falha** se aparecer `TOKENS_PER_S` ou `MODEL` apontando TinyLlama GGUF ou se `HARNESS_B_SKIP` no caminho default.
  - Gate **não** compara numericamente A vs B nem imprime “hipótese ok”.
- Timeout B alinhado ao do kernel (`VERIFY_TIMEOUT` / `VERIFY_HARNESS_B_TIMEOUT` documentado); A mantém timeout longo (GGUF).

## Fora de escopo

- llama.cpp / GGUF / TinyLlama no UEFI ou no kernel
- Filesystem maduro, `std` no target UEFI, heap geral, MMU completa, GPU no SO
- Runtime nativo completo como processo/userspace no IA Livre
- Prova ou refutação da hipótese A vs B
- Trocar carga canônica da Linha A
- Mudanças em `node/`, `agent/`, manifesto, Project V2 além do espelho já existente da Issue #11
- Nova ADR (salvo descoberta estrutural que contradiga 0001 — não esperada)

## Critérios de aceite

- [ ] Contrato documental descreve proxy pós-exit, marcadores B, limites vs carga canônica e que a hipótese **não** está comprovada
- [ ] Kernel em QEMU executa trabalho real mínimo pós-`ExitBoot` e emite marcadores `NATIVE_BENCH_*` medidos (além da regressão `EXIT_BOOT_OK`)
- [ ] `run-harness-line-b.sh` sobe o ambiente IA Livre, captura serial e emite `IA_LIVRE_HARNESS_LINE=B` + `HARNESS_OK` + marcadores proxy honestos — **sem** `B_SKIP` no sucesso
- [ ] `make verify-harness` passa com A (carga GGUF) + B (proxy real); rejeita tokens inventados em B
- [ ] `AGENTS.md` cobre como rodar/verificar; architecture/harness atualizados; README avaliado
- [ ] Nenhum doc/gate declara hipótese comprovada
- [ ] Etapa 12 não é marcada `feita` nesta spec (só após gate + revisão pelo agente principal)

## Riscos e rollback

- **Risco:** leitor compara `PROXY_MS` com `TOKENS_PER_S` de A → marcadores distintos + avisos repetidos no harness doc e no output do script B.
- **Risco:** “OK” ser lido como vitória da hipótese → frase canônica nos docs e no `GATE_OK` (“A ok + B proxy; hipótese não comprovada”).
- **Risco:** timer bare-metal frágil → fallback documentado (medir janela no host entre BEGIN/OK) sem inventar números.
- **Risco:** escopo inchado (GGUF no kernel) → rejeitar; Pronto quando = proxy real + instrumento B vivo.
- **Rollback:** restaurar stub `B_SKIP`; reverter gate B; etapa continua `em_andamento`.

## Etapa do roadmap

- Etapa 12 — Runtime nativo / Linha B real (mínimo) (`em_andamento`, Issue [#11](https://github.com/eriksonlima/projeto-ia-livre/issues/11))
- Spec: `specs/runtime-nativo-linha-b/`
- Pronto quando (roadmap): caminho documentado e verificável para a carga canônica do harness emitir `IA_LIVRE_HARNESS_*` com `LINE=B` no ambiente IA Livre (ou stub honestamente substituído por execução real mínima); sem fingir hipótese comprovada.
