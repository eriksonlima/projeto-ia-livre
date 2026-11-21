# Rede IA Livre — protocolo v1 (Etapa 23)

Implementação do desenho ADR 0004 no crate `node/` (`ia-livre-node`).  
Participar da Rede **não exige** o SO **IA Livre** (ADR 0001).

Protótipo histórico (Etapa 6): [`rede-ia-livre-prototipo.md`](rede-ia-livre-prototipo.md).  
Desenho: [`desenho-protocolo-rede-ia-livre.md`](desenho-protocolo-rede-ia-livre.md) · ADR [`0004`](adr/0004-stack-protocolo-rede-ia-livre.md).

## Independência

| Precisa | Não precisa |
|---------|-------------|
| Rust no host (`std`) | Kernel UEFI / QEMU |
| Loopback ou LAN | Runtime / GGUF / agente |

Sem libp2p, NAT, DHT, marketplace ou QUIC obrigatório nesta etapa.

## Identidade

1. Par **ed25519** (`ed25519-dalek`); seed de 32 bytes em arquivo (fora do git).
2. Default: `build/node-keys/<apelido>.key` (ou `--key-file`).
3. **`PeerId`** = hex lowercase da chave pública (32 bytes → 64 chars). Forma única e estável.
4. `--node-id` = **apelido** (UX) — **não** âncora de confiança.

## Framing

Linhas UTF-8 terminadas em `\n` (TCP e UDP).

### Mensagens v1

| Tipo | Transporte | Formato | Função |
|------|------------|---------|--------|
| `HELLO` | UDP | `HELLO v1 <peer_id> <tcp_port> <pubkey_hex> <sig_hex>` | Descoberta; assinatura cobre `HELLO\|v1\|<peer_id>\|<tcp_port>\|<pubkey_hex>` |
| `IDENT` | TCP | `IDENT v1 <peer_id> <pubkey_hex> <nonce_hex> <sig_hex>` | Handshake; canônico `IDENT\|v1\|<peer_id>\|<pubkey_hex>\|<nonce_hex>` |
| `MSG` / `ACK` | TCP | `MSG <texto>` / `ACK <texto>` | Aplicação (prova: `ola-rede-ia-livre`) |
| `PING` / `PONG` | TCP | `PING <nonce>` / `PONG <nonce>` | Liveness após IDENT |
| `TASK` / `TASK_ACK` | TCP | `TASK <task_id> <texto>` / `TASK_ACK <task_id>` | Pedido mínimo além de PING (Etapa 51; prova: `t1` / `prova-task-v1`) |

HELLO/IDENT inválidos (sig, PeerId≠pubkey, versão≠`v1`) são rejeitados. Dial por HELLO só após validação.  
`ACK` de MSG **não** confunde com `TASK_ACK`. `task_id` = token sem espaços. KNOW / marketplace **fora** desta versão.

### Fluxo canônico

```
UDP HELLO v1 (assinado)  →  valida PeerId/sig
TCP dial (--peer ou pós-HELLO)  →
IDENT ↔ IDENT (nonce)    →  IA_LIVRE_IDENT_OK + IA_LIVRE_PEER_OK
MSG / ACK (prova)        →  IA_LIVRE_MSG_OK
PING / PONG              →  IA_LIVRE_PING_OK
TASK / TASK_ACK          →  IA_LIVRE_TASK_OK
```

## Defaults

| Item | Valor |
|------|-------|
| TCP A / B | `7400` / `7401` |
| UDP | `7410` |
| Prova MSG | `ola-rede-ia-livre` |
| Prova TASK | `task_id=t1` · texto `prova-task-v1` |
| Timeout gate | 45s (`VERIFY_NODE_TIMEOUT`) |
| Protocolo | `v1` |

## Marcadores (stdout)

- `IA_LIVRE_PROTO=v1`
- `IA_LIVRE_PEER_ID=…` (local)
- `IA_LIVRE_NODE_ID=…` (apelido)
- `IA_LIVRE_IDENT_OK` + `IA_LIVRE_REMOTE_PEER_ID=…`
- `IA_LIVRE_PEER_OK` / `IA_LIVRE_PEER_ADDR=…` (após IDENT)
- `IA_LIVRE_MSG_OK`
- `IA_LIVRE_PING_OK`
- `IA_LIVRE_TASK_OK`

## Como rodar

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
cargo build -p ia-livre-node

# Terminal A
cargo run -p ia-livre-node -- --tcp-port 7400 --node-id alice

# Terminal B (regressão: --peer)
cargo run -p ia-livre-node -- --tcp-port 7401 --node-id bob --peer 127.0.0.1:7400

# Terminal B (Etapa 39: bootstrap, sem --peer)
cargo run -p ia-livre-node -- --tcp-port 7401 --node-id bob --bootstrap 127.0.0.1:7400
```

Descoberta além de LAN/`--peer`: [`rede-descoberta-wan.md`](rede-descoberta-wan.md).

## Gate

```bash
make verify-node
# ou: ./scripts/verify-node.sh
```

Exige regressão `--peer` **e** estágio bootstrap (`IA_LIVRE_DISC_OK` + marcadores v1).  
mDNS real (Etapa 50): opt-in no gate (`VERIFY_NODE_MDNS_SKIP=0`) ou skip honesto — ver [`rede-descoberta-wan.md`](rede-descoberta-wan.md).  
Timeout: `VERIFY_NODE_TIMEOUT` (default 45s **por estágio**).

## Fora deste v1 (núcleo framing)

DHT, relay executável, NAT traversal, marketplace, tipo `KNOW`, integração runtime/kernel, libp2p/Iroh, QUIC obrigatório.  
mDNS = serviço `_ia-livre._tcp` (Etapa 50; opt-in / skip CI); **não** substitui IDENT.  
`TASK` = pedido/ACK mínimo (Etapa 51); **não** é fila persistente nem matching multi-peer.
