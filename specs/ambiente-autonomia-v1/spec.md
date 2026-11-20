# Spec — Ambiente de autonomia além do protótipo (v1 utilizável)

## Resultado visível

Existe um **escopo documentado** da **primeira versão utilizável** da camada 3 (ambiente de autonomia), além do protótipo da Etapa 7, com **critério verificável mínimo** explícito:

1. **Forma e fronteiras** da autonomia v1 (o que entra vs o que fica fora).
2. **Evolução** a partir do contrato E7 (`agent/` + `note` + JSONL + runtime subprocesso).
3. **Critério verificável mínimo** da v1 (marcadores / checklist de gate futuros) — ainda no **host**, **sem** exigir o SO IA Livre.

A etapa é **só documental** (`doc-only`). Não há implementação completa do agente v1 em `agent/`, nem integração P2P/kernel, nem UI.

## Contexto fixo (não reinventar)

- Protótipo atual (Etapa 7): [`docs/ambiente-autonomia-prototipo.md`](../../docs/ambiente-autonomia-prototipo.md) — loop single-shot, ferramenta `note`, memória JSONL, consumo de `ia-livre-runtime` via subprocesso; crate `agent/`; gate `make verify-agent`.
- ADR 0001: agentes e ferramentas **fora** do kernel; autonomia evolui em ritmo próprio; **não** exige o SO IA Livre — [`docs/adr/0001-separacao-camadas-e-p2p.md`](../../docs/adr/0001-separacao-camadas-e-p2p.md).
- Decisão aberta em [`docs/architecture.md`](../../docs/architecture.md): «Forma e escopo do ambiente de autonomia na primeira versão utilizável».
- Product context: agentes, memória e ferramentas para aprender e experimentar no próprio ambiente — [`docs/product-context.md`](../../docs/product-context.md).
- Spec do protótipo: [`specs/ambiente-autonomia/`](../ambiente-autonomia/).
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`; se não precisar, registrar.

## Decisão de desenho (única — obrigatória)

| Peça | Escolha nesta etapa |
|------|---------------------|
| Forma da etapa | **Desenho** (ADR + doc de escopo) — **não** implementação do agente v1 |
| Decisão doc vs código | **doc-only** — critério verificável desta etapa = checklist documental; **não** altera `agent/` / gates de código |
| Ambiente | Host Linux (`std`); autonomia v1 **não exige** o SO IA Livre / QEMU / UEFI (ADR 0001) |
| Base de código (próximo protótipo) | Evoluir o crate **`agent/`** existente — **não** criar crate novo |
| Consumo do runtime | Continua via **subprocesso** CLI `ia-livre-runtime` + GGUF canônico; sem refactor obrigatório do `runtime/` em lib |
| Loop v1 | Sessão com **objetivo CLI** (`--goal` ou equivalente) e **até N turnos** limitados (N documentado, ex. 3); não só o prompt fixo de prova E7 |
| Memória v1 | JSONL permanece; além de `note` (append), v1 exige capacidade de **consultar** memória (ex. listar últimos K / `recall` por texto) |
| Ferramentas v1 | **Registro explícito** de ferramentas; mínimo = `note` + **uma** segunda ferramenta de consulta à memória (`list_notes` / `recall`) |
| Critério verificável **desta etapa** | ADR + doc de escopo + pontes; sem diff de produto em `agent/` |
| Critério verificável **mínimo da v1** (próxima implementação) | Gate futuro (ou extensão de `verify-agent`) exige, além dos marcadores E7: prova de objetivo CLI aceito **e** prova da segunda ferramenta / consulta à memória (marcadores candidatos documentados, ex. `IA_LIVRE_GOAL_OK` + `IA_LIVRE_RECALL_OK`) |
| ADR | **Nova** (ex.: `docs/adr/0005-ambiente-autonomia-v1.md`) — status **aceita** no nível *desenho / escopo*; implementação = etapa/backlog futuro |
| Doc de escopo | `docs/desenho-ambiente-autonomia-v1.md` (ou nome equivalente fixado na Task 2) |

### Rejeitado (explícito)

- Implementar o loop multi-turno / `--goal` / segunda ferramenta nesta etapa (salvo ponte documental).
- Multi-agente, orquestração distribuída, marketplace de ferramentas.
- ReAct/CoT robusto ou avaliação de qualidade do raciocínio como critério desta etapa.
- Integração com `node/` / Rede IA Livre (tarefas P2P).
- Integração com kernel UEFI / QEMU.
- Memória vetorial / embeddings / RAG completo.
- Sandbox OS-level (seccomp, containers) como requisito v1.
- UI gráfica / IDE / notebook.
- Declarar o protótipo E7 obsoleto sem fronteira clara; o gate `make verify-agent` **permanece** válido.
- Inflar a etapa com código “só um pouquinho” — a decisão fixada é **doc-only**.

### Esboço do contrato v1 (a detalhar no doc)

```
Usuário / CLI
  --goal "…"  --memory …  --max-turns N
       │
       ▼
