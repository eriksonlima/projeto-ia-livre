# Spec — mDNS real na Rede IA Livre (além do skip)

Etapa 50 · Issue [#50](https://github.com/eriksonlima/projeto-ia-livre/issues/50)  
Depende: Etapa 39 (bootstrap + `--disc-mdns` reservado; mDNS era skip honesto).

---

## Resultado visível

O crate `node/` (`ia-livre-node`) passa a **anunciar e resolver** o serviço mDNS **`_ia-livre._tcp`** na LAN quando `--disc-mdns` está ativo, sem exigir o SO IA Livre (ADR 0001):

1. **Anúncio** — nó com `--disc-mdns` registra o serviço apontando para o TCP local (`tcp-port`).
2. **Resolução** — peer com `--disc-mdns` (sem `--peer` obrigatório) descobre endpoint(s) na LAN e diala TCP até sessão autenticável (IDENT ed25519).
3. **Marcadores** — `IA_LIVRE_DISC_MODE=mdns` + `IA_LIVRE_DISC_OK` quando a descoberta mDNS conclui caminho até sessão (como bootstrap na E39).
4. **Gate opt-in** — estágio mDNS em `make verify-node` (dois nós na mesma máquina / loopback LAN se possível) **ou** skip honesto `IA_LIVRE_DISC_MDNS_SKIP` se multicast indisponível — **sem fingir**. Default do gate pode continuar skip em CI; prova forçável via `VERIFY_NODE_MDNS_SKIP=0` (e/ou `FORCE` documentado).

Participar da Rede **continua sem** kernel UEFI, QEMU, GGUF nem runtime. Bootstrap/`--peer`/HELLO LAN **permanecem**.

---

## Contexto fixo (não reinventar)

- Contrato E39: [`docs/rede-descoberta-wan.md`](../../docs/rede-descoberta-wan.md) — hoje `--disc-mdns` reservado; `VERIFY_NODE_MDNS_SKIP=1` default; `IA_LIVRE_DISC_MDNS_SKIP`.
- Protocolo v1: [`docs/rede-ia-livre-v1.md`](../../docs/rede-ia-livre-v1.md) — mDNS = opt-in/skip E39.
- Spec E39: `specs/rede-descoberta-wan/` — bootstrap feito; Task 3 deixou mDNS como skip.
- Nó: `node/` — sem libp2p (`AGENTS.md` exige `! grep -qi libp2p node/Cargo.toml`).
- Gate atual: `scripts/verify-node.sh` — peer + bootstrap; mDNS só imprime skip.
- Código atual: `main.rs` com `--disc-mdns` → `IA_LIVRE_DISC_MDNS=skip` (placeholder).
- ADR 0001 / 0004 — host `std`; stack leve; DHT/libp2p fora.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A** | Crate Rust leve mDNS (ex. `mdns-sd` / `mdns`) + `--disc-mdns` real | **Escolhida** — alinha ao doc E39 e ao Pronto quando |
| **B** | Manter só skip + doc | **Rejeitada** — Etapa 50 exige anúncio/resolução |
| **C** | libp2p / Iroh discovery | **Rejeitada** — AGENTS + ADR 0004 |
| **D** | DHT / marketplace / relay | **Rejeitada** — fora do Pronto quando |
| **E** | Exigir mDNS no gate CI default | **Rejeitada** — CI sem multicast é comum; skip honesto default OK |
| **F** | Substituir bootstrap por mDNS | **Rejeitada** — regressão E39 obrigatória |

### Escolha: **A — mDNS real opt-in + gate skip/force**

| Peça | Escolha nesta etapa |
|------|---------------------|
| Serviço | `_ia-livre._tcp` (nome alinhado a `rede-descoberta-wan.md`; domínio `.local` conforme crate) |
| Flag | `--disc-mdns` (já parseada) — ativa anúncio **e** resolução no mesmo processo |
| Precedência dial | `--peer` > bootstrap > **mdns** > LAN-only HELLO — documentar; se `--disc-mdns` + bootstrap, bootstrap vence dial (mdns ainda pode anunciar) **ou** regra única fixada na Task 1 (uma só) |
| Segurança | mDNS só fornece **endereço**; autenticação continua IDENT / PeerId |
| Dep | Crate leve; feature Cargo opcional ok; **proibido** libp2p |
| Anúncio | Instance name = alias/`node-id` ou PeerId curto documentado; TXT mínimo opcional (não substitui IDENT) |
| Resolução | Browse `_ia-livre._tcp`; filtrar self; dial TCP ao host:port resolvido |
| Marcadores sucesso | `IA_LIVRE_DISC_MODE=mdns` + `IA_LIVRE_DISC_OK` (+ v1: `IDENT_OK` / `PEER_OK` / …) |
| Skip honesto | Ambiente sem multicast / browse timeout → **não** emitir `DISC_OK` fingido; gate: `IA_LIVRE_DISC_MDNS_SKIP=…` |
| Gate default | `VERIFY_NODE_MDNS_SKIP=1` (CI); prova: `VERIFY_NODE_MDNS_SKIP=0` (+ `VERIFY_NODE_MDNS_FORCE=1` se útil para forçar falha vs skip) |
| Independência SO | Host Linux `std` apenas |

### Fluxo canônico (prova — gate opt-in)

```
A: --tcp-port 7400 --disc-mdns   (anuncia _ia-livre._tcp → :7400)
B: --tcp-port 7401 --disc-mdns   (sem --peer / sem --bootstrap)
  → browse/resolve A
  → IA_LIVRE_DISC_MODE=mdns
  → TCP dial → IDENT ↔ IDENT → PEER_OK / MSG_OK / PING_OK
  → IA_LIVRE_DISC_OK
```

Se multicast indisponível no host:

```
verify-node (MDNS_SKIP=1 ou detecção)
  → IA_LIVRE_DISC_MDNS_SKIP=<motivo>
  → exit 0 no estágio mDNS (sem DISC_OK fingido)
```

---

## Conteúdo obrigatório

### 1. Documentação

- Atualizar [`docs/rede-descoberta-wan.md`](../../docs/rede-descoberta-wan.md): mDNS **implementado** (não mais “adiado”); serviço, flags, precedência, marcadores, skip/force do gate.
- Ponte em [`docs/rede-ia-livre-v1.md`](../../docs/rede-ia-livre-v1.md) (mDNS = E50 real / opt-in).
- `AGENTS.md`: Como rodar / Como verificar do nó — estágio mDNS + como forçar prova (`VERIFY_NODE_MDNS_SKIP=0`).
- ADR: só se a fronteira mudar; preferir atualizar doc E39 (não exigir ADR nova só por crate).

### 2. Código em `node/`

- Substituir placeholder `IA_LIVRE_DISC_MDNS=skip` por anúncio + resolução reais sob `--disc-mdns`.
- Preferir módulo em `discovery.rs` (ou `mdns.rs`) integrado ao dial/sessão existente.
- Dep mDNS leve em `node/Cargo.toml`; **sem** libp2p.
- Falha/timeout de multicast: mensagem honesta; não travar peer/bootstrap.

### 3. Gate

- `scripts/verify-node.sh`: estágio **mdns** (A e B com `--disc-mdns`; B sem `--peer`/`--bootstrap`) quando `VERIFY_NODE_MDNS_SKIP≠1`.
- Default `VERIFY_NODE_MDNS_SKIP=1` → imprime `IA_LIVRE_DISC_MDNS_SKIP=…` e **não** exige `DISC_OK` mdns.
- Com skip=0: exige `DISC_MODE=mdns` + `DISC_OK` + marcadores v1; se multicast falhar de forma detectável, skip honesto (exit 0) **salvo** `VERIFY_NODE_MDNS_FORCE=1` (falha o gate).
- Regressão peer + bootstrap **permanecem**.
- `make verify-node` permanece o alvo.

---

## Fora de escopo

- libp2p, Iroh, QUIC obrigatório, DHT/Kademlia, marketplace
- NAT traversal, STUN/TURN, hole-punching, relay executável
- Exigir SO IA Livre / QEMU / GGUF / runtime / agent
- Quebrar framing v1 (IDENT/MSG/PING)
- Exigir dois hosts físicos distintos no gate (loopback/LAN mesma máquina OK)
- Substituir bootstrap ou HELLO UDP
- Marcar Etapa 50 `feita` nesta spec (agente principal após gate + revisor)

---

## Critérios de aceite

- [ ] `--disc-mdns` anuncia e resolve `_ia-livre._tcp` (nome documentado)
- [ ] Sucesso emite `IA_LIVRE_DISC_MODE=mdns` + `IA_LIVRE_DISC_OK` com sessão autenticável
- [ ] Autenticação continua IDENT; mDNS ≠ identidade
- [ ] Gate: estágio opt-in **ou** `IA_LIVRE_DISC_MDNS_SKIP` honesto; default CI = skip
- [ ] Documentado como forçar prova (`VERIFY_NODE_MDNS_SKIP=0` / FORCE)
- [ ] `docs/rede-descoberta-wan.md` + `AGENTS.md` atualizados; README avaliado
- [ ] `! grep -qi libp2p node/Cargo.toml`
- [ ] Regressão `make verify-node` (peer + bootstrap) verde com skip default

---

## Riscos e rollback

- **Risco:** multicast/firewall/CI sem mDNS → skip default + FORCE documentado.
- **Risco:** flaky browse no loopback → timeout generoso; filtrar self; sleeps mínimos no script.
- **Risco:** crate mDNS + tokio → preferir API async ou thread dedicada documentada; não bloquear accept TCP.
- **Risco:** colisão de instance names → documentar unicidade (alias + porta ou PeerId).
- **Rollback:** reverter anúncio/resolução ao placeholder skip; gate volta a só peer+bootstrap.

---

## Etapa do roadmap

- Etapa 50 — mDNS real na Rede IA Livre (além do skip) (`em_andamento`; Issue [#50](https://github.com/eriksonlima/projeto-ia-livre/issues/50))
- Spec: `specs/mdns-rede-ia-livre/`
- Pronto quando (roadmap): `--disc-mdns` anuncia/resolve `_ia-livre._tcp` em LAN com gate opt-in; skip honesto se multicast indisponível.
