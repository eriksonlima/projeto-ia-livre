# Spec — Carga GGUF canônica na Linha B (mínimo honesto)

## Resultado visível

Caminho **mínimo e honesto** para a **carga canônica do harness** executar na **Linha B** (QEMU / IA Livre), com um de dois desfechos aceitáveis:

1. **Sucesso real:** TinyLlama 1.1B Chat v1.0 Q4_K_M GGUF + prompt canônico + `n-predict=32` rodam no ambiente IA Livre; o harness emite `IA_LIVRE_HARNESS_*` com `LINE=B` e métricas B **em espécie** comparáveis às de A (ex. `LOAD_S`, `TOKENS_PER_S`) — valores **medidos**, não inventados; **ou**
2. **Bloqueio honesto documentado:** se B13 (memória/scheduler mínima) e/ou B14 (runtime falando o contrato nativo) ainda não permitirem carga GGUF real, docs + stubs/gate registram o bloqueio com marcadores explícitos — **sem** fingir GGUF no QEMU e **sem** inventar `TOKENS_PER_S` / `LOAD_S` GGUF.

O proxy pós-ExitBoot da **Etapa 12** permanece **distinto** até existir carga GGUF real em B. A hipótese A vs B **não** fica comprovada nesta etapa (prova/refutação = Etapa 22 / B16).

## Contexto fixo (não reinventar)

- Harness: [`docs/harness-linha-a-b.md`](../../docs/harness-linha-a-b.md) — A = host + GGUF; B hoje = proxy `post_exit_microbench` (Etapa 12).
- Contrato B mínimo atual: [`docs/runtime-nativo-linha-b.md`](../../docs/runtime-nativo-linha-b.md) — GGUF TinyLlama **ausente**; `TOKENS_PER_S` **proibido** no proxy.
- Carga canônica (igual à Linha A / AGENTS.md):

| Item | Valor |
|------|--------|
| Modelo | TinyLlama 1.1B Chat v1.0 |
| Quantização | Q4_K_M (GGUF) |
| Arquivo | `models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf` |
| Prompt | `Complete em uma frase: O Projeto IA Livre é` |
| `--n-predict` | `32` |
| Aceleração (v1) | CPU (`n-gpu-layers=0`) |

