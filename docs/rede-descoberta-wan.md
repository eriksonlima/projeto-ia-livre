# Descoberta WAN mínima (Etapa 39)

Extensão da Rede IA Livre **além** do HELLO UDP LAN e do dial único `--peer`: lista de **bootstrap** verificável (simula WAN com endpoints estáticos) + **mDNS opt-in** (adiado no gate com skip honesto). **Sem** exigir o SO IA Livre.

Protocolo v1: [`rede-ia-livre-v1.md`](rede-ia-livre-v1.md).  
Desenho: [`desenho-protocolo-rede-ia-livre.md`](desenho-protocolo-rede-ia-livre.md).  
ADR: [`0004`](adr/0004-stack-protocolo-rede-ia-livre.md) (addendum: bootstrap = dial multiendereço).

## Modos

| Modo | Como | Marcador |
|------|------|----------|
| `lan` | HELLO UDP assinado (existente) | (implícito; sem `DISC_MODE` obrigatório) |
| `peer` | `--peer host:port` | `IA_LIVRE_DISC_MODE=peer` |
| `bootstrap` | `--bootstrap` / `--bootstrap-file` | `IA_LIVRE_DISC_MODE=bootstrap` + `IA_LIVRE_DISC_OK` |
| `mdns` | `--disc-mdns` (opt-in; gate com skip) | `IA_LIVRE_DISC_MODE=mdns` (quando implementado) |

### Precedência de dial

1. Se `--peer` estiver presente → dial **somente** peer (`DISC_MODE=peer`); bootstrap é ignorado para dial.
2. Senão, se houver endpoints bootstrap → dial sequencial (`DISC_MODE=bootstrap`).
3. Senão → só LAN (HELLO) + accept TCP.

Bootstrap fornece **endereço**, não identidade: autenticação continua **IDENT** ed25519 / PeerId.

## Flags

```
--bootstrap <host:port>     # repetível; também aceita lista separada por vírgula
--bootstrap-file <path>     # uma linha = host:port; # comentários; linhas vazias ignoradas
--disc-mdns                 # opt-in (ver skip abaixo)
```

Arquivo exemplo (gitignored via `build/`): `build/node-bootstrap.txt`.

## Marcadores

```
IA_LIVRE_DISC_MODE=bootstrap|peer|mdns
IA_LIVRE_DISC_OK            # dial bootstrap (ou mdns) concluiu sessão autenticável
```

Marcadores v1 (`PEER_OK`, `IDENT_OK`, `MSG_OK`, `PING_OK`) **permanecem**.

## Gate

`make verify-node`:

1. **Regressão peer** — B com `--peer` (E23).
2. **Bootstrap** — B **sem** `--peer`, com `--bootstrap 127.0.0.1:<tcp_A>`; exige `DISC_OK` + v1.

Timeout: `VERIFY_NODE_TIMEOUT` (default 45s por estágio).  
mDNS: `VERIFY_NODE_MDNS_SKIP=1` (default) — implementação mDNS adiada; skip honesto no gate.

## mDNS (opt-in / skip)

Flag `--disc-mdns` reserva o modo; implementação de anúncio `_ia-livre._tcp` **adiada**.  
Gate: `VERIFY_NODE_MDNS_SKIP=1` (default) imprime `IA_LIVRE_DISC_MDNS_SKIP=1` — **sem** fingir descoberta multicast.

## Futuro (só desenho)

| Peça | Nota |
|------|------|
| Relay | Hint futuro `RELAY_HINT v1 <host:port>` — **sem** código nesta etapa |
| DHT | Fora; ADR 0004 / libp2p rejeitados para o mínimo |
| NAT | STUN/TURN / hole-punch — fora |

Loopback **simula** WAN com endpoints estáticos; não prova internet pública.

## Como rodar

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
cargo build -p ia-livre-node

# A
cargo run -p ia-livre-node -- --tcp-port 7400 --node-id alice

# B via bootstrap (sem --peer)
cargo run -p ia-livre-node -- --tcp-port 7401 --node-id bob \
  --bootstrap 127.0.0.1:7400

make verify-node
```
