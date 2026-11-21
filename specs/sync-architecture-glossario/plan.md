# Plan — Sincronizar architecture/product + glossário pós-E30

## Abordagem

Documentação only. Três fatias verticais: (1) vocabulário e critérios de auditoria, (2) architecture canônico, (3) product + superfície README/AGENTS.

1. **Auditoria + glossário (Task 1)** — Ler `ROADMAP.md` desfechos E30–E41, contratos citados em `AGENTS.md`, e estado atual de `architecture.md` / `product-context.md`. Produzir checklist de inconsistências e `docs/glossario.md` com termos estáveis (Linha A/B, `B_BLOCK` atual, QEMU/metal, identidades GPU, skip). **Sem** editar architecture ainda (ou só stub de âncoras se glossário referenciar seções futuras).
2. **Architecture sync (Task 2)** — Atualizar `docs/architecture.md` in-place: decisões tomadas E23–E41, decisões abertas reais, estado harness/Linha B honesto, mapa de entregas substituindo fronteira Etapa 3, pontes para glossário e contratos. Cruzar com checklist da Task 1.
3. **Product + pontes (Task 3)** — `docs/product-context.md`, `README.md`, revisão condicional `AGENTS.md`; gate de consistência (grep + leitura humana) conforme spec.

Ordem: 1 → 2 → 3. Task 2 pode citar glossário; Task 3 fecha README e remove resíduos em product-context alinhados ao architecture revisado.

Tom: português, técnico-claro, manifesto intacto. Coerência: **AGENTS** = operação; **architecture** = visão; **product-context** = valor; **glossário** = vocabulário.

## Arquivos prováveis

- `docs/glossario.md` — **novo**
- `docs/architecture.md` — principal volume de edição
- `docs/product-context.md` — alinhamento produto/hipótese/entregas
- `README.md` — pontes curtas (avaliar necessidade)
- `AGENTS.md` — **somente** se inconsistência factual inevitável
- `specs/sync-architecture-glossario/tasks.md` — marcar tasks feitas ao fechar fatias

**Não editar (salvo pedido explícito fora desta spec):** `docs/manifesto.md`, código e scripts de gate, `ROADMAP.md` (exceto atualização de status da etapa em outra fatia), contratos satélite inteiros (ponte/link basta).

## Dependências

- Etapas 30–41 `feita` no `ROADMAP.md`
- Contratos e desfechos já publicados (paths em `AGENTS.md` → Estrutura)
- Manifesto e ADRs 0001–0013 existentes — citar, não duplicar decisões

## Verificação

Não há gate `make` novo. Usar:

1. Checklist de aceite em `spec.md`
2. **Greps de regressão textual** (falha se bater sem contexto «histórico»):
   - `architecture.md`: `Etapa 3` como etapa atual; `no_gguf_path` como bloqueio corrente; `no_gguf_forward` como bloqueio corrente; `sem implementação no node/` / `sem implementação no agent/` como estado presente
   - `product-context.md`: `Etapa 3 é **só documentação**` sem redação pós-sync
3. Presença de `docs/glossario.md` com âncoras mínimas (`Linha A`, `Linha B`, `B_BLOCK`, `QEMU`, `bare-metal`, `host_stub`, `host_shard_exec`)
4. `test -f docs/architecture.md && test -f docs/product-context.md && test -f docs/glossario.md`
5. Gate existente `AGENTS.md` → Como verificar (docs-only): comandos `test -f` do scaffold **inalterados**; se `AGENTS` foi tocado, revalidar sanity do trecho editado
6. Rule `readme-por-fatia`: registrar na Task 3 se README foi ou não atualizado e por quê