# Plan — Definição verificável de “protótipo objetivo atingido” (Etapa 58)

## Abordagem

1. **Checklist (Task 1)** — Criar `docs/prototipo-objetivo-atingido.md` com: meta em uma frase; tabela/seções dos três pilares (critério atingido, evidência/comando, estado atual, não-conta); seção “celebrar só com evidência”; ponte para harness comparável, boot-hardware-real, rede/autonomia. Atualizar `docs/glossario.md` (entrada curta). Opcional: uma linha em `docs/product-context.md` apontando o checklist.

2. **Espelho (Task 2)** — Atualizar `ROADMAP.md` (desfecho/ponte quando fechar; durante: Spec já aponta); `memory-bank/activeContext.md` + `progress.md` com foco no checklist e residual (INCONCLUSIVO / METAL se skip). Avaliar README (`readme-por-fatia`).

3. **Gate opcional (Task 3)** — `scripts/verify-prototipo-objetivo.sh` + `make verify-prototipo-objetivo`: `test -f` do checklist; greps de pilares/marcadores-chave (ex. `INCONCLUSIVO`, `METAL_OK`, `verify-node`, `verify-agent`, frase de celebração-com-evidência); emite `IA_LIVRE_PROTOTIPO_OBJETIVO_OK` (nome ajustável). **Sem** corrida harness; **sem** exigir `COMPROVA`/`METAL_OK` no log. Documentar em AGENTS.md.

Sem tocar kernel/runtime/node/agent/harness de produto.

## Arquivos prováveis

- `docs/prototipo-objetivo-atingido.md` (novo)
- `docs/glossario.md` (entrada)
- `docs/product-context.md` (ponte curta, se couber)
- `scripts/verify-prototipo-objetivo.sh` (novo)
- `Makefile` (alvo)
- `AGENTS.md` (Como verificar)
- `README.md` (só se capa enganosa)
- `memory-bank/activeContext.md` / `progress.md`
- `ROADMAP.md` / `BACKLOG.md` (já na promoção)

Não editar: `kernel/`, `runtime/`, `node/`, `agent/`, scripts de harness comparable (salvo menção).

## Dependências

- Nenhuma dep de build/QEMU/GGUF/USB para o gate documental.
- Conteúdo factual: ler estados atuais de `harness-a-b-comparavel.md`, `boot-hardware-real.md`, gates node/agent.

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
test -f docs/prototipo-objetivo-atingido.md
grep -q 'INCONCLUSIVO' docs/prototipo-objetivo-atingido.md
make verify-prototipo-objetivo   # nome final na Task 3
# Não exige:
# make verify-harness-comparable / COMPROVA / USB
```

Critérios: checklist presente e honesto; espelho MB/ROADMAP; gate só documental; sem vitória indevida.
