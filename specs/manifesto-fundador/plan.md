# Plan — Manifesto Fundador e identidade

## Abordagem

Uma fatia vertical única: redigir o manifesto completo em português, publicar em `docs/manifesto.md`, e acrescentar um apontador curto na seção Documentação do `README.md`. Não duplicar o corpo do manifesto em CONTRIBUTING, product-context ou Memory Bank — no máximo uma linha de referência se útil.

Estrutura sugerida de `docs/manifesto.md`:

1. Título + lema
2. Missão
3. Nomenclatura (tabela dos três nomes)
4. Princípios imutáveis (lista numerada ou com âncoras)
5. Governança (alternativa B) e proteções em camadas
6. Política open source e licenças (preferência a confirmar)
7. Sustentabilidade e financiamento
8. Relação com o restante da documentação (links para README, product-context, ROADMAP)

Fonte de verdade de tom e nomes: `README.md`, `docs/product-context.md` e o contexto já decidido na Issue #2 / pedido desta etapa. Não reinventar branding.

## Arquivos prováveis

- `docs/manifesto.md` — criar (documento principal)
- `README.md` — editar só a lista Documentação (link ao manifesto)
- Opcional mínimo: `docs/product-context.md` — uma linha “ver manifesto” se reforçar coerência; evitar reescrever princípios

## Dependências

- Etapa 1 feita (scaffold e remote)
- Nenhuma dependência de código ou ADRs
- Etapa 3 permanece pendente; o manifesto não substitui architecture.md

## Verificação

1. Checklist dos critérios de aceite em `spec.md` (leitura do arquivo publicado)
2. Conferir nomenclatura e lema contra `README.md` e `docs/product-context.md`
3. Gate de `AGENTS.md` → **Como verificar** (scaffold/docs; sem regressão)
4. Confirmar que licenças estão marcadas como decisão a confirmar
