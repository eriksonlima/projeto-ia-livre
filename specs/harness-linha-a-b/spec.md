# Spec — Harness da hipótese Linha A vs Linha B

## Resultado visível

Existe um **harness de comparação** documentado e gateável para a hipótese de pesquisa (**Linha A** = Linux otimizado + runtime no host vs **Linha B** = IA Livre + runtime nativo), com **mesma carga canônica** (modelo, quantização, prompt, `n-predict` / tokens pedidos e métricas acordadas). Nesta etapa:

1. **Metodologia** fica fixada em doc dedicada (separada das métricas dos protótipos Etapas 5/8).
2. **Linha A** roda de forma **reproduzível no host Linux** (usando o runtime existente `ia-livre-runtime` ou script que o invoca).
3. **Linha B** tem **slot/stub documentado** (como medir quando o runtime nativo no SO existir) — **sem** fingir prova da hipótese nem inventar números de Linha B.
4. **Gate** verifica o harness Linha A (marcadores canônicos); Linha B pode ser **skip/stub** explícito enquanto o SO não tiver runtime nativo.

A entrega **não** declara vitória nem refutação da hipótese. Só entrega o **instrumento de medição** e a baseline A.

## Contexto fixo (não reinventar)

- Hipótese: [`docs/architecture.md`](../../docs/architecture.md) (seção Hipótese de pesquisa) e [`docs/product-context.md`](../../docs/product-context.md) — mesmo hardware/modelo/quant/carga; A = Linux + runtime otimizado; B = IA Livre + runtime nativo.
- ADR 0001: kernel pequeno; inferência fora do kernel — [`docs/adr/0001-separacao-camadas-e-p2p.md`](../../docs/adr/0001-separacao-camadas-e-p2p.md). Runtime nativo completo **ainda não** vive no kernel UEFI.
- Runtime host (Etapas 5/8): `runtime/` + llama.cpp; métricas em `docs/runtime-inferencia-cpu-metricas.md` e `docs/runtime-inferencia-gpu-metricas.md` — **explicitamente NÃO** são o benchmark da hipótese. O harness desta etapa deve ser **distinto e apontado** como tal.
- Modelo canônico: TinyLlama 1.1B Chat v1.0 Q4_K_M (`models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf`).
- Kernel UEFI mínimo existe (Etapa 4) mas **não** tem runtime nativo completo — Linha B completa está **fora** do alcance desta etapa.
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia se `README.md` precisa refletir a superfície; se não, registrar.

## Decisão de ambiente e escopo (obrigatória nesta etapa)

| Peça | Escolha nesta etapa |
|------|---------------------|
| Objetivo | Harness + metodologia + baseline Linha A + slot Linha B |
| Linha A | Host Linux + `ia-livre-runtime` (CPU default; GPU opcional só se a carga do harness fixar o mesmo modo nas duas linhas) |
| Linha B | Stub/slot documentado; gate pode emitir skip canônico se runtime nativo ausente |
| Prova da hipótese | **Não** — só instrumento; não concluir A≻B nem B≻A |
| Separação docs | Doc nova do harness (ex. `docs/harness-linha-a-b.md`); **não** misturar com docs de métricas E5/E8 |
| Gate | `make verify-harness` (ou nome equivalente) — exige sucesso Linha A; Linha B skip/stub ok |

### Expectativa realista (não negociável)

- **Não** implementar runtime nativo no kernel nesta etapa.
- **Não** bootar QEMU/UEFI como “Linha B medida” só com o kernel atual (seria o mesmo runtime host disfarçado ou medição vazia).
- **Não** reutilizar `docs/runtime-inferencia-*-metricas.md` como relatório do harness — no máximo citar como *protótipo de caminho*, com aviso de que **não** substituem o harness.
- Números Linha A no host são **baseline da referência**, não vitória da hipótese.

### Carga canônica do harness (fixar na implementação / Task 1)

