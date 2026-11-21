# Projeto IA Livre

Iniciativa brasileira, open source e sem fins lucrativos, para infraestrutura descentralizada de inteligência artificial.

| Nome | Papel |
|------|--------|
| **Projeto IA Livre** | Ecossistema, comunidade e governança |
| **IA Livre** | Sistema operacional próprio, com IA nativa |
| **Rede IA Livre** | Rede P2P — participação sem exigir o SO |

> Nascido no Brasil. Aberto ao mundo. Livre por princípio.

**Licença (1ª parte):** [Apache-2.0](LICENSE) — ver ADR [`docs/adr/0007-licencas-por-componente.md`](docs/adr/0007-licencas-por-componente.md). Terceiros: [`docs/licencas-terceiros.md`](docs/licencas-terceiros.md).

## Como rodar

Veja `AGENTS.md` → **Como rodar**.

## Como verificar

Veja `AGENTS.md` → **Como verificar**.

## Documentação

- Manifesto Fundador: `docs/manifesto.md`
- Roadmap: `ROADMAP.md` · Backlog: `BACKLOG.md`
- Specs: `specs/`
- Produto: `docs/product-context.md`
- Arquitetura: `docs/architecture.md` · Glossário: `docs/glossario.md`
- Harness A vs B: `docs/harness-linha-a-b.md` · comparável: `docs/harness-a-b-comparavel.md` (veja `AGENTS.md` → gates)
- Boot/imagem hardware real (ESP/USB): `docs/boot-hardware-real.md` — `make verify-baremetal` (artefato; ≠ QEMU)
- Rede (v1 + bootstrap): `docs/rede-ia-livre-v1.md` · `docs/rede-descoberta-wan.md`
- Autonomia (`calc`): `docs/autonomia-alem-v1.md`
- GPU host shard: `docs/shard-multi-gpu-host.md` — `make verify-gpu-shard-host`
- ADRs: `docs/adr/`
- Contrato nativo: `docs/runtime-contrato-nativo.md`
- Contexto ativo: `memory-bank/activeContext.md`
- Contribuição: `CONTRIBUTING.md`