agent/ (host)
  carrega memória JSONL
  para t in 1..=N:
    monta prompt (goal + trecho de memória + ferramentas)
    chama ia-livre-runtime (subprocesso)
    pode invocar note | recall/list_notes
    persiste turnos
  emite marcadores (E7 + GOAL/RECALL ou equivalentes)
```

Compatibilidade: `IA_LIVRE_AGENT_OK` / `TOOL_OK` / `MEMORY_OK` do protótipo E7 **não** são removidos nesta etapa; o desenho v1 **estende** o contrato.

Não-objetivos da v1 (desenho): multi-agente, P2P, kernel, RAG vetorial, sandbox OS, UI, framework LangChain-like — listar no doc como **futuro**.

## Conteúdo obrigatório

### 1. ADR

- Contexto: lacuna «forma e escopo da autonomia na primeira versão utilizável» em `architecture.md` + limites do protótipo E7 (single-shot, uma ferramenta, prompt fixo de prova).
- Decisão: escopo v1 acima (host, `--goal` + N turnos, JSONL + recall, registro com 2 ferramentas, subprocesso runtime); etapa atual = desenho; implementação futura.
- Consequências positivas/negativas; o que **não** fica decidido (API estável multi-linguagem, parsing confiável de tool-call do SLM, GPU no agente, integração P2P).
- Relação com ADR 0001 (autonomia fora do kernel / sem exigir SO) e com o protótipo Etapa 7 (evolução, não descarte).

### 2. Doc de escopo / desenho

- Motivação: por que o protótipo E7 não basta como “utilizável”.
- Modelo de sessão (goal, turnos, limites).
- Memória: formato JSONL estendido se necessário; contrato de `note` + consulta.
- Registro de ferramentas e tabela de mensagens/efeitos.
- **Critério verificável mínimo da v1** (marcadores candidatos + o que o gate futuro deve exigir).
- Fronteira do **próximo protótipo** (checklist: o que implementar depois; o que continua fora).
- Alternativas consideradas (agente single-shot “enfeitado”, framework externo, embutir no kernel) e por que não.
- Honestidade: o `agent/` atual **não** implementa v1.

### 3. Pontes

- `docs/architecture.md`: mover/riscar «Forma e escopo do ambiente de autonomia…» para **decidida no nível desenho/escopo** (apontar ADR + doc); implementação continua aberta.
- Ponte em `docs/ambiente-autonomia-prototipo.md`: protótipo = Etapa 7; escopo v1 = Etapa 15 (não implementado).
- `AGENTS.md`: menção curta na estrutura/docs (ponte), **sem** inventar gate de código novo nesta etapa.
- README: avaliar (`readme-por-fatia`).

## Fora de escopo

- Código de produto em `agent/`, `kernel/`, `runtime/`, `node/` (exceto se ponte documental citar paths existentes)
- Alterar `make verify-agent` / `scripts/verify-agent.sh` nesta etapa
- Multi-agente, P2P, UEFI-agente, RAG vetorial, UI, sandbox OS
- Mudança de manifesto ou de ADR 0001
- Nova etapa de implementação sem promoção via backlog / pedido explícito

## Critérios de aceite

- [ ] ADR nova registra **um** escopo v1 (loop com goal/turnos, memória+consulta, 2 ferramentas no registro, host sem exigir SO) com fronteiras e consequências
- [ ] Doc de escopo detalha motivação vs E7, contrato v1, **critério verificável mínimo** (marcadores/gate futuros) e fronteira do próximo protótipo
- [ ] `architecture.md` deixa de listar a forma/escopo da autonomia v1 como “aberta sem proposta”; aponta ADR/doc; implementação permanece aberta
- [ ] Ponte honesta no doc do protótipo: Etapa 7 ≠ escopo v1 ≠ implementação
- [ ] README avaliado (`readme-por-fatia`)
- [ ] Sem código de produto novo no `agent/` (nem outros crates de produto) nesta etapa — decisão **doc-only**
- [ ] Gate `make verify-agent` do protótipo **não** é quebrado nem substituído nesta etapa
- [ ] Etapa 15 não é marcada `feita` nesta spec (só após revisão pelo agente principal)

## Riscos e rollback

- **Risco:** leitor achar que `agent/` já é v1 utilizável → avisos explícitos «desenho ≠ implementação».
- **Risco:** escopo inchado (implementar multi-turno agora) → Pronto quando = só doc/ADR + critério documentado; decisão **doc-only**.
- **Risco:** ADR contradizer 0001 (amarrar autonomia ao SO) → rejeitar; continua host-only sem exigir IA Livre.
- **Risco:** critério “verificável” vago → o doc **fixa** marcadores candidatos e o que o próximo gate deve exigir além de E7.
- **Rollback:** reverter ADR/doc/pontes; etapa continua `em_andamento`.

## Etapa do roadmap

- Etapa 15 — Ambiente de autonomia além do protótipo (v1 utilizável) (`em_andamento`, Issue [#15](https://github.com/eriksonlima/projeto-ia-livre/issues/15))
- Spec: `specs/ambiente-autonomia-v1/`
- Pronto quando (roadmap): escopo documentado da primeira versão utilizável da camada 3 e critério verificável mínimo — ainda no host, sem exigir o SO IA Livre.