- Dependências fortes: **Etapa 19 / B13** (allocator tipado + hints Prefill/Decode no kernel) e **Etapa 20 / B14** (runtime exercendo o contrato nativo além do proxy). Sem esses contratos mergeados/verificáveis, **não** há carga GGUF real em B.
- Rodar `ia-livre-runtime` no Linux host = **Linha A**, nunca B.
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`; se não precisar, registrar.

## Decisão de desenho (única — obrigatória)

| Peça | Escolha nesta etapa |
|------|---------------------|
| Objetivo | Carga canônica GGUF na Linha B **ou** bloqueio honesto documentado |
| Ambiente B | QEMU / IA Livre — **não** host `ia-livre-runtime` |
| Proxy Etapa 12 | **Permanece** o caminho default de sucesso do harness B até GGUF real existir; não é reescrito como “GGUF” |
| Métricas B “em espécie” | Só com carga GGUF **real**: `LOAD_S` / `TOKENS_PER_S` (ou nomes `HARNESS_*` equivalentes) **medidos** |
| Bloqueio | Marcadores e docs explícitos (ex. `LOAD_KIND=blocked` / `B_BLOCK=…`); gate aceita bloqueio documentado **sem** números inventados |
| Hipótese A vs B | **Não comprovada** — mesmo com GGUF em B, prova lado a lado = Etapa 22 |
| GPU manager | **Fora** |
| ADR nova | Só se surgir escolha estrutural que contradiga ADR 0001/0003 — não esperada para o mínimo |

### Rejeitado (explícito)

- Inventar `TOKENS_PER_S` / `LOAD_S` GGUF sem carga real no QEMU/IA Livre.
- Declarar hipótese A vs B comprovada (ou refutada) só com esta etapa.
- Tratar o proxy Etapa 12 como se fosse TinyLlama / carga canônica.
- Contar corrida host de `ia-livre-runtime` como Linha B.
- GPU manager / multi-GPU / perfil GPU-B obrigatório no gate.
- Implementar B13/B14 nesta spec (outras etapas / branches).
- Editar `specs/memoria-scheduler-impl-minima/` ou `specs/runtime-contrato-nativo/` a partir desta fatia.

### Dois caminhos de marcadores (contrato)

Namespace `IA_LIVRE_HARNESS_*` (reemitido pelo script B a partir da evidência real).

#### Caminho A — GGUF real em B (só se B13+B14 permitirem)

| Marcador | Obrigatório | Significado |
|----------|-------------|-------------|
| `IA_LIVRE_HARNESS_LINE=B` | sim | Linha B |
| `IA_LIVRE_HARNESS_OK` | sim | Carga canônica concluiu |
| `IA_LIVRE_HARNESS_LOAD_KIND=gguf` | sim | Distingue do proxy |
| `IA_LIVRE_HARNESS_MODEL=` | sim | Identificador do GGUF canônico (ex. nome do arquivo TinyLlama) |
| `IA_LIVRE_HARNESS_N_PREDICT=32` | sim | Mesma carga que A |
| `IA_LIVRE_HARNESS_LOAD_S=` | sim | Load **medido** do GGUF em B |
| `IA_LIVRE_HARNESS_TOKENS_PER_S=` | sim | Throughput **medido** em B |
| `IA_LIVRE_HARNESS_ACCEL=cpu` | sim (v1) | Sem GPU-B obrigatório |
| `IA_LIVRE_HARNESS_PROXY=…` | **não** | Não misturar com proxy |

#### Caminho B — Bloqueio honesto (default enquanto deps faltarem)

| Marcador | Obrigatório | Significado |
|----------|-------------|-------------|
| `IA_LIVRE_HARNESS_LINE=B` | sim | Linha B |
| `IA_LIVRE_HARNESS_B_BLOCK=<motivo>` | sim | Motivo estável (ex. `awaiting_b13_b14`, `no_gguf_path`) |
| `IA_LIVRE_HARNESS_LOAD_KIND=blocked` | sim | Não é GGUF nem sucesso de proxy “como se GGUF” |
| `IA_LIVRE_HARNESS_OK` | **não** no sentido de carga GGUF | Sucesso GGUF ausente; proxy Etapa 12 pode continuar emitindo `HARNESS_OK` **só** para o caminho proxy (separado) |
| Proxy Etapa 12 | opcional paralelo | `PROXY=post_exit_microbench` + `LOAD_KIND=proxy` permanece válido como instrumento mínimo; **não** substitui GGUF |

**Proibido em ambos os caminhos sem carga real:**

- `TOKENS_PER_S` / `LOAD_S` com valores inventados ou copiados da Linha A.
- `MODEL=` apontando TinyLlama GGUF sem o arquivo/carga terem rodado em B.
- Declarar no gate “hipótese ok” / A≻B / B≻A.

### Relação com o gate atual

- `make verify-harness` hoje: A = GGUF host; B = proxy QEMU.
- Nesta etapa o gate **atualiza** para reconhecer: (1) GGUF real em B **ou** (2) bloqueio honesto + (proxy Etapa 12 ainda aceito como instrumento mínimo enquanto GGUF não existir).
- Gate **não** inventa números; **não** exige `TOKENS_PER_S` em B até o caminho GGUF real existir.

## Conteúdo obrigatório

### 1. Documentação

- Estender [`docs/runtime-nativo-linha-b.md`](../../docs/runtime-nativo-linha-b.md): seção “caminho GGUF canônico em B” + tabela sucesso vs bloqueio + deps B13/B14 + aviso de que proxy ≠ GGUF.
- Atualizar [`docs/harness-linha-a-b.md`](../../docs/harness-linha-a-b.md): estado do slot B (proxy / bloqueio / GGUF); quando A e B passam a ter métricas em espécie; hipótese ainda não comprovada.
- Ponte mínima em `docs/architecture.md` (decisão aberta / harness) se a home de arquitetura ainda disser só “proxy”.
- `AGENTS.md`: Como rodar / verificar Linha B no cenário GGUF **ou** bloqueio; gate sem inventar números.
- README: avaliar (`readme-por-fatia`).

### 2. Harness / gate (sem fraude)

- `scripts/run-harness-line-b.sh` e `scripts/verify-harness.sh` alinhados ao contrato: proxy (Etapa 12) **ou** bloqueio documentado **ou** GGUF real — mutuamente honestos.
- Falha do gate se B emitir `TOKENS_PER_S` / `LOAD_S` GGUF / `MODEL` TinyLlama **sem** evidência de carga real (marcadores kernel/runtime exigidos quando o caminho GGUF existir).
- Mensagem de gate: hipótese **não** comprovada.

### 3. Integração e carga (condicionadas)

- Só após B13 + B14 verificáveis no branch/main adotado: ligar o caminho nativo à carga canônica (modelo no ESP ou mecanismo documentado; prompt; `n-predict=32`).
- Se inviável: fechar com bloqueio honesto + docs + gate coerente — etapa ainda cumpre o Pronto quando do roadmap (“métricas … **ou** bloqueio honesto”).

## Fora de escopo

- Implementação de B13 (Etapa 19) ou B14 (Etapa 20)
- Prova/refutação lado a lado da hipótese (Etapa 22 / B16)
- GPU manager / multi-GPU / GPU-B no gate v1
- Mudanças em `node/`, `agent/`, manifesto
- Trocar a carga canônica da Linha A
- Inventar ABI estável multi-tenant ou filesystem maduro além do mínimo necessário à carga (se a carga real for tentada, o mínimo fica documentado na task de integração — sem expandir para SO completo)

## Critérios de aceite

- [x] Docs descrevem caminho GGUF canônico em B, deps B13/B14, marcadores de sucesso vs bloqueio, e que proxy Etapa 12 ≠ GGUF
- [x] Hipótese A vs B **não** declarada comprovada em docs/gate/scripts
- [x] Nenhum caminho emite `TOKENS_PER_S` / `LOAD_S` GGUF inventados ou sem carga real
- [x] Gate harness atualizado: aceita GGUF real em B **ou** bloqueio honesto (proxy mínimo pode permanecer); rejeita fraude de métricas
- [ ] Se B13+B14 permitirem e a carga for viável: corrida B com TinyLlama Q4_K_M, prompt canônico, `n-predict=32` e métricas medidas em espécie — **N/A** nesta etapa (inviável no QEMU mínimo)
- [x] Se não permitirem / inviável: bloqueio documentado com marcadores honestos e gate coerente (`B_BLOCK=no_gguf_path`)
- [x] `AGENTS.md` cobre o cenário; README avaliado (sem mudança)
- [x] Etapa 21 pronta para o agente principal marcar `feita` após gate + revisor (desfecho bloqueio)

## Riscos e rollback

- **Risco:** pressão para “fechar” com números falsos → regra dura: sem evidência de carga = sem `TOKENS_PER_S` GGUF; bloqueio é desfecho válido.
- **Risco:** confusão proxy vs GGUF → `LOAD_KIND` distinto (`proxy` / `blocked` / `gguf`) + docs repetidos.
- **Risco:** B13/B14 atrasados ou divergentes entre branches → Task 1 segura em paralelo; tasks de integração **condicionadas**; não duplicar specs B13/B14.
- **Risco:** escopo inchado (SO completo / GPU) → rejeitar; mínimo = carga canônica ou bloqueio.
- **Rollback:** restaurar gate B = só proxy Etapa 12; reverter stubs GGUF; docs de bloqueio permanecem como registro.

## Etapa do roadmap

- Etapa 21 — Carga GGUF canônica na Linha B (mínimo honesto) (`pendente` no GitHub / branch `etapa-b15-gguf-linha-b`; **não** `em_andamento` enquanto Etapa 19 ocupar o lease)
- Issue: [#21](https://github.com/eriksonlima/projeto-ia-livre/issues/21) (ex-B15)
- Spec: `specs/carga-gguf-linha-b/`
- Pronto quando (roadmap / issue): caminho mínimo da carga canônica do harness (TinyLlama Q4_K_M) na Linha B (QEMU/IA Livre) emite métricas B em espécie comparáveis às de A (ex. tokens/s), **ou** bloqueio honesto documentado; gate harness atualizado sem inventar números; hipótese **não** comprovada; sem GPU manager.

> **Agente principal:** gravar `Spec: specs/carga-gguf-linha-b/` na entrada da Etapa 21 do `ROADMAP.md` quando a etapa for listada/espelhada (este subagente não edita o ROADMAP).
