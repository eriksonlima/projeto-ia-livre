# Spec — Contexto de produto e arquitetura inicial

## Resultado visível

`docs/product-context.md` e `docs/architecture.md` aprofundados (sem apagar o esboço existente) descrevem de forma explícita as quatro camadas, a hipótese de pesquisa (o que comparar e o que **não** assumir), decisões já tomadas vs abertas, e a fronteira com as Etapas 4+. Se houver escolha estrutural de consenso já registrada no architecture, um ADR `docs/adr/0001-*.md` documenta essa decisão; caso contrário, não inventar ADR cosmético.

## Contexto fixo (não reinventar)

- Fonte canônica de princípios/governança: [`docs/manifesto.md`](../../docs/manifesto.md) — **não reescrever** nesta etapa.
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre (como no manifesto).
- Esboços atuais em `docs/product-context.md` e `docs/architecture.md` são a base: expandir e estruturar, não substituir por documento paralelo.
- Template de ADR: `docs/adr/0000-template.md`.

## Conteúdo obrigatório

### 1. `docs/product-context.md` (aprofundar)

Manter e enriquecer as seções existentes (problema, usuários, princípios com link ao manifesto, não objetivos, métricas). Explicitar no mínimo:

- Papel de cada camada **do ponto de vista do produto** (o que o usuário/contribuidor ganha com kernel, runtime, autonomia, Rede), sem virar ADR técnico.
- Hipótese de pesquisa como métrica de sucesso: comparação **comparável** (mesmo hardware/modelo) entre IA Livre e Linux otimizado para a mesma carga — e o que **não** conta como prova (ex.: só trocar o runtime em cima de drivers genéricos sem mecanismos nativos).
- Fronteira com etapas futuras: esta etapa é só documentação de contexto; bootstrap de código começa na Etapa 4.

### 2. `docs/architecture.md` (aprofundar)

Expandir as quatro camadas com responsabilidade clara de cada uma:

| Camada | Nome | Responsabilidade mínima a documentar |
|--------|------|--------------------------------------|
| 1 | **IA Livre (kernel)** | boot, memória, CPU/GPU, dispositivos, isolamento, escalonamento orientado a inferência |
| 2 | **Runtime nativo de IA** | inferência/treinamento, tensores, KV cache, backends de aceleração |
| 3 | **Ambiente de autonomia** | agentes, memória persistente, ferramentas, experimentação |
| 4 | **Rede IA Livre** | protocolo P2P comum (nós nativos e nós em SO convencional) |

Além disso, obrigatório:

- **Hipótese de pesquisa** — o que comparar (SO especializado vs Linux otimizado, mesmo hardware/modelo); o que **não** assumir (ex.: que “SO próprio” vence só por existir; que GPU multi-GPU está resolvida; que o runtime genérico no Linux já é o baseline justo sem otimizações equivalentes).
- **Decisões já tomadas** (mínimo, se ainda forem consenso): SO não obrigatório na Rede; kernel pequeno/auditável com inteligência pesada fora do kernel; CPU/QEMU (x86-64 + UEFI) primeiro; NVIDIA multi-GPU depois; protocolo P2P independente do kernel (desenvolvível em paralelo no host).
- **Decisões abertas** — listar explicitamente o que ainda não está fechado (ex.: desenho fino de scheduler/memória model-aware, stack P2P concreto, licenças por componente, aceleração além do CPU inicial).
- **Referências** — AgentOS, SLM-OS, TensorOS, CLLM como estudo de lacunas (GPU, multi-GPU, KV cache, multi-tenant), sem copiar arquitetura alheia como decisão.
- **Fronteira Etapa 4+** — nenhum bootstrap de código nesta etapa; Etapa 4 = kernel mínimo QEMU; 5 = runtime CPU; 6 = nó P2P em SO convencional.

### 3. ADR inicial (condicional)

Registrar **ADR 0001** se (e somente se) houver escolha estrutural de consenso a cristalizar agora. Candidatas naturais já esboçadas:

- Separação **kernel × runtime** (inteligência pesada fora do kernel).
- **Protocolo P2P independente do SO/kernel** (Rede utilizável sem instalar IA Livre).

Se ambas forem consenso e já estiverem só no `architecture.md`, um único ADR 0001 que cubra a separação em camadas + independência do P2P é **desejável**. Não criar ADR só para repetir o manifesto ou para decisões ainda abertas.

## Fora de escopo

- Código do kernel, runtime, ambiente de autonomia ou nó P2P
- Reescrever ou alterar o manifesto
- Benchmarks reais, drivers GPU, multi-GPU
- Bootstrap UEFI/QEMU (Etapa 4)
- Implementação de inferência CPU (Etapa 5) ou cliente P2P (Etapa 6)
- Escolher stack P2P definitivo, licenças finais por componente ou desenho detalhado de scheduler
- ADRs cosméticos ou “propostos” sem decisão real

## Critérios de aceite

- [x] `docs/product-context.md` aprofunda problema/usuários/princípios (link ao manifesto)/não objetivos/métricas e deixa clara a hipótese de pesquisa e a fronteira com Etapa 4+
- [x] `docs/architecture.md` descreve as quatro camadas (kernel, runtime, autonomia, Rede/P2P) com responsabilidades explícitas
- [x] Hipótese de pesquisa documenta o que comparar e o que **não** assumir
- [x] Decisões tomadas vs abertas estão separadas e legíveis
- [x] Se houver escolha estrutural de consenso, existe `docs/adr/0001-*.md` (status aceita ou proposta justificada) alinhado ao architecture; senão, architecture explica por que ADR ainda não cabe
- [x] Manifesto permanece intacto (sem reescrita nesta etapa)
- [x] Nenhum código de produto bootstrapado
- [x] Gate de `AGENTS.md` → **Como verificar** continua passando (docs-only)

## Riscos e rollback

- **Risco:** architecture vira wishlist sem distinção aberto/fechado → forçar seções “Decisões tomadas” e “Decisões abertas”.
- **Risco:** ADR cosmético ou que contradiz o manifesto → só ADR estrutural alinhado aos princípios; senão omitir.
- **Risco:** invadir Etapa 4+ com snippets de kernel/runtime → manter só documentação e fronteiras.
- **Risco:** apagar conteúdo útil do esboço → expandir in-place; preservar links e decisões preliminares já alinhadas.
- **Rollback:** reverter diffs em `docs/product-context.md`, `docs/architecture.md` e eventual ADR 0001; etapa permanece `em_andamento` até o Pronto quando.

## Etapa do roadmap

- Etapa 3 — Contexto de produto e arquitetura inicial (`em_andamento`, Issue [#3](https://github.com/eriksonlima/projeto-ia-livre/issues/3))
- Pronto quando (roadmap): `docs/product-context.md` e `docs/architecture.md` descrevem camadas (kernel, runtime, autonomia, P2P), hipóteses de pesquisa e decisões abertas; ADR inicial se houver escolha estrutural.
