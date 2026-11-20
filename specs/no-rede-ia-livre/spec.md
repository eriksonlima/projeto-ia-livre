# Spec — Protótipo do nó Rede IA Livre

## Resultado visível

Existe um **cliente/nó da Rede IA Livre** no repositório que roda em **SO convencional** (host Linux de referência, `std`), **sem** exigir o kernel UEFI nem o runtime de inferência. Dois processos (no **mesmo host**, documentado como simulação de dois nós, ou em hosts distintos) fazem **descoberta mínima** e **troca de uma mensagem** com formato documentado. Como rodar e como verificar estão em `AGENTS.md` (gate **adicional** aos das Etapas 4 e 5). A entrega prova o caminho mínimo da **camada 4** (Rede IA Livre), alinhada ao ADR 0001 — protocolo P2P **independente** do SO.

## Contexto fixo (não reinventar)

- ADR 0001: protocolo P2P **independente** do kernel/SO; nós em SO convencional; participar da Rede **não** exige o IA Livre — [`docs/adr/0001-separacao-camadas-e-p2p.md`](../../docs/adr/0001-separacao-camadas-e-p2p.md).
- Arquitetura: camada 4 = Rede IA Livre (descoberta, identidade, tarefas, conhecimento, recursos); stack concreta do P2P ainda era decisão aberta — esta etapa **fecha só o mínimo** para o protótipo — [`docs/architecture.md`](../../docs/architecture.md).
- Product context: participação sem trocar de SO; entrega progressiva boot → inferência CPU → **nó P2P** — [`docs/product-context.md`](../../docs/product-context.md).
- Manifesto: princípio imutável “participação sem exigir o SO”; protocolos públicos e abertos — [`docs/manifesto.md`](../../docs/manifesto.md).
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Etapas 4–5 entregues e **não** são dependência de execução desta etapa (só coexistência no monorepo).

## Decisão de ambiente e stack (obrigatória nesta etapa)

**Ambiente:** protótipo no **host Linux** (`std`). **Não** embutido no kernel UEFI, **não** bootado em QEMU, **não** acoplado ao crate `runtime/`.

**Stack única escolhida:** crate Rust **`node/`** no workspace Cargo (membro host, target nativo), binário CLI `ia-livre-node` (nome do pacote alinhado ao padrão `ia-livre-*`).

**Transporte e descoberta (mínimo fixado nesta etapa):**

| Peça | Escolha |
|------|---------|
| Mensagens | TCP, framing simples (linha UTF-8 terminada em `\n` **ou** length-prefix u32 BE + payload UTF-8 — **uma** forma fixada na doc) |
| Descoberta | UDP em loopback/LAN: anúncio periódico `HELLO` com `(node_id, tcp_port)`; o segundo processo escuta e diala o TCP anunciado. Fallback documentado: `--peer host:port` sem UDP |
| Async | `tokio` (runtime multi-thread default) **ou** `std::net` síncrono + threads — preferir **tokio** se o host já aceitar a dep; se bloquear, `std` + threads com a mesma semântica |
| Identidade | `node_id` opaco curto (UUID v4 ou string aleatória de 8+ chars); **sem** criptografia de identidade nesta etapa |
| Payload de prova | Uma mensagem de texto fixa (ex.: `ping` / `ola-rede-ia-livre`) e eco ou ACK documentado |

Justificativa:

- Alinha ao restante do projeto (Rust no host) e ao ADR 0001 (P2P desenvolvível no Ubuntu antes do SO maduro).
- TCP + UDP announce é o caminho mais curto e auditável para “descoberta mínima + mensagem” sem libp2p/DHT.
- Dois processos no mesmo host bastam para o Pronto quando, desde que documentados como simulação de dois nós.

Alternativas **não** adotadas nesta etapa: libp2p completo, mDNS/zeroconf obrigatório, QUIC, WebRTC, DHT/Kademlia, Noise/TLS mútuo, marketplace, gRPC.

### Marcadores de saída (obrigatórios para o gate)

Emitir na stdout de forma grepável (pelo menos no processo que **recebe** a mensagem de prova, e preferencialmente em ambos):

1. `IA_LIVRE_PEER_OK` — peer descoberto ou conexão TCP estabelecida com o outro nó.
2. `IA_LIVRE_MSG_OK` — mensagem de prova recebida (e, se houver eco/ACK, após validação do conteúdo esperado).

Opcional útil: `IA_LIVRE_NODE_ID=…`, `IA_LIVRE_PEER_ADDR=…`.

## Conteúdo obrigatório

### 1. Crate `node/`

- Diretório canônico: `node/` (membro do workspace Cargo na raiz, target **host**, não `x86_64-unknown-uefi`).
- CLI documentada que sobe um nó (listen TCP + opcional anúncio UDP) e/ou diala um peer.
- Dois processos devem poder rodar em paralelo no mesmo host (portas distintas ou alocação automática documentada).
- Sem `#![no_std]`; sem dependência de `kernel/` ou `runtime/` no `Cargo.toml` do nó.

