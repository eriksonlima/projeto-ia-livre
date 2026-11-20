# Plan — Protótipo do nó Rede IA Livre

## Abordagem

Três fatias verticais até o Pronto quando da Etapa 6. Ambiente fixo: **host Linux** + crate **`node/`** + **TCP (mensagem)** + **UDP announce ou `--peer` (descoberta mínima)** + protocolo documentado + gate adicional. **Não** alterar comportamento do kernel UEFI nem do runtime de inferência além de listar o membro no workspace.

### Task 1 — Scaffold do nó + protocolo mínimo documentado

1. Adicionar membro `node/` ao workspace Cargo (target host/`std`; **não** `x86_64-unknown-uefi`).
2. Pacote/binário `ia-livre-node` com CLI mínima: pelo menos `--tcp-port`, `--node-id` (opcional/auto), e esqueleto de listen **ou** print de “scaffold ok” + parse de flags.
3. Criar `docs/rede-ia-livre-prototipo.md` com framing, tipos de mensagem, portas default sugeridas, independência do SO, e nota de que dois processos no mesmo host = simulação de dois nós.
4. Atualizar `AGENTS.md`: layout `node/`, pré-requisitos (só Rust host), **Como rodar** parcial (`cargo build -p ia-livre-node`).
5. Garantir que `make verify` e `make verify-runtime` **não** são quebrados por esta fatia (não é obrigatório re-rodar o runtime se o ambiente não tiver modelo — não regredir o Makefile/workspace do kernel).

Critério parcial: `cargo build -p ia-livre-node` sucede; doc do protocolo existe; AGENTS menciona o nó e que não exige o SO.

### Task 2 — Descoberta mínima + sessão entre dois processos

1. Implementar listen TCP + anúncio UDP periódico `HELLO` (payload com `node_id` + `tcp_port`) **e** dial via descoberta **ou** `--peer host:port`.
2. Ao conectar, emitir `IA_LIVRE_PEER_OK` (e opcionalmente `IA_LIVRE_PEER_ADDR=…`).
3. Documentar o fluxo canônico de dois terminais no mesmo host (portas default distintas ou script helper).
4. Atualizar **Como rodar** com o exemplo de dois processos até peer conectado.

Critério parcial: dois processos no host estabelecem conexão TCP (via UDP ou `--peer`) e o marcador `IA_LIVRE_PEER_OK` aparece.

### Task 3 — Troca de mensagem + gate + documentação final

1. Enviar mensagem de prova fixa após o peer OK; receptor valida e emite `IA_LIVRE_MSG_OK` (ACK/eco conforme a doc).
2. Script `scripts/verify-node.sh` (+ alvo `make verify-node`): sobe dois processos, espera os marcadores, mata processos, exit 0/≠0; timeout documentado (`VERIFY_NODE_TIMEOUT`).
3. Completar `AGENTS.md` → **Como verificar** (Etapa 6) e reforçar independência do SO / kernel / runtime.
4. Fechar detalhes em `docs/rede-ia-livre-prototipo.md` (exemplo de captura de stdout, defaults finais).
5. Não avançar roadmap para `feita` nesta task — marcação fica para o agente principal após gate + revisor.

### Defaults canônicos (orientação)

| Item | Valor sugerido |
|------|----------------|
| TCP nó A | `7400` |
| TCP nó B | `7401` (ou efêmero + só dial em A) |
| UDP discover | `7410` (mesmo socket compartilhado / broadcast 127.0.0.1 ou 255.255.255.255 documentado) |
| Mensagem de prova | `ola-rede-ia-livre` |
| Timeout do gate | 45s (override `VERIFY_NODE_TIMEOUT`) |

Ajustar se houver conflito de portas no host; documentar os valores finais em AGENTS + doc do protocolo.

### Notas de implementação (orientação, não código aqui)

- Workspace: `members = ["kernel", "runtime", "node"]`.
- Preferir dependências mínimas: `tokio` (+ `tokio::net`) **ou** só `std`; clap/`std::env::args` para CLI.
- Não puxar `llama-cpp-2`, `uefi`, nem crates do kernel.
- Script de verify: redirecionar logs para arquivos temporários sob `/tmp` ou `build/`, `grep -q` nos marcadores, `trap` para cleanup.
- Dois hosts reais: documentar como opcional (`--peer <ip>:<port>`); o gate automatizado pode ficar só no mesmo host.

## Arquivos prováveis

- `node/Cargo.toml`, `node/src/main.rs` (e módulos mínimos: `proto`, `discover`, `session`)
- `Cargo.toml` (workspace: adicionar `node`)
- `docs/rede-ia-livre-prototipo.md`
- `scripts/verify-node.sh`
- `Makefile` — alvo `verify-node`
- `AGENTS.md` — Como rodar / Como verificar / Estrutura / Stack (menção ao nó)
- `README.md` — menção curta opcional ao protótipo P2P

Não editar como entrega: comportamento de `kernel/src/**`, `runtime/src/**`, manifesto, ADR 0001 (salvo link), marketplace, crypto avançada.

Opcional mínimo: atualizar a tabela “Fronteira” / decisões abertas em `docs/architecture.md` refletindo o mínimo P2P escolhido — **não** é critério de aceite desta etapa (ADR novo só se a decisão for tratada como estrutural permanente além do protótipo; nesta etapa a doc do protocolo + AGENTS bastam).

## Dependências

- Etapas 1–5 feitas (scaffold, manifesto, architecture + ADR 0001, kernel, runtime CPU)
- Host: Rust estável (target host); rede loopback suficiente para o gate
- Sem dependência de QEMU, OVMF, GGUF, cmake/libclang para o nó
- Sem dependência do SO IA Livre para participar

## Verificação

1. Checklist de `spec.md` (critérios de aceite)
2. Gates anteriores não são substituídos: `make verify` (kernel) e `make verify-runtime` (quando modelo presente) permanecem válidos
3. Gate do nó em `AGENTS.md` → **Como verificar** (Etapa 6): `make verify-node` / `scripts/verify-node.sh`
4. Confirmar ausência de DHT/crypto avançada/marketplace/integração runtime-kernel na entrega
5. Após gate verde: agente principal chama `revisor-de-fatia`, atualiza ROADMAP/Memory Bank (fora do papel do especificador)
