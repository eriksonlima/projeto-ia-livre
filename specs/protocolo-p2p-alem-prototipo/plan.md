# Plan — Protocolo P2P além do protótipo (stack / identidade)

## Abordagem

1. **ADR candidata** (Task 1): fixar em `docs/adr/0004-…` a decisão estrutural — protocolo Rede IA Livre v1 próprio (TCP+UDP, ed25519/PeerId, HELLO assinado + dial, framing além de MSG/ACK); libp2p e NAT/DHT adiados; fronteiras ADR 0001 e protótipo Etapa 6.
2. **Doc de desenho** (Task 2): expandir identidade, mensagens v1, descoberta, fronteira do próximo protótipo, alternativas rejeitadas/adiadas; sem código.
3. **Pontes e fechamento documental** (Task 3): atualizar `architecture.md` (decisão aberta → desenho candidato), ponte em `rede-ia-livre-prototipo.md`, `AGENTS.md` se couber, README avaliado.

Ordem: ADR → desenho detalhado → pontes (as pontes citam paths estáveis do ADR/doc).

## Arquivos prováveis

- `docs/adr/0004-stack-protocolo-rede-ia-livre.md` (nome final alinhado à Task 1)
- `docs/desenho-protocolo-rede-ia-livre.md`
- `docs/architecture.md` — decisão aberta da stack P2P → decidida no nível desenho
- `docs/rede-ia-livre-prototipo.md` — ponte honestidade (Etapa 6 vs desenho Etapa 14)
- `AGENTS.md` — ponte curta em Estrutura / docs (sem gate novo de código)
- `README.md` — só se a capa ficar enganosa sem menção ao desenho
- `specs/protocolo-p2p-alem-prototipo/tasks.md` — marcar fatias

## Dependências

- Etapas 1–13 feitas (ADR 0001, protótipo do nó, arquitetura).
- Sem QEMU, GGUF ou build de `node/` como pré-requisito do gate desta etapa.
- Não depende de marketplace, runtime nativo em B, nem autonomia v1.

## Verificação

Gate desta etapa = **checklist documental** (não `make verify-node` novo nem alteração de código):

```bash
test -f docs/adr/0004-stack-protocolo-rede-ia-livre.md   # ou nome fixado
test -f docs/desenho-protocolo-rede-ia-livre.md
grep -qiE 'ed25519|PeerId|IDENT|framing' docs/desenho-protocolo-rede-ia-livre.md
grep -qiE '0004|protocolo-rede|stack.*P2P|Rede IA Livre v1' docs/architecture.md
grep -qiE 'Etapa 14|desenho|v1' docs/rede-ia-livre-prototipo.md
# Sem diff de código de produto em node/ kernel/ runtime/ agent/ (salvo ponte doc)
```

Critério de pronto da etapa: ADR + doc de desenho coerentes com a proposta única; architecture e ponte do protótipo atualizados; sem marketplace / integração runtime-kernel / implementação completa.
