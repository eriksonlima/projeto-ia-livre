# Spec — Lacunas de arquitetura (scheduler / memória model-aware)

## Resultado visível

Existe um **desenho documentado** (ADR + doc de desenho) de **um** mecanismo nativo candidato que diferencia a **Linha B** (IA Livre + mecanismos) da **Linha A** (Linux genérico otimizado):

1. **Classes de memória model-aware** expostas pelo kernel ao runtime (KV cache vs pesos / pesos estáticos).
2. **Hints de fase** prefill vs decode no **scheduler** de inferência (runtime anuncia; kernel escala).
3. Fronteiras claras, não-objetivos e o que fica para **implementação futura**.

A etapa é **só documental**. Não há implementação completa no kernel, nem prova da hipótese A vs B, nem carga GGUF canônica na Linha B.

## Contexto fixo (não reinventar)

- Decisão aberta em [`docs/architecture.md`](../../docs/architecture.md): «Desenho fino de memória model-aware e do scheduler de inferência».
- Hipótese de pesquisa: mecanismos nativos (memória model-aware, scheduler consciente de prefill/decode, etc.) vs Linux de propósito geral — **ainda não comprovada**.
- ADR 0001: inferência **fora** do kernel; kernel fornece mecanismos — [`docs/adr/0001-separacao-camadas-e-p2p.md`](../../docs/adr/0001-separacao-camadas-e-p2p.md).
- Etapa 12: Linha B = proxy microbench pós-ExitBoot; carga TinyLlama/GGUF em B **continua aberta** — [`docs/runtime-nativo-linha-b.md`](../../docs/runtime-nativo-linha-b.md).
- Referências próximas (estudar como **lacunas**, não blueprint): SLM-OS, TensorOS, AgentOS — ver tabela em `architecture.md`.
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`; se não precisar, registrar.

## Decisão de desenho (única — obrigatória)

| Peça | Escolha nesta etapa |
|------|---------------------|
| Forma | **Desenho** (ADR + doc) — **não** implementação completa |
| Proposta candidata | Interface **kernel ↔ runtime** com (1) **classes de memória** tipadas para inferência e (2) **hints de fase** no scheduler |
| Memória model-aware | Kernel expõe alocação / regiões com **classe** mínima: `Weights` (somente leitura após load) e `KvCache` (leitura/escrita quente no decode); runtime declara a classe ao pedir memória |
| Scheduler | Runtime emite **hint de fase** `Prefill` \| `Decode` (e opcionalmente `Idle` / `Load`); kernel usa o hint para prioridade / quantum / afinidade candidata — **sem** embutir o modelo no núcleo |
| Fronteira ADR 0001 | Inferência, tensores, GGUF, sampling e KV *lógica* permanecem no **runtime**; kernel só mecanismos (páginas/regiões tipadas + política de escala por hint) |
| Diferencial vs Linha A | Em Linux genérico, KV e weights competem como heap anônimo; o SO não distingue prefill/decode. Em B, o contrato nativo **nomeia** essas classes e fases |
| ADR | **Nova** (ex.: `docs/adr/0003-memoria-model-aware-e-scheduler-fases.md`) — status **aceita** no nível *desenho candidato*; implementação = etapas futuras |
| Doc de desenho | `docs/desenho-memoria-scheduler-nativo.md` (ou nome equivalente fixado na Task 2) |

### Rejeitado (explícito)

- Implementar allocator tipado / scheduler real no `kernel/` nesta etapa (salvo ponte documental).
- Colocar inferência, llama.cpp ou GGUF **dentro** do kernel.
- Copiar SLM-OS / TensorOS / AgentOS como blueprint.
- Declarar hipótese A vs B comprovada ou “mecanismo já vence Linux”.
- Desenhar multi-tenant completo, GPU manager nativo, RDMA ou multi-GPU como critério desta etapa.
- Várias propostas concorrentes sem escolher uma — a etapa **fixa uma** candidata.

### Esboço do contrato (a detalhar no doc de desenho)

```
Runtime                          Kernel (mecanismos)
────────                         ───────────────────
alloc(class=Weights|KvCache) →   região tipada + políticas (pin, RO pós-load, …)
set_phase(Prefill|Decode|…)  →   hint para scheduler (prioridade / quantum)
free / resize (futuro)       →   liberação / compactação candidata
```

Não-objetivos do contrato v1 (desenho): syscalls finais estáveis, ABI binária, MMU completa, swap de KV para disco, preemptividade fina com timers maduros — listar no doc como **futuro**.

## Conteúdo obrigatório

### 1. ADR

- Contexto: lacuna aberta + risco de “só Linux + runtime” (ADR 0001).
- Decisão: a proposta candidata acima (classes + hints).
- Consequências positivas/negativas; o que **não** fica decidido (implementação, ABI, GPU).
- Relação com Etapas 10–12 (mapa/bump → ExitBoot → proxy B) e com a hipótese.

### 2. Doc de desenho

- Motivação vs Linha A (por que classes + fases diferenciam).
- Modelo de classes de memória e ciclo de vida (load → prefill → decode → idle).
- Hints de scheduler e políticas candidatas (prioridade, quantum, o que o kernel **não** decide).
- Fronteiras kernel × runtime (ADR 0001).
- Lacunas aprendidas de SLM-OS / TensorOS / AgentOS (parágrafo curto cada — o que falta neles / o que **não** copiar).
- Não-objetivos e backlog de implementação futura (sem promover etapa sozinho).
- Como o proxy Linha B atual **não** implementa ainda este contrato (honestidade).

### 3. Pontes

- `docs/architecture.md`: mover/riscar a decisão aberta de memória/scheduler para **decidida no nível desenho** (apontar ADR + doc); hipótese continua aberta.
- Ponte mínima em `docs/runtime-nativo-linha-b.md` e/ou `docs/harness-linha-a-b.md`: desenho candidato ≠ implementação ≠ prova.
- `AGENTS.md`: menção curta na estrutura/docs (ponte), sem inventar gate de código.
- README: avaliar (`readme-por-fatia`).

## Fora de escopo

- Código de produto no `kernel/`, `runtime/`, `node/`, `agent/` (exceto se alguma ponte documental exigir referência a paths existentes)
- Implementação de allocator tipado, MMU, scheduler preemptivo, syscalls
- Carga GGUF / TinyLlama na Linha B
- Prova ou refutação da hipótese A vs B
- GPU manager nativo, multi-GPU, multi-tenant completo
- Mudança de manifesto ou protocolo P2P
- Nova etapa de implementação sem confirmação / backlog

## Critérios de aceite

- [ ] ADR nova registra **uma** proposta candidata (classes de memória + hints prefill/decode) com fronteiras e consequências
- [ ] Doc de desenho detalha interface kernel↔runtime, ciclo de vida, não-objetivos e o que fica para o futuro
- [ ] `architecture.md` deixa de listar o desenho fino como “aberto sem proposta”; aponta ADR/doc; hipótese permanece não comprovada
- [ ] Pontes honestas: Linha B atual = proxy; este desenho **não** está implementado nem medido no harness
- [ ] Referências SLM-OS / TensorOS / AgentOS tratadas como lacunas, não blueprint
- [ ] README avaliado (`readme-por-fatia`)
- [ ] Sem código de produto novo no kernel/runtime nesta etapa
- [ ] Etapa 13 não é marcada `feita` nesta spec (só após revisão pelo agente principal)

## Riscos e rollback

- **Risco:** leitor achar que o desenho = Linha B já diferenciada → avisos explícitos “desenho ≠ implementação ≠ prova”.
- **Risco:** escopo inchado (implementar scheduler agora) → Pronto quando = só doc/ADR.
- **Risco:** ADR contradizer 0001 (inferência no kernel) → rejeitar; mecanismos só.
- **Rollback:** reverter ADR/doc/pontes; etapa continua `em_andamento`.

## Etapa do roadmap

- Etapa 13 — Lacunas de arquitetura (scheduler / memória model-aware) (`em_andamento`, Issue [#12](https://github.com/eriksonlima/projeto-ia-livre/issues/12))
- Spec: `specs/lacunas-arquitetura-scheduler-memoria/`
- Pronto quando (roadmap): desenho (doc/ADR) do mecanismo nativo candidato que diferencia Linha B da A — escopo de desenho, não implementação completa.
