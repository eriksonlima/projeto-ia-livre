# Plan — Sincronizar architecture/product pós-E58

## Abordagem

Documentação only. Três fatias: (1) glossário + checklist de regressão, (2) architecture, (3) product-context + gate.

1. **Task 1 — Glossário + inventário** — Completar `docs/glossario.md` (REPL, `read_local`, mDNS, relay, KNOW, `host_multi`). Congelar checklist de inconsistências da spec (tabela lacunas) como guia da Task 2. **Não** reescrever architecture ainda.
2. **Task 2 — Architecture** — Atualizar `docs/architecture.md` in-place: decisões tomadas E42–E71, decisões abertas **reais**, mapa pós-E71, GPU/Rede/autonomia/hipótese honestos. Cruzar com Task 1.
3. **Task 3 — Product + gate** — Alinhar `docs/product-context.md`; estender `scripts/verify-docs-consistency.sh`; rodar `make verify-docs-consistency`; avaliar README (`readme-por-fatia`).

Ordem: 1 → 2 → 3. Tom: português, técnico-claro. Coerência: **AGENTS** = operação; **architecture** = visão; **product-context** = valor; **glossário** = vocabulário; **prototipo-objetivo** = checklist E58 (citar, não duplicar).

## Arquivos prováveis

- `docs/glossario.md` — âncoras faltantes
- `docs/architecture.md` — principal volume
- `docs/product-context.md` — estado de produto
- `scripts/verify-docs-consistency.sh` — greps pós-E58 / anti-regressão
- `Makefile` — só se o target precisar de nota (provável: intacto)
- `README.md` / `AGENTS.md` — **condicional** (`readme-por-fatia`)
- `specs/sync-architecture-product/tasks.md` — marcar tasks

**Não editar:** `docs/manifesto.md`, código de produto, `ROADMAP.md` (status fica com o agente principal), contratos satélite inteiros (ponte basta), B55.

## Dependências

- Etapas 42–71 `feita`; E72 `em_andamento`
- Contratos/ADRs já publicados (0020–0024, path metal, ABI, autonomia nativa, etc.)
- Spec E42 (`sync-architecture-glossario`) como precedente de gate documental

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
make verify-docs-consistency
```

Checks específicos (além do script):

1. Checklist de aceite em `spec.md`
2. Greps anti-regressão: `architecture.md` sem `REPL`/`read_local` como abertos; sem mapa só `pós-E41` desatualizado; com `BLOQUEIO_FINAL` ou `0022`
3. Glossário: `grep -q` para REPL, `read_local`, mDNS, relay|RELAY, KNOW, `host_multi`
4. Sem menção falsa de `COMPROVA`/`METAL_OK` como atingidos
5. Registrar se README foi tocado ou não
