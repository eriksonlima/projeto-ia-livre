# ADR 0027 — Produto = Linux IA-nativo; Linha B arquivada

- Status: aceita
- Data: 2026-11-21

## Contexto

O checklist do protótipo foi cumprido (ADR [`0026`](0026-produto-sem-comprovacao-ab.md)). O pedido de produto pediu shell tipo Linux, configs livres, qualquer GGUF e Rede — o que o kernel UEFI freestanding (Linha B) não entrega em prazo razoável (sem TCP guest — ADR [`0024`](0024-tcp-rede-guest-inviavel.md); sem shell; inferência subset).

## Decisão

1. **Produto canônico:** **IA Livre Linux** — distribuição mínima **TTY-first** (bash), sem meta de desktop, com stack `ia-livre-runtime` / `ia-livre-agent` / `ia-livre-node`, configs em `/etc/ia-livre/`, modelos em path configurável.
2. **LLM o mais nativo possível:** userspace + tuning (hugepages, isolcpus, governor, cgroups) e, evolutivamente, **customização do kernel Linux** (defconfig/patches com ADR própria) — **não** guest UEFI.
3. **Linha B (UEFI freestanding / runtime-native guest / harness B / ESP bare-metal como uso):** **arquivada** como lab histórico. Sem etapas novas de produto. Código e gates podem permanecer no repo; **não** competem prioridade.
4. ADR [`0001`](0001-separacao-camadas-e-p2p.md) intacta: participar da Rede **não** exige este SO.
5. Sem meta `COMPROVA` A/B; harness B ≠ objetivo de produto.

## Consequências

- Roadmap/backlog priorizam imagem live, config/modelos, tuning, smoke QEMU, USB Linux.
- Narrativa em `product-context` / `architecture` / README aponta Linux IA-nativo.
- Linha B: referência histórica / gates opcionais de regressão, não “próximo passo”.
