# Spec — Ambiente de autonomia além do protótipo (v1 utilizável)

## Resultado visível

Existe uma **escolha documentada** (ADR + doc de desenho) da **primeira versão utilizável** da **camada 3** (ambiente de autonomia), além do protótipo da Etapa 7:

1. **Escopo v1** — o que entra (ferramentas além de `note`, política de memória, UX CLI mínima).
2. **Fronteira vs protótipo E7** — o que permanece contrato mínimo vs o que a v1 acrescenta.
3. **Critério verificável mínimo** — checklist/marcadores que uma etapa futura de implementação deve cumprir.
4. **Fora de escopo explícito** — P2P, kernel/SO IA Livre, marketplace, multi-agente, RAG vetorial.

A etapa é **só documental**. Implementação completa de novas ferramentas/código em `agent/` **não** é obrigatória; o gate `make verify-agent` do protótipo permanece válido.

## Contexto fixo (não reinventar)

- Protótipo atual (Etapa 7): [`docs/ambiente-autonomia-prototipo.md`](../../docs/ambiente-autonomia-prototipo.md) — loop + ferramenta `note` + JSONL; crate `agent/` (`ia-livre-agent`); consome `ia-livre-runtime` via subprocesso; gate `make verify-agent`.
- ADR 0001: agentes e ferramentas **fora** do kernel; autonomia evolui em ritmo próprio; este caminho **não exige** o SO IA Livre — [`docs/adr/0001-separacao-camadas-e-p2p.md`](../../docs/adr/0001-separacao-camadas-e-p2p.md).
- Arquitetura: camada 3 = agentes, memória persistente, ferramentas; consome o runtime — [`docs/architecture.md`](../../docs/architecture.md).
- Decisão aberta em architecture: «Forma e escopo do ambiente de autonomia na primeira versão utilizável».
- Runtime (Etapa 5): GGUF canônico TinyLlama; gate `make verify-runtime`. GPU (Etapa 8) é **opcional** e **fora** do critério mínimo da autonomia v1.
- Rede (Etapas 6/14) e kernel (4/10–12): **independentes** — não entram nesta v1.
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`; se não precisar, registrar.

## Decisão de desenho (única — obrigatória)

| Peça | Escolha nesta etapa |
|------|---------------------|
| Forma | **Desenho** (ADR + doc) — **não** implementação completa da v1 em `agent/` |
| Ambiente | Continua no **host Linux** (`std`); **não** exige SO IA Livre / QEMU / UEFI |
| Consumo do runtime | Mantém **subprocesso** CLI de `ia-livre-runtime` (CPU default); sem exigir refactor do runtime em lib |
| UX CLI mínima | **One-shot** com `--prompt` (texto do usuário) + `--model` / `--memory` / `--n-predict` já existentes; prompt fixo do protótipo vira **default de prova**, não o único modo documentado da v1. **REPL interativo** = futuro |
| Ferramentas v1 (allowlist) | (1) `note` — append nota (já no protótipo); (2) `recall` — listar/filtrar entradas recentes do JSONL; (3) `help` — listar ferramentas e contratos curtos. **Sem** shell arbitrário, rede ou write fora do workspace do agente |
| Política de memória | JSONL sob path gitignored; kinds mínimos `note` / `turn` / `tool`; **injeção no prompt** = últimas **N** entradas (N documentado, ex. 8) + notas marcadas; **sem** embeddings / RAG vetorial |
| Decisão de ferramenta | Allowlist + invocação **determinística no cenário de prova** (como E7); parsing espontâneo do SLM **não** é o único caminho do critério verificável |
| Critério verificável mínimo | Documentar marcadores-alvo da **próxima** implementação: além de `IA_LIVRE_TOOL_OK` / `MEMORY_OK` / `AGENT_OK` (E7), exigir prova de **≥2 ferramentas** da allowlist (`note` + `recall` ou `help`) e evidência de política de memória aplicada (ex. `IA_LIVRE_MEMORY_POLICY_OK` ou equivalente documentado). Gate E7 **não** quebra nesta etapa |
| ADR | **Nova** (ex.: `docs/adr/0005-autonomia-v1-utilizavel.md`) — status **aceita** no nível *desenho candidato*; implementação = etapa/backlog futuro |
| Doc de desenho | `docs/desenho-autonomia-v1.md` (ou nome equivalente fixado na Task 2) |

### Rejeitado (explícito)

- Implementar a v1 completa em `agent/` nesta etapa (salvo ponte documental).
- Integrar autonomia com Rede IA Livre / `node/` / P2P.
- Embutir agente no kernel UEFI ou exigir o SO IA Livre.
- Marketplace de ferramentas, multi-agente, orquestração distribuída.
- ReAct / CoT robusto, avaliação de qualidade do raciocínio, UI gráfica / IDE.
- Memória vetorial / RAG / embeddings como requisito da v1.
- Shell arbitrário, rede, ou I/O fora de um workspace documentado do agente.
- Trocar o modelo canônico ou exigir GPU para o critério mínimo.
- Declarar a camada 3 “pronta para produção” ou o protótipo E7 obsoleto sem fronteira clara.
- Várias propostas concorrentes sem escolher um escopo — a etapa **fecha um** desenho.

### Esboço do contrato v1 (a detalhar no doc de desenho)

```
Usuário CLI (--prompt "…")
        │
        ▼
