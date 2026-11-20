# Spec — Manifesto Fundador e identidade

## Resultado visível

Documento fundador publicado em `docs/manifesto.md` (ou caminho equivalente em `docs/`) que define missão, princípios imutáveis, nomenclatura oficial, governança descentralizada (alternativa B) com proteções em camadas, política open source e sustentabilidade — legível por qualquer pessoa sem depender de código ou ADRs técnicos.

## Contexto fixo (não reinventar)

| Nome | Papel |
|------|--------|
| **Projeto IA Livre** | Iniciativa brasileira, open source, sem fins lucrativos: ecossistema + comunidade + governança |
| **IA Livre** | Sistema operacional próprio, do zero, com IA como finalidade nativa (não “Linux + Ollama”) |
| **Rede IA Livre** | Rede P2P; participar **não** exige o SO — nó em Linux/Windows/etc. permitido |

- Lema: *Nascido no Brasil. Aberto ao mundo. Livre por princípio.*
- Tom alinhado a `README.md` e `docs/product-context.md`: direto, soberania tecnológica, colaboração P2P, sem jargão de marketing vazio.

## Conteúdo obrigatório do manifesto

1. **Missão** — por que existe o Projeto IA Livre; problema (concentração proprietária) e resposta (infraestrutura aberta, brasileira na origem, IA nativa).
2. **Princípios imutáveis** — regras que resistem inclusive aos fundadores; devem cobrir pelo menos:
   - open source e sem fins lucrativos;
   - participação na Rede sem exigir o SO;
   - acesso comunitário básico sem cobrança por token;
   - nenhum financiador compra governança;
   - nenhuma decisão só por curiosidade técnica — deve servir liberdade, autonomia, eficiência ou descentralização.
3. **Nomenclatura** — tabela Projeto IA Livre / IA Livre / Rede IA Livre e uso correto dos nomes.
4. **Governança B + proteções** — descentralizada; associação brasileira sem fins lucrativos apenas como instrumento jurídico/administrativo (não como dona do projeto). Camadas de proteção: constituição/princípios imutáveis, comunidade, institucional, técnica, independência.
5. **Política open source** — código e protocolos abertos; licenças por componente. Preferência inicial registrada como **decisão a confirmar** (não lei): Apache 2.0 em infra; GPLv3 onde preservação de liberdades for prioridade.
6. **Sustentabilidade** — modelo sem fins lucrativos; financiamento sem compra de governança; acesso comunitário básico gratuito de token.

## Fora de escopo

- Código de produto, kernel, runtime, nó P2P
- Arquitetura técnica detalhada (`docs/architecture.md`) e ADRs de engenharia
- Conteúdo da Etapa 3 (product-context expandido / architecture) além de apontadores mínimos
- Estatuto jurídico formal da associação (só o papel dela no modelo B)
- Escolher licenças definitivas por repositório/componente (só política + preferência a confirmar)
- Tradução multilíngue completa (português basta nesta fatia)

## Critérios de aceite

- [x] Existe arquivo de manifesto em `docs/` (ex.: `docs/manifesto.md`) com as seções obrigatórias acima
- [x] Missão, princípios imutáveis, nomenclatura (três nomes), governança B com as cinco camadas de proteção, política open source e sustentabilidade estão explícitos
- [x] Preferência de licenças aparece como decisão a confirmar, não como regra fechada
- [x] Nomenclatura e lema batem com README / product-context (sem nomes novos)
- [x] README (seção Documentação) aponta para o manifesto sem copiar o texto longo
- [x] Gate de `AGENTS.md` continua passando (docs-only; sem regressão de scaffold)

## Riscos e rollback

- **Risco:** manifesto genérico demais ou inconsistente com product-context → alinhar frases-chave aos princípios já publicados; não inventar nomes.
- **Risco:** tratar associação como “dona” do projeto → reforçar no texto que é só instrumento jurídico/administrativo.
- **Risco:** cristalizar licenças cedo demais → manter “a confirmar”.
- **Rollback:** remover ou reverter o arquivo em `docs/` e o link no README; etapa permanece `em_andamento` até o Pronto quando.

## Etapa do roadmap

- Etapa 2 — Manifesto Fundador e identidade (`em_andamento`, Issue [#2](https://github.com/eriksonlima/projeto-ia-livre/issues/2))
- Pronto quando (roadmap): manifesto com missão, princípios imutáveis, nomenclatura (Projeto IA Livre / IA Livre / Rede IA Livre), governança B com proteções e política open source publicados em `docs/`.
