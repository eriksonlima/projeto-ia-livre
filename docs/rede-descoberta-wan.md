# Descoberta WAN mínima (Etapas 39 / 50)

Extensão da Rede IA Livre **além** do HELLO UDP LAN e do dial único `--peer`: lista de **bootstrap** verificável (Etapa 39) + **mDNS real opt-in** (Etapa 50: anúncio/resolução `_ia-livre._tcp`). **Sem** exigir o SO IA Livre.

Protocolo v1: [`rede-ia-livre-v1.md`](rede-ia-livre-v1.md).  
Desenho: [`desenho-protocolo-rede-ia-livre.md`](desenho-protocolo-rede-ia-livre.md).  
ADR: [`0004`](adr/0004-stack-protocolo-rede-ia-livre.md) (addendum: bootstrap = dial multiendereço; mDNS = descoberta LAN).

## Modos

| Modo | Como | Marcador |
|------|------|----------|
| `lan` | HELLO UDP assinado (existente) | (implícito; sem `DISC_MODE` obrigatório) |
| `peer` | `--peer host:port` | `IA_LIVRE_DISC_MODE=peer` |
| `bootstrap` | `--bootstrap` / `--bootstrap-file` | `IA_LIVRE_DISC_MODE=bootstrap` + `IA_LIVRE_DISC_OK` |
| `mdns` | `--disc-mdns` (opt-in) | `IA_LIVRE_DISC_MODE=mdns` + `IA_LIVRE_DISC_OK` |
| `relay` | `--relay` + intro (Etapa 67) | `IA_LIVRE_DISC_MODE=relay` + `DISC_OK` + `RELAY_OK` |

### Precedência de dial

1. Se `--peer` estiver presente → dial **somente** peer (`DISC_MODE=peer`); bootstrap/relay/mDNS **não** disparam dial.
2. Senão, se houver endpoints bootstrap → dial sequencial (`DISC_MODE=bootstrap`).
3. Senão, se `--relay` → ASK intro + dial hint (`DISC_MODE=relay`).
4. Senão, se `--disc-mdns` → browse/resolve `_ia-livre._tcp` e dial (`DISC_MODE=mdns`).
5. Senão → só LAN (HELLO) + accept TCP.

Se `--disc-mdns` **coexiste** com bootstrap: bootstrap **vence o dial**; mDNS **ainda anuncia** o serviço local (útil para outros peers descobrirem este nó).

Bootstrap e mDNS fornecem **endereço**, não identidade: autenticação continua **IDENT** ed25519 / PeerId.

## Flags

```
--bootstrap <host:port>     # repetível; também aceita lista separada por vírgula
--bootstrap-file <path>     # uma linha = host:port; # comentários; linhas vazias ignoradas
--disc-mdns                 # anuncia + resolve _ia-livre._tcp (Etapa 50)
--relay-listen              # processo só intro relay (Etapa 67)
--relay-reg <host:port>     # registra 127.0.0.1:<tcp-port> no relay
--relay <host:port>         # ASK hint + dial (DISC_MODE=relay)
```

Arquivo exemplo (gitignored via `build/`): `build/node-bootstrap.txt`.

## Serviço mDNS (Etapa 50)

| Campo | Valor |
|-------|--------|
| Tipo | `_ia-livre._tcp` (domínio `.local` conforme crate) |
| Porta | TCP do nó (`--tcp-port`) |
| Instance | alias `--node-id` + porta (unicidade na LAN) |
| TXT | opcional / mínimo — **não** substitui IDENT |
| Crate | `mdns-sd` (leve; **sem** libp2p) |

Comportamento com `--disc-mdns`:

1. **Anúncio** — registra o serviço apontando para o TCP local.
2. **Resolução** — se não houver `--peer` nem bootstrap, browse peers; filtra self; dial TCP até sessão autenticável.
3. Sucesso → `IA_LIVRE_DISC_MODE=mdns` + `IA_LIVRE_DISC_OK` (+ marcadores v1).
4. Multicast indisponível / timeout → **sem** `DISC_OK` fingido; mensagem honesta.

## Marcadores

```
IA_LIVRE_DISC_MODE=bootstrap|peer|mdns|relay
IA_LIVRE_DISC_OK            # dial bootstrap/mdns/relay concluiu sessão autenticável
IA_LIVRE_RELAY_OK           # dial via RELAY_HINT (Etapa 67)
IA_LIVRE_DISC_MDNS_SKIP=…   # só no gate: estágio mDNS pulado (motivo)
```

Marcadores v1 (`PEER_OK`, `IDENT_OK`, `MSG_OK`, `PING_OK`) **permanecem**.

## Gate

`make verify-node`:

1. **Regressão peer** — B com `--peer` (E23).
2. **Bootstrap** — B **sem** `--peer`, com `--bootstrap 127.0.0.1:<tcp_A>`; exige `DISC_OK` + v1.
3. **mDNS (opt-in)** — A e B com `--disc-mdns`; B sem `--peer`/`--bootstrap`; exige `DISC_MODE=mdns` + `DISC_OK` **ou** skip honesto.

Timeout: `VERIFY_NODE_TIMEOUT` (default 45s por estágio).

| Variável | Default | Efeito |
|----------|---------|--------|
| `VERIFY_NODE_MDNS_SKIP` | `1` | CI: imprime `IA_LIVRE_DISC_MDNS_SKIP=…`, exit 0 no estágio mDNS |
| `VERIFY_NODE_MDNS_SKIP=0` | — | Exige prova mDNS (`DISC_MODE=mdns` + `DISC_OK`) |
| `VERIFY_NODE_MDNS_FORCE=1` | off | Com skip=0: se multicast falhar de forma detectável, **falha** o gate (não skip) |

## Relay intro (Etapa 67)

| Peça | Nota |
|------|------|
| Modelo | Introdução de endereço (`RELAY_REG` / `RELAY_ASK` / `RELAY_HINT v1`) — **não** forward de sessão |
| Gate | `make verify-node-relay` |
| DHT | **Adiado** (stub); Pronto quando fechado pelo relay |
| NAT real | STUN/TURN / hole-punch — **fora**; loopback ≠ internet pública |

## Futuro (só desenho)

| Peça | Nota |
|------|------|
| DHT | Kademlia / tabela — fora do mínimo; ADR 0004 |
| NAT | STUN/TURN / hole-punch — fora |
| Session relay | Forward de bytes (≠ intro) — fora |

Loopback **simula** WAN com endpoints estáticos (bootstrap/relay) e LAN local (mDNS); não prova internet pública.

## Como rodar

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
cargo build -p ia-livre-node

# A
cargo run -p ia-livre-node -- --tcp-port 7400 --node-id alice

# B via bootstrap (sem --peer)
cargo run -p ia-livre-node -- --tcp-port 7401 --node-id bob \
  --bootstrap 127.0.0.1:7400

# mDNS (dois terminais; sem --peer / sem --bootstrap no B)
cargo run -p ia-livre-node -- --tcp-port 7400 --node-id alice --disc-mdns
cargo run -p ia-livre-node -- --tcp-port 7401 --node-id bob --disc-mdns

make verify-node
# Prova mDNS (multicast ok):
# VERIFY_NODE_MDNS_SKIP=0 make verify-node

# Relay intro (Etapa 67):
# Terminal R: cargo run -p ia-livre-node -- --relay-listen --tcp-port 7399
# Terminal A: … --tcp-port 7400 --relay-reg 127.0.0.1:7399
# Terminal B: … --tcp-port 7401 --relay 127.0.0.1:7399
make verify-node-relay
```