ia-livre-agent
  1. Carregar JSONL (memória)
  2. Montar prompt = sistema curto + últimas N entradas + prompt do usuário
  3. Subprocesso ia-livre-runtime (CPU)
  4. Decisão de ferramenta (allowlist: note | recall | help)
  5. Executar ferramenta → efeito observável (arquivo / stdout)
  6. Persistir turn/tool no JSONL
  7. Emitir marcadores (E7 + extensão v1 documentada)
```

Compatibilidade: `make verify-agent` e marcadores E7 permanecem válidos até uma etapa de implementação da v1; o desenho **não** quebra o contrato do protótipo sem etapa dedicada.

Não-objetivos da v1 (desenho): REPL, P2P-tools, sandbox OS-level (seccomp/containers), marketplace, multi-agente, RAG, GPU obrigatória, lib de runtime compartilhada — listar no doc como **futuro**.

## Conteúdo obrigatório

### 1. ADR

- Contexto: lacuna «forma e escopo do ambiente de autonomia na primeira versão utilizável» em `architecture.md` + limites do protótipo E7 (`note` + prompt fixo + JSONL mínimo).
- Decisão: escopo v1 acima (UX one-shot, allowlist de 3 ferramentas, política de memória N-últimas, critério verificável mínimo, host-only).
- Consequências positivas/negativas; o que **não** fica decidido (implementação, REPL, integração P2P, RAG).
- Relação com ADR 0001 (autonomia fora do kernel / sem exigir SO) e com o protótipo Etapa 7 (evolução, não descarte silencioso).

### 2. Doc de desenho

- Motivação: por que ir além do cenário de prova único (`note` + prompt fixo).
- Fronteira **protótipo E7 × autonomia v1** (tabela: o que permanece / o que acrescenta / o que fica fora).
- UX CLI mínima (`--prompt` e defaults).
- Allowlist de ferramentas (contratos: nome, args, efeito, marcador).
- Política de memória (formato JSONL, kinds, N, injeção no prompt).
- Critério verificável mínimo (marcadores, cenário de prova v1, relação com `make verify-agent`).
- Alternativas consideradas (REPL-first, shell tool, LangChain, agente no kernel) e por que não agora.
- Não-objetivos e backlog de implementação futura (sem promover etapa sozinho).
- Honestidade: o `agent/` atual **não** implementa a v1 completa.

### 3. Pontes

- `docs/architecture.md`: mover/riscar «Forma e escopo do ambiente de autonomia…» para **decidida no nível desenho** (apontar ADR + doc); implementação continua aberta.
- Ponte em `docs/ambiente-autonomia-prototipo.md`: protótipo atual = Etapa 7; desenho v1 = Etapa 15 (não implementado).
- `AGENTS.md`: menção curta na estrutura/docs (ponte), sem inventar gate de código novo obrigatório nesta etapa.
- README: avaliar (`readme-por-fatia`).

## Fora de escopo

- Código de produto em `agent/`, `runtime/`, `node/`, `kernel/` (exceto se ponte documental citar paths existentes)
- Implementação de `recall` / `help` / `--prompt` usuário / novos marcadores no crate
- Integração com Rede IA Livre / P2P / marketplace
- Kernel UEFI, QEMU, Linha B
- RAG, multi-agente, UI, sandbox OS-level, shell arbitrário
- Mudança de manifesto ou de ADR 0001
- Nova etapa de implementação sem promoção via backlog / pedido explícito
- Gate `make verify-agent` novo ou alterado nesta etapa (só **documentar** o critério futuro)

## Critérios de aceite

- [ ] ADR nova registra **um** escopo de autonomia v1 utilizável (UX, ferramentas, memória, critério verificável) com fronteiras e consequências
- [ ] Doc de desenho detalha fronteira vs E7, allowlist, política de memória, critério verificável mínimo e não-objetivos (P2P, kernel, marketplace, RAG, multi-agente)
- [ ] `architecture.md` deixa de listar a forma/escopo da autonomia v1 como “aberta sem proposta”; aponta ADR/doc; implementação permanece aberta
- [ ] Ponte honesta no doc do protótipo: Etapa 7 ≠ desenho v1 ≠ implementação
- [ ] README avaliado (`readme-por-fatia`)
- [ ] Sem código de produto novo no `agent/` (nem outros crates de produto) nesta etapa
- [ ] Etapa 15 não é marcada `feita` nesta spec (só após revisão pelo agente principal)

## Riscos e rollback

- **Risco:** leitor achar que `agent/` já é a v1 utilizável → avisos explícitos «desenho ≠ implementação».
- **Risco:** escopo inchado (implementar ferramentas/REPL agora) → Pronto quando = só doc/ADR + critério verificável documentado.
- **Risco:** ADR contradizer 0001 (amarrar autonomia ao SO) → rejeitar; autonomia continua no host sem exigir IA Livre.
- **Risco:** allowlist frouxa (shell/rede) → a decisão desta spec **rejeita** shell/rede na v1; se evidência futura mudar, nova ADR.
- **Risco:** quebrar gate E7 ao “antecipar” marcadores → critério v1 é **alvo documentado**; `make verify-agent` intacto nesta etapa.
- **Rollback:** reverter ADR/doc/pontes; etapa continua `em_andamento`.

## Etapa do roadmap

- Etapa 15 — Ambiente de autonomia além do protótipo (v1 utilizável) (`em_andamento`, Issue [#15](https://github.com/eriksonlima/projeto-ia-livre/issues/15))
- Spec: `specs/autonomia-v1-utilizavel/`
- Pronto quando (roadmap): escopo documentado da primeira versão utilizável da camada 3 e critério verificável mínimo — ainda no host, sem exigir o SO IA Livre.
