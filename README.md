# Projeto IA Livre

Iniciativa brasileira, open source e sem fins lucrativos, para infraestrutura descentralizada de inteligência artificial.

| Nome | Papel |
|------|--------|
| **Projeto IA Livre** | Ecossistema, comunidade e governança |
| **IA Livre** | SO **Linux IA-nativo** (TTY-first, LLM-first) |
| **Rede IA Livre** | Rede P2P — participação sem exigir o SO |

> Nascido no Brasil. Aberto ao mundo. Livre por princípio.

**Foco de produto:** SO Linux customizado para LLM (shell, configs, qualquer GGUF, Rede + agente) — ADR [`0027`](docs/adr/0027-produto-linux-ia-nativo.md). Linha B (UEFI freestanding) está **arquivada** como lab. Sem meta de `COMPROVA` (ADR [`0026`](docs/adr/0026-produto-sem-comprovacao-ab.md)).

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
- Linux IA-nativo (produto): ADR [`0027`](docs/adr/0027-produto-linux-ia-nativo.md) · `distro/` · USB: [`docs/guia-ia-livre-linux-usb.md`](docs/guia-ia-livre-linux-usb.md) · gates `verify-distro-*` / `verify-linux-usb-artifact`
- Harness / UEFI / bare-metal ESP (lab arquivado): `docs/harness-linha-a-b.md` · `docs/baremetal-report.md` · `docs/boot-hardware-real.md` — **≠** meta de produto
- Rede (v1 + TASK + bootstrap + mDNS + relay): `docs/rede-ia-livre-v1.md` · `docs/rede-descoberta-wan.md` — `make verify-node` / `verify-node-relay` · bridge: `make verify-rede-bridge` · TCP guest: `make verify-rede-guest` (ADR 0024)
- Autonomia (`calc` + REPL + read_local): `docs/autonomia-alem-v1.md` · `docs/autonomia-repl.md` · bridge host↔nativo: `docs/autonomia-bridge-nativo.md` / `make verify-autonomia-bridge`
- GPU host shard: `docs/shard-multi-gpu-host.md` — `make verify-gpu-shard-host` · GPU real (caminho nativo): `docs/gpu-real-nativo.md` / `make verify-gpu-native-real`
- ADRs: `docs/adr/`
- Contrato nativo: `docs/runtime-contrato-nativo.md`
- Contexto ativo: `memory-bank/activeContext.md`
- Contribuição: `CONTRIBUTING.md`
