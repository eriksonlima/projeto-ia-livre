# Projeto IA Livre

Iniciativa brasileira, open source e sem fins lucrativos, para infraestrutura descentralizada de inteligência artificial.

| Nome | Papel |
|------|--------|
| **Projeto IA Livre** | Ecossistema, comunidade e governança |
| **IA Livre** | Sistema operacional próprio (Linha B), com IA nativa |
| **Rede IA Livre** | Rede P2P — participação sem exigir o SO |

> Nascido no Brasil. Aberto ao mundo. Livre por princípio.

**Foco de produto:** evoluir o SO IA Livre (bare-metal / runtime nativo / report ESP) e o ecossistema verificável (Rede + autonomia no host). O checklist dos 3 pilares do protótipo está **cumprido**; a hipótese A vs B fica como lab histórico — **sem** meta de `COMPROVA` (ADR [`docs/adr/0026-produto-sem-comprovacao-ab.md`](docs/adr/0026-produto-sem-comprovacao-ab.md)).

**Licença (1ª parte):** [Apache-2.0](LICENSE) — ver ADR [`docs/adr/0007-licencas-por-componente.md`](docs/adr/0007-licencas-por-componente.md). Terceiros: [`docs/licencas-terceiros.md`](docs/licencas-terceiros.md).

## Como rodar

Veja `AGENTS.md` → **Como rodar**.

## Como verificar

Veja `AGENTS.md` → **Como verificar**.

## Documentação

- Manifesto Fundador: `docs/manifesto.md`
- Roadmap: `ROADMAP.md` · Backlog: `BACKLOG.md`
- Specs: `specs/`
- Produto: `docs/product-context.md` · checklist protótipo (ok): [`docs/prototipo-objetivo-atingido.md`](docs/prototipo-objetivo-atingido.md) / `make verify-prototipo-objetivo`
- Arquitetura: `docs/architecture.md` · Glossário: `docs/glossario.md`
- Bare-metal report (canal padrão sem COM1): [`docs/baremetal-report.md`](docs/baremetal-report.md) · ADR 0025
- Harness A vs B (lab/histórico): `docs/harness-linha-a-b.md` · comparável: `docs/harness-a-b-comparavel.md` (veja `AGENTS.md`) — **≠** meta de produto
- Boot/imagem hardware real (ESP/USB): [`docs/guia-primeiro-boot-usb.md`](docs/guia-primeiro-boot-usb.md) · `docs/boot-hardware-real.md` — `make verify-baremetal` / `verify-write-usb` / `verify-boot-guide-release`; path metal SFS: `make verify-metal-infer` — [`docs/gguf-path-metal-io.md`](docs/gguf-path-metal-io.md)
- Rede (v1 + TASK + bootstrap + mDNS + relay): `docs/rede-ia-livre-v1.md` · `docs/rede-descoberta-wan.md` — `make verify-node` / `verify-node-relay` · bridge: `make verify-rede-bridge` · TCP guest: `make verify-rede-guest` (ADR 0024)
- Autonomia (`calc` + REPL + read_local): `docs/autonomia-alem-v1.md` · `docs/autonomia-repl.md` · bridge host↔nativo: `docs/autonomia-bridge-nativo.md` / `make verify-autonomia-bridge`
- GPU host shard: `docs/shard-multi-gpu-host.md` — `make verify-gpu-shard-host` · GPU real (caminho nativo): `docs/gpu-real-nativo.md` / `make verify-gpu-native-real`
- ADRs: `docs/adr/`
- Contrato nativo: `docs/runtime-contrato-nativo.md`
- Contexto ativo: `memory-bank/activeContext.md`
- Contribuição: `CONTRIBUTING.md`
