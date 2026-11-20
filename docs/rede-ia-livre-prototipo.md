# Rede IA Livre — protótipo do nó (Etapa 6)

Protocolo **mínimo** da camada 4. Público e aberto.  
Participar da Rede IA Livre **não exige** instalar o SO **IA Livre** (ADR 0001 / manifesto).

Dois processos no **mesmo host** = simulação de dois nós. Em hosts distintos, use `--peer <ip>:<tcp-port>`.

## Independência

| Precisa | Não precisa |
|---------|-------------|
| Rust no host (`std`) | Kernel UEFI / QEMU / `IA_LIVRE_BOOT_OK` |
| Loopback ou LAN | Runtime de inferência / GGUF / `IA_LIVRE_INFER_OK` |

Crate: `node/` (`ia-livre-node`). Sem dependência de `kernel/` ou `runtime/`.

## Framing

- **TCP (sessão):** linhas UTF-8 terminadas em `\n` (uma mensagem = uma linha).
- **UDP (descoberta):** um datagrama UTF-8 = uma linha `HELLO` (sem framing adicional).

## Mensagens

| Tipo | Transporte | Formato | Função |
|------|------------|---------|--------|
| `HELLO` | UDP | `HELLO <node_id> <tcp_port>\n` | Anúncio periódico para descoberta |
| `MSG` | TCP | `MSG <texto>\n` | Mensagem de aplicação |
| `ACK` | TCP | `ACK <texto>\n` | Confirmação do receptor |

Mensagem de prova (gate): `MSG ola-rede-ia-livre` → receptor responde `ACK ola-rede-ia-livre` e emite `IA_LIVRE_MSG_OK` (preferencialmente ambos os processos).

## Defaults canônicos

| Item | Valor |
|------|-------|
| TCP nó A | `7400` |
| TCP nó B | `7401` |
| UDP discover | `7410` |
| Mensagem de prova | `ola-rede-ia-livre` |
| Timeout do gate | 45s (`VERIFY_NODE_TIMEOUT`) |

## Descoberta

1. Cada nó escuta TCP em `--tcp-port` (defaults: nó A `7400`, nó B `7401`).
2. Anuncia em UDP `--udp-port` (default `7410`) com `HELLO` a cada ~1 s (para `127.0.0.1` e broadcast).
3. Ao receber `HELLO` de outro `node_id`, diala o TCP anunciado.
4. **Fallback:** `--peer 127.0.0.1:7400` (sem UDP) — obrigatório se o ambiente bloquear broadcast; **preferido no gate**.

## Marcadores (stdout)

- `IA_LIVRE_PEER_OK` — sessão TCP com o peer estabelecida
- `IA_LIVRE_MSG_OK` — mensagem de prova recebida/validada (MSG ou ACK)
- Opcional: `IA_LIVRE_NODE_ID=…`, `IA_LIVRE_PEER_ADDR=…`

## Fora deste protótipo

DHT, crypto de identidade, NAT traversal, marketplace, libp2p, integração com runtime/kernel.

## Fluxo canônico (mesmo host)

```bash
# Terminal A
cargo run -p ia-livre-node -- --tcp-port 7400 --node-id alice

# Terminal B (fallback --peer; preferir no gate se UDP estiver bloqueado)
cargo run -p ia-livre-node -- --tcp-port 7401 --node-id bob --peer 127.0.0.1:7400
```

Stdout esperada (em ambos): `IA_LIVRE_PEER_OK`, `IA_LIVRE_PEER_ADDR=…`, e `IA_LIVRE_MSG_OK` após `MSG`/`ACK` da prova.

Exemplo de captura (ordem aproximada):

```
IA_LIVRE_NODE_ID=alice
tcp_port=7400
udp_port=7410
IA_LIVRE_PEER_OK
IA_LIVRE_PEER_ADDR=127.0.0.1:xxxxx
IA_LIVRE_MSG_OK
```

UDP: anúncio a cada ~1 s para `127.0.0.1:<udp-port>` e broadcast; socket com `SO_REUSEADDR`/`SO_REUSEPORT`. Sem `--peer`, os dois nós podem descobrir-se só via `HELLO`.

## Gate

```bash
make verify-node
# ou: ./scripts/verify-node.sh
```

Sobe alice (`7400`) + bob (`7401` com `--peer 127.0.0.1:7400`), confirma `IA_LIVRE_PEER_OK` e `IA_LIVRE_MSG_OK`, limpa os processos. Timeout: `VERIFY_NODE_TIMEOUT` (default 45s).

## Implementação

- Task 1: scaffold + este documento — feita
- Task 2: descoberta + sessão TCP + `IA_LIVRE_PEER_OK` — feita
- Task 3: `MSG`/`ACK` + `make verify-node` — feita
