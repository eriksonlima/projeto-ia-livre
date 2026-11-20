# Manifesto Fundador — Projeto IA Livre

> Nascido no Brasil. Aberto ao mundo. Livre por princípio.

Este documento é a referência institucional do ecossistema. Em conflito com decisões ocasionais de marketing, roadmap ou conveniência técnica, prevalecem os princípios aqui registrados — inclusive contra alterações unilaterais dos fundadores.

## Missão

Grandes modelos de inteligência artificial concentram-se em infraestrutura proprietária e centralizada. Quem quer executar, aprender e colaborar localmente encontra sistemas genéricos e redes fechadas.

O **Projeto IA Livre** existe para construir uma infraestrutura aberta e descentralizada, de origem brasileira e aberta ao mundo, em que a inteligência artificial seja finalidade do sistema — não um aplicativo grudado nele.

Queremos que pessoas e comunidades possam executar, modificar, aprender, colaborar e evoluir com IA sem depender exclusivamente de empresas ou plataformas fechadas.

## Nomenclatura

| Nome | Papel |
|------|--------|
| **Projeto IA Livre** | Iniciativa brasileira, open source e sem fins lucrativos: ecossistema, comunidade e governança |
| **IA Livre** | Sistema operacional próprio, desenvolvido do zero, com IA como finalidade nativa |
| **Rede IA Livre** | Rede P2P que conecta participantes, recursos e conhecimento; participar **não** exige o SO |

Use estes nomes de forma consistente. Não invente marcas paralelas para o mesmo papel.

## Princípios imutáveis

Alterar estes princípios exige processo extraordinário da comunidade (quórum elevado, transparência, período de contestação). Não bastam a vontade de um administrador, financiador ou fundador.

1. **Open source e sem fins lucrativos** — o projeto é comunitário; não há distribuição de lucros.
2. **Participação sem exigir o SO** — a Rede IA Livre aceita nós em sistemas convencionais (Linux, Windows e outros compatíveis); o IA Livre é a implementação nativa de referência, não um pedágio de entrada.
3. **Acesso comunitário básico sem cobrança por token** — ninguém deve precisar pagar por token para o acesso básico à inteligência compartilhada pela comunidade. Limites técnicos justos podem existir para preservar disponibilidade; o acesso básico não vira produto comercial.
4. **Financiamento sem compra de governança** — doações, patrocínios e créditos de infraestrutura são bem-vindos; nenhum financiador adquire privilégios de governança, modelos, resultados ou acesso exclusivo em troca de recursos.
5. **Propósito técnico** — nenhuma decisão será tomada apenas porque é tecnologicamente interessante. Deve contribuir para liberdade, autonomia, eficiência ou descentralização.
6. **Resistência à captura** — o projeto não deve depender da boa vontade permanente de seus administradores para continuar livre. Proteções institucionais e técnicas devem dificultar a captura por indivíduos, grupos, empresas ou Estados.

## Governança (alternativa B)

A governança é **descentralizada e comunitária**. Os participantes decidem coletivamente os rumos técnicos e institucionais.

Uma **associação brasileira sem fins lucrativos** poderá existir como instrumento jurídico e administrativo (domínios, contratos, doações, obrigações legais). Ela **não é dona** do projeto, dos princípios nem da comunidade.

### Proteções em camadas

1. **Constituição** — este manifesto e os princípios imutáveis; mudança só por processo extraordinário.
2. **Comunidade** — decisões coletivas, transparência, participação aberta; ninguém com poder absoluto.
3. **Institucional** — associação como braço administrativo, sem propriedade sobre a missão.
4. **Técnica** — regras no software quando aplicável: auditoria, atualizações não silenciosas, controle do participante sobre os recursos que disponibiliza.
5. **Independência** — código, documentação e capacidade de continuidade distribuídos de modo que nenhuma entidade isolada possa desligar ou sequestrar o projeto.

Nenhum mecanismo impede absolutamente toda captura. O objetivo é barreiras sobrepostas, transparência e continuidade independente.

## Política open source

- Código-fonte do SO, runtime, agentes, ferramentas e clientes de nó: públicos e licenciados de forma open source.
- Protocolos da Rede IA Livre: especificação pública e aberta.
- Modelos, pesos e dados: licenças e origens documentadas com transparência; código aberto não implica automaticamente pesos abertos.
- Resultados de pesquisa: publicação aberta sempre que possível, respeitando direitos de terceiros.

**Licenças de 1ª parte (confirmadas — Etapa 17):** Apache License 2.0 (`Apache-2.0`) para `kernel`, `runtime`, `node`, `agent` e documentação do repositório — ver [`LICENSE`](../LICENSE), ADR [`0007`](adr/0007-licencas-por-componente.md). Dependências de terceiros mantêm licenças próprias ([`licencas-terceiros.md`](licencas-terceiros.md)). GPLv3 não foi aplicada a esses componentes nesta decisão; mudança futura exige nova ADR. Isto **não** é parecer jurídico.

## Sustentabilidade

O projeto busca sustentabilidade sem vender o acesso básico à inteligência comunitária.

Fontes possíveis, sem compra de governança:

- contribuições e doações voluntárias;
- financiamento científico e editais;
- patrocínio institucional transparente;
- créditos de infraestrutura (servidores, armazenamento, conectividade);
- contribuição comunitária (hardware, desenvolvimento, documentação, testes).

A capacidade da Rede IA Livre é finita. O acesso gratuito é sustentado pelo que a comunidade disponibiliza — não por promessa de processamento ilimitado.

No início, a sustentabilidade mais crítica é humana: uma comunidade que contribua e não deixe o desenvolvimento depender de uma única pessoa.

## Relação com a documentação

| Documento | Papel |
|-----------|--------|
| Este manifesto | Identidade, missão, princípios e governança |
| `docs/product-context.md` | Problema, usuários e não objetivos de produto |
| `docs/architecture.md` | Visão técnica (evolui com ADRs) |
| `ROADMAP.md` | Etapas e status de entrega |
| `README.md` | Porta de entrada do repositório |

Arquitetura e código seguem o roadmap; não substituem este manifesto.