### 2. Protocolo mínimo documentado

- Documento curto em `docs/` (ex.: `docs/rede-ia-livre-prototipo.md`) descrevendo:
  - framing;
  - tipos/linhas mínimas (`HELLO` / `MSG` / `ACK` ou equivalente);
  - descoberta UDP (porta, payload, intervalo);
  - que **participar não exige o SO IA Livre**;
  - que dois processos no mesmo host = simulação de dois nós (e como repetir em dois hosts com `--peer`).
- Protocolo **público e aberto** (texto no repo), alinhado ao manifesto.

### 3. Build / run

- Comandos em `AGENTS.md` → **Como rodar** (pré-requisitos: Rust host; **sem** QEMU/OVMF/llama.cpp/libclang para o nó).
- Exemplo canônico: terminal A sobe nó A; terminal B sobe nó B (com descoberta ou `--peer`); mensagem de prova cruzada; marcadores na stdout.

### 4. Gate em `AGENTS.md`

- **Como verificar** da Etapa 6: comando(s) que constroem o nó, sobem **dois** processos (script preferível), confirmam `IA_LIVRE_PEER_OK` e `IA_LIVRE_MSG_OK`, exit 0.
- Gates das Etapas 4 (`make verify`) e 5 (`make verify-runtime`) **permanecem**; o gate do nó é **adicional**.
- Não exigir QEMU, GGUF nem modelo para o gate do nó.
- Preferir `scripts/verify-node.sh` e alvo `make verify-node` (timeout generoso, ex. 30–60s).

### 5. Prova de independência do SO

- Documentar explicitamente em `AGENTS.md` e na doc do protocolo: o nó roda só com Rust no host; **não** precisa do EFI/`IA_LIVRE_BOOT_OK` nem do runtime/`IA_LIVRE_INFER_OK` para participar da Rede neste protótipo.

## Fora de escopo

- DHT completo, roteamento multi-hop, NAT traversal, hole punching
- Criptografia avançada de identidade (PKI, Noise, mTLS, assinaturas de mensagem)
- Marketplace, leilão de recursos, cobrança, tokens
- Integração com `runtime/` (inferência remota) ou `kernel/` (UEFI)
- Ambiente de autonomia / agentes (camada 3)
- UI gráfica, dashboard, app mobile
- libp2p como stack obrigatória; QUIC/WebRTC
- Persistência de peer store, gossip, pub/sub
- Windows/macOS como alvo de CI nesta etapa (Linux host de referência basta; código portátil `std` é bem-vindo mas não gate)
- Alterar comportamento do kernel ou do runtime além de menções documentais / workspace members

## Critérios de aceite

- [x] Existe crate `node/` (Rust host) no workspace, independente de `kernel/` e `runtime/`
- [x] Dois processos no host (ou dois hosts) completam descoberta mínima **ou** dial explícito documentado e estabelecem sessão TCP
- [x] Troca de pelo menos uma mensagem de prova com formato documentado em `docs/`
- [x] Stdout contém `IA_LIVRE_PEER_OK` e `IA_LIVRE_MSG_OK` de forma verificável
- [x] `AGENTS.md` → **Como rodar** e **Como verificar** cobrem o nó (gate adicional); documentado que não exige o SO IA Livre
- [x] Nenhum DHT, crypto de identidade avançada, marketplace ou integração runtime/kernel como entrega desta etapa
- [x] Etapa 6 marcada `feita` no roadmap após gate + revisor-de-fatia

## Riscos e rollback

- **Risco:** UDP broadcast bloqueado no ambiente → fallback `--peer 127.0.0.1:<port>` obrigatório no gate; descoberta UDP permanece como caminho “feliz” documentado.
- **Risco:** corrida de portas entre processos no mesmo host → portas configuráveis via CLI (`--tcp-port`, `--udp-port`) com defaults documentados; script de verify usa portas fixas altas.
- **Risco:** escopo inchado (libp2p, crypto, DHT) → rejeitar; Pronto quando = descoberta mínima + uma mensagem entre dois processos.
- **Risco:** acoplar o nó ao runtime “porque já está no host” → rejeitar; crates separados, gates separados.
- **Rollback:** remover `node/`, script/alvo de verify do nó e trechos de `AGENTS.md`/`Cargo.toml` workspace/docs do protótipo; etapa continua `em_andamento`.

## Etapa do roadmap

- Etapa 6 — Protótipo do nó Rede IA Livre (`em_andamento`, Issue [#6](https://github.com/eriksonlima/projeto-ia-livre/issues/6))
- Spec: `specs/no-rede-ia-livre/`
- Pronto quando (roadmap): cliente/nó em SO convencional comunica-se entre dois hosts (ou processos) com descoberta mínima e troca de mensagem documentada; participação sem exigir o SO IA Livre.