| Item | Valor orientador (alinhar a E5 salvo desvio documentado) |
|------|----------------------------------------------------------|
| Modelo | TinyLlama 1.1B Chat v1.0 Q4_K_M (mesmo arquivo GGUF) |
| Prompt | `Complete em uma frase: O Projeto IA Livre é` |
| `--n-predict` | 32 (salvo bloqueio documentado) |
| Aceleração no harness v1 | **CPU** (`--n-gpu-layers 0`) — compara A vs B no mesmo modo; GPU no harness fica decisão aberta / etapa futura |
| Hardware | Documentar host de referência (mesmo para A e, no futuro, B) |

### Métricas mínimas do harness (marcadores)

Estáveis e grepáveis, **namespace distinto** dos protótipos quando fizer sentido (prefixo `IA_LIVRE_HARNESS_`):

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_HARNESS_LINE=A` \| `B` | Qual linha acabou de rodar |
| `IA_LIVRE_HARNESS_OK` | Corrida da linha concluiu com sucesso (A obrigatório no gate) |
| `IA_LIVRE_HARNESS_LOAD_S=` | Tempo de load (s) |
| `IA_LIVRE_HARNESS_TOKENS_PER_S=` | Throughput de geração |
| `IA_LIVRE_HARNESS_MODEL=` | Identificador do modelo/quant (ex. nome do arquivo ou slug) |
| `IA_LIVRE_HARNESS_N_PREDICT=` | Tokens pedidos |
| `IA_LIVRE_HARNESS_B_SKIP` | Linha B não executável ainda (stub); exit do gate permanece 0 se política for skip |

Opcional útil (documentar se emitido): latência de geração, `IA_LIVRE_HARNESS_ACCEL=cpu`.

**Não** exigir nesta etapa: joules, p95 multi-request, VRAM multi-tenant — candidatos da architecture ficam para evolução do harness.

### Slot Linha B (contrato documental)

Documentar de forma inequívoca:

1. **Pré-condição:** runtime nativo no IA Livre (ou caminho bootável que execute a **mesma** carga GGUF/prompt/`n-predict` e emita os mesmos marcadores `IA_LIVRE_HARNESS_*` com `LINE=B`).
2. **Entrypoint futuro:** caminho/comando placeholder (ex. script `scripts/run-harness-line-b.sh` que hoje só imprime `IA_LIVRE_HARNESS_B_SKIP` + motivo).
3. **O que NÃO conta como Linha B:** rodar `ia-livre-runtime` no Linux host; medir só o boot UEFI sem inferência; copiar números das docs E5/E8.
4. Quando B existir: mesma tabela de carga; mesmo hardware; relatório lado a lado na doc do harness.

## Conteúdo obrigatório

### 1. Documentação da metodologia

- Arquivo dedicado (ex. `docs/harness-linha-a-b.md`): hipótese, o que A e B significam **nesta** etapa, carga canônica, métricas, como rodar A, slot B, aviso explícito de que **não** prova a hipótese ainda, e **separação** das métricas E5/E8.
- Atualizar `docs/architecture.md`: decisão aberta “Critérios exatos e harness…” → apontar a doc/spec (mínimo necessário).
- Avisos cruzados nas docs E5/E8 (uma linha apontando o harness) — opcional mas desejável se barato.

### 2. Harness Linha A (executável)

- Script(s) e/ou alvo Make que: sobe/invoca o runtime no host com a carga canônica; captura/emite marcadores `IA_LIVRE_HARNESS_*` com `LINE=A` e `HARNESS_OK`.
- Preferir **envolver** `ia-livre-runtime` (subprocesso) em vez de duplicar lógica de inferência — o harness é o instrumento, o runtime continua o motor da Linha A no host.
- Reproduzível: documentado em `AGENTS.md` (Como rodar / Como verificar).

### 3. Stub Linha B

- Script ou ramo documentado que **não** finge medição: emite `IA_LIVRE_HARNESS_B_SKIP` (e mensagem humana do motivo).
- Contrato do que será necessário para tirar o skip.

### 4. Gate + AGENTS

- `make verify-harness` + `scripts/verify-harness.sh` (nomes equivalentes ok se consistentes).
- Gate: exige Linha A com `IA_LIVRE_HARNESS_OK` + marcadores mínimos; aceita B skip; **não** exige QEMU/UEFI nem GPU.
- Gates existentes (kernel, runtime CPU/GPU, node, agent) **não** regridem por esta etapa.
- `README.md`: avaliar (`readme-por-fatia`).

## Fora de escopo

- Runtime nativo completo no kernel / boot QEMU com inferência
- Declarar comprovação ou refutação da hipótese
- Trocar o modelo canônico (salvo bloqueio documentado)
- Multi-GPU, joules, p95 de carga multi-tenant como critério de aceite
- Reescrever ou invalidar os gates/métricas das Etapas 5/8 (só separar semanticamente)
- Mudanças em `node/`, `agent/`, manifesto
- Otimização agressiva de Linux (“tuning” de kernel/sysctl como projeto à parte) — Linha A = host Linux + runtime do projeto como **referência pragmática**; “otimizado” no sentido da hipótese completa pode evoluir depois, documentado como limitação
- Embarcar pesos GGUF no git

## Critérios de aceite

- [ ] Doc dedicada do harness descreve metodologia, carga canônica, métricas, Linha A executável e slot Linha B — **sem** confundir com docs E5/E8
- [ ] Linha A roda no host de forma reproduzível e emite `IA_LIVRE_HARNESS_LINE=A` + `IA_LIVRE_HARNESS_OK` + load/tokens
- [ ] Linha B tem stub/skip documentado (`IA_LIVRE_HARNESS_B_SKIP` ou equivalente); nenhum número inventado de B
- [ ] `make verify-harness` (ou equivalente) passa com A ok e B skip; timeout documentado
- [ ] `AGENTS.md` cobre como rodar e verificar o harness; architecture aponta o harness; README avaliado
- [ ] Hipótese **não** é declarada comprovada nesta etapa
- [ ] Etapa 9 não é marcada `feita` nesta spec (só após gate + revisão pelo agente principal)

## Riscos e rollback

- **Risco:** confundir métricas E5/E8 com o harness → namespace `HARNESS_`, doc separada, avisos cruzados.
- **Risco:** “Linha B” acidentalmente = mesmo binário no Linux → contrato explícito do que conta como B; stub sem números.
- **Risco:** escopo inchado (runtime no kernel, joules, prova da hipótese) → rejeitar; Pronto quando = harness + baseline A + slot B.
- **Risco:** chamar o runtime atual de “Linux otimizado” sem nuance → documentar limitação (referência pragmática do projeto, não tuning OS completo).
- **Rollback:** remover scripts/gate/doc do harness; restaurar menção “decisão aberta” em architecture se necessário; etapa continua `em_andamento`.

## Decisões abertas (explícitas — não bloqueiam a etapa se documentadas)

1. **Aceleração no harness v1:** fixar CPU-only (recomendado) ou permitir perfil GPU espelhado A/B depois — default desta spec = **CPU-only**.
2. **Grau de “Linux otimizado”:** nesta etapa A = Linux host + `ia-livre-runtime` sem campanha de sysctl/isolcpus; evolução de tuning fica backlog/etapa futura.
3. **Forma do entrypoint B futuro:** script espelho vs binário no ESP/QEMU — só precisa estar nomeado no contrato; implementação B fora desta etapa.
4. **Métricas extras** (joules, p95, VRAM): candidatas da architecture; fora do mínimo do harness v1.

## Etapa do roadmap

- Etapa 9 — Harness da hipótese Linha A vs Linha B (`em_andamento`, Issue [#9](https://github.com/eriksonlima/projeto-ia-livre/issues/9))
- Spec: `specs/harness-linha-a-b/`
- Pronto quando (roadmap): harness comparável (mesmo modelo/quantização/carga) documentado para Linha A (Linux otimizado) vs Linha B (IA Livre), sem confundir com métricas dos protótipos CPU/GPU das Etapas 5/8.
