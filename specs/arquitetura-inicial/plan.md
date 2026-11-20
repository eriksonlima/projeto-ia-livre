# Plan — Contexto de produto e arquitetura inicial

## Abordagem

Uma fatia vertical única: aprofundar os dois documentos de produto/arquitetura a partir dos esboços existentes e, se justificável, registrar ADR 0001. Não criar documentos paralelos nem tocar no manifesto.

Ordem sugerida de redação:

1. **`docs/architecture.md`** — expandir camadas, hipótese (comparar / não assumir), decisões tomadas vs abertas, referências e fronteira Etapa 4+.
2. **`docs/product-context.md`** — alinhar linguagem de produto à arquitetura (papéis das camadas para usuários/contribuidores, métricas da hipótese, não objetivos e fronteira), mantendo o manifesto como link canônico de princípios.
3. **ADR 0001** — se o consensus estrutural (kernel × runtime separados; P2P independente do SO) estiver claro no architecture, criar `docs/adr/0001-separacao-camadas-e-p2p.md` (ou título equivalente) a partir de `docs/adr/0000-template.md`, status `aceita`, e referenciar no architecture. Se ainda houver dúvida real, documentar a abertura no architecture e **não** forçar ADR.

Tom: técnico-claro, em português, coerente com manifesto e README. Sem código de bootstrap.

## Arquivos prováveis

- `docs/architecture.md` — expandir (principal)
- `docs/product-context.md` — expandir (alinhamento de produto)
- `docs/adr/0001-*.md` — criar **somente** se houver escolha estrutural de consenso
- Opcional mínimo: `README.md` — só se faltar apontador para ADRs; evitar churn

Não editar: `docs/manifesto.md`, código de produto, scaffold de kernel/runtime.

## Dependências

- Etapas 1–2 feitas (scaffold + manifesto)
- Esboços atuais de product-context e architecture
- Template ADR em `docs/adr/0000-template.md`
- Etapas 4–6 permanecem pendentes; esta fatia não as inicia

## Verificação

1. Checklist dos critérios de aceite em `spec.md` (leitura dos docs publicados)
2. Conferir que manifesto não foi alterado (`git diff docs/manifesto.md` vazio ou inexistente)
3. Conferir nomenclatura contra manifesto/README
4. Se ADR 0001 existir: formato do template, decisão estrutural explícita, link a partir de `docs/architecture.md`
5. Gate de `AGENTS.md` → **Como verificar** (docs-only; sem regressão de scaffold)
