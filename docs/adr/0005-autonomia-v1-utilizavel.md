# ADR 0005 — Escopo da autonomia v1 utilizável (camada 3)

- Status: aceita (nível **desenho**; implementação = **Etapa 24** em `agent/`)
- Data: 2026-11-20

## Contexto

O protótipo da Etapa 7 entrega um loop mínimo no host: prompt fixo de prova, uma ferramenta (`note`), JSONL e gate `make verify-agent` — ver [`docs/ambiente-autonomia-prototipo.md`](../ambiente-autonomia-prototipo.md). Em [`docs/architecture.md`](../architecture.md) restava aberta a «forma e escopo do ambiente de autonomia na primeira versão utilizável».

Sem desenho, a próxima implementação em `agent/` pode ou ficar eternamente no cenário de prova, ou expandir sem fronteira (shell, P2P, RAG). ADR 0001 permanece: agentes **fora** do kernel; este caminho **não exige** o SO IA Livre.

Esta ADR **não** implementa a v1 em `agent/`. Detalhe: doc de desenho da Etapa 15 (Task 2).

## Decisão

1. **Ambiente:** autonomia v1 continua no **host Linux** (`std`); **não** exige SO IA Livre / QEMU / UEFI.
2. **Runtime:** mantém **subprocesso** CLI de `ia-livre-runtime` (CPU default); sem exigir refactor do runtime em lib; GPU **não** é critério mínimo.
3. **UX CLI mínima:** modo **one-shot** com `--prompt` (texto do usuário) + flags já existentes (`--model` / `--memory` / `--n-predict`). O prompt fixo do protótipo vira **default de prova**, não o único modo documentado. **REPL** = futuro.
4. **Allowlist de ferramentas v1:**
   - `note` — append nota (já no protótipo);
   - `recall` — listar/filtrar entradas recentes do JSONL;
   - `help` — listar ferramentas e contratos curtos.
   - **Sem** shell arbitrário, rede ou write fora do workspace documentado do agente.
5. **Política de memória:** JSONL gitignored; kinds mínimos `note` / `turn` / `tool`; injeção no prompt = últimas **N** entradas (N fixado no doc de desenho, ex. 8). **Sem** embeddings / RAG vetorial.
6. **Decisão de ferramenta no critério de prova:** allowlist + invocação **determinística** no cenário de prova (como E7); parsing espontâneo do SLM **não** é o único caminho.
7. **Critério verificável mínimo (próxima implementação):** além de `IA_LIVRE_TOOL_OK` / `MEMORY_OK` / `AGENT_OK` (E7), prova de **≥2 ferramentas** da allowlist (`note` + `recall` ou `help`) e evidência de política de memória aplicada (ex. `IA_LIVRE_MEMORY_POLICY_OK` ou equivalente). Gate E7 **não** quebra nesta etapa documental.
8. **Fronteira ADR 0001:** autonomia fora do kernel; participar da Rede / usar o SO **não** são pré-requisitos desta v1.

### Rejeitado nesta decisão

- P2P / `node/` / integração Rede; agente no kernel; marketplace; multi-agente; RAG; shell/rede; UI gráfica; GPU obrigatória; declarar produção.

### O que esta ADR **não** decide

- Implementação no crate `agent/` (código, gate novo).
- REPL interativo, integração Rede IA Livre, sandbox OS-level, lib compartilhada do runtime.

## Consequências

### Positivas

- Fecha a lacuna de architecture no nível **desenho** com um escopo claro e auditável
- Evolui o protótipo E7 sem descartá-lo (gate atual permanece)
- Mantém superfície pequena (3 ferramentas) alinhada ao manifesto (propósito, não curiosidade)

### Negativas

- Sem implementação nesta etapa — “utilizável” só no papel até etapa futura
- One-shot sem REPL limita UX interativa até backlog futuro
- Allowlist estreita pode frustrar quem espera shell/RAG cedo

## Relação com etapas e ADRs

| Peça | Papel |
|------|--------|
| ADR 0001 | Autonomia fora do kernel / sem exigir SO — intacta |
| Etapa 7 | Protótipo `note` + JSONL — continua válido |
| Etapa 15 | Esta ADR + doc de desenho — **sem** código `agent/` |
| Etapa 24 | Implementação v1 (`--prompt`, `recall`/`help`, política N=8) + gate estendido |

Doc de desenho (Task 2): [`docs/desenho-autonomia-v1.md`](../desenho-autonomia-v1.md) (a criar).
