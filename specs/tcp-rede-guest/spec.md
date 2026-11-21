# Spec — Stack TCP Rede nativa no guest

Etapa 66 · Issue [#66](https://github.com/eriksonlima/projeto-ia-livre/issues/66) (ex-B61)  
Depende: E11 (pós-ExitBoot / UART COM1) · E52 / ADR [`0019`](../../docs/adr/0019-rede-bridge-uefi-host.md) (bridge `NET_BRIDGE_*`; TCP guest **adiado**) · E23/E51 (`ia-livre-node` v1 + `TASK_OK`).  
ADR 0001: participar da Rede **não exige** o SO IA Livre.

---

## Resultado visível

Existe um desfecho **verificável** para “sessão Rede no caminho B” quanto a TCP **no guest** pós-ExitBoot:

| Caminho | Condição | Esperado |
|---------|----------|----------|
| **A — TCP mínimo realista** | virtio-net (ou NIC documentada) + stack freestanding + sessão v1 mínima no guest | Marcadores `IA_LIVRE_NET_NATIVE_*` + gate QEMU **sem** fingir |
| **B — Inviabilidade medida + bridge estendida** | A inviável com evidência (kernel sem NIC/driver/TCP); ADR nova (ex. `0024`) + marcador honesto de bloqueio guest + gate | `NET_GUEST_BLOCK=…` (ou equiv.) + bridge/`NET_BRIDGE_*` preservados; `verify-node` intacto |

A etapa fecha com **sessão Rede amarrada ao caminho B** (marcadores) **e** `make verify-node` host **intacto** (ADR 0001). **Proibido** `NET_NATIVE_OK` sem stack; **proibido** exigir SO para Rede host.

---

## Contexto fixo (não reinventar)

- **E52 / ADR 0019:** bridge host↔UEFI (`IA_LIVRE_NET_BRIDGE_*`); TCP nativo pós-Exit **adiado** — freestanding com UART, sem NIC/TCP.
- **Estado medido (pré-especificação):** `kernel/` pós-Exit = UART COM1; **sem** virtio-net, socket, smoltcp ou driver NIC (grep vazio).
- **ADR 0001:** `node/` no host `std` continua canônico; `make verify-node` **não** depende de QEMU/SO.
- **E6 / E23 / E39 / E50 / E51:** protocolo v1 + bootstrap/mDNS/`TASK` no host.
- Hipótese A vs B / comparable / GPU guest: **fora**.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A — virtio-net + TCP freestanding + dial v1 no guest** | Driver + IP/TCP + sessão Rede nativa pós-Exit | **Improvável / rejeitada nesta etapa como desfecho completo** — custo >> fatia; sem base NIC no kernel atual; risco alto de stub teatral |
| **B — ADR inviabilidade + marcadores honestos + gate** | Documentar tentativa/medição (sem NIC); ADR `0024` (TCP guest ainda inviável); estender contrato bridge **ou** emitir `NET_GUEST_BLOCK=no_tcp_post_exit` (fixado na Task 1); gate `verify-rede-guest` **ou** estágio em `verify-rede-bridge` | **Escolhida** — fecha Pronto quando com honestidade; preserva ADR 0001/0019 |
| **C — Emitir `NET_NATIVE_OK` / TCP cosmético** | “Sucesso” serial sem stack | **Rejeitada** — fraude |
| **D — Portar `ia-livre-node` / libp2p ao kernel** | `std` / stack pesada no freestanding | **Rejeitada** — ADR 0001 / 0004 / AGENTS |
| **E — Só docs sem marcadores/gate** | Texto sem verificação | **Rejeitada** — Pronto quando exige marcadores + sessão caminho B |
| **F — Acoplar `verify-node` a QEMU/SO** | Rede host passa a exigir guest | **Rejeitada** — ADR 0001 |

### Escolha: **B — inviabilidade medida + bridge/marcadores honestos**

| Peça | Nesta etapa |
|------|-------------|
| Tentativa A | Registro medido: inventário (UART-only; ausência NIC/driver/TCP) + por que virtio-net+stack não cabe na fatia; **sem** implementar driver completo |
| ADR | Nova ADR curta (próximo número livre: **`0024`**) — TCP guest pós-Exit **ainda inviável** no kernel atual; ponte ADR 0019 (adiamento → inviabilidade documentada nesta etapa); critérios de reabertura |
| Contrato | Estender [`docs/rede-bridge-nativo.md`](../../docs/rede-bridge-nativo.md) **e/ou** doc dedicado `docs/rede-tcp-guest.md` (Task 1 fixa): o que B prova; o que **não** prova; marcador de bloqueio |
| Marcadores | Preservar `IA_LIVRE_NET_BRIDGE_*`; adicionar bloqueio guest estável, ex. `IA_LIVRE_NET_GUEST_BLOCK=no_tcp_post_exit` (nome exacto na Task 1). **Não** emitir `NET_NATIVE_OK` |
| Sessão Rede caminho B | Continua via bridge: evidência pós-Exit + âncora host (`TASK_OK` / prova E52) |
| Gate | Novo `make verify-rede-guest` **ou** estágio aditivo em `make verify-rede-bridge` — Task 1 decide; **não** substitui `verify-node` |
| ADR 0001 | Intacta: host sem SO; regressão `verify-node` sem QEMU |

### Justificativa

- Fecha ex-B61 / E66 sem fingir TCP: A exigiria virtio-net + IP/TCP freestanding + framing v1 no guest — inviável na fatia com base atual (só UART).
- Aceita B com **tentativa/documentação medida** (inventário + ADR), alinhada a ADR 0020/0021/0023 (inviabilidade honesta).
- Mantém participação Rede no caminho B via bridge E52 e `verify-node` independente.

### Rejeitado (explícito)

- `NET_NATIVE_OK` / stub TCP sem stack.
- Exigir SO/QEMU em `make verify-node`.
- libp2p; DHT/WAN (B62); KNOW (B63).
- Portar `node/` ao kernel nesta etapa.
- Confundir `BRIDGE_*` (E49 autonomia) com `NET_BRIDGE_*` / `NET_GUEST_*`.

---

## Conteúdo obrigatório

### 1. Documentação / ADR

- ADR `0024` (título sugerido: TCP Rede no guest pós-Exit inviável no kernel atual): contexto E52/0019; evidência (sem NIC); decisão B; rejeições; reabertura (virtio-net + TCP mínimo + sessão v1 verificável).
- Contrato atualizado: ponte em `rede-bridge-nativo.md` e/ou `docs/rede-tcp-guest.md`.
- Pontes curtas: ADR 0019 (status do adiamento), `rede-ia-livre-v1.md` se necessário.
- `AGENTS.md`: Como verificar o gate E66.

### 2. Implementação mínima (marcadores / runner)

- Runner ou estágio que, no caminho B:
  1. valida evidência nativa pós-Exit (reusar fixture/bridge E52);
  2. emite bloqueio guest honesto (`NET_GUEST_BLOCK=…`);
  3. preserva âncora Rede host (`NET_BRIDGE_OK` / `TASK_OK`);
  4. **nunca** emite `NET_NATIVE_OK` sem stack.
- Sem driver NIC no kernel nesta etapa (exceto probe documental se barato e não teatral).

### 3. Gate

- Target fixado na Task 1 (`verify-rede-guest` ou extensão de `verify-rede-bridge`).
- Exige marcador de bloqueio (ou, se A for milagrosamente reabilitada com evidência real — fora do esperado — `NET_NATIVE_*` reais).
- Regressão: `make verify-rede-bridge` e `make verify-node` verdes; node **sem** QEMU.
- Anti-fraude: falha se `NET_NATIVE_OK` sem evidência de stack/NIC.

---

## Fora de escopo

- Implementar virtio-net / TCP/IP / DHCP completos no guest.
- libp2p; DHT/NAT/relay (B62); KNOW (B63); marketplace.
- Fingir TCP / `NET_NATIVE_OK`.
- Quebrar ou acoplar `verify-node` ao SO.
- Prefill/Decode / hipótese A vs B / GPU.
- Promover etapa a `feita` (agente principal após gate).

---

## Critérios de aceite

- [ ] Decisão A vs B registrada; desfecho **B** com tentativa/medição de A (sem NIC) documentada.
- [ ] ADR `0024` (ou número livre na implementação) aceita: TCP guest ainda inviável; critérios de reabertura.
- [ ] Marcadores honestos (`NET_GUEST_BLOCK=…` ou equiv. fixado) + sessão caminho B via bridge; **sem** `NET_NATIVE_OK` falso.
- [ ] Gate aditivo verde; `make verify-node` intacto (ADR 0001); `verify-rede-bridge` não regride.
- [ ] `AGENTS.md` atualizado; `README.md` avaliado (`readme-por-fatia`).
- [ ] Sem libp2p / DHT/WAN / KNOW nesta etapa.

---

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| Pressão por TCP cosmético | Critério escrito + anti-fraude no gate |
| Confundir “adiado” (0019) com “feito” | ADR 0024 fecha inviabilidade medida; ponte explícita |
| Gate acopla `verify-node` a QEMU | Gate **novo/aditivo**; regressão exige node sem SO |
| Confundir E49 / E52 / E66 | Namespaces `BRIDGE_*` ≠ `NET_BRIDGE_*` ≠ `NET_GUEST_*` |
| Escopo vazar para virtio completo | Fora de escopo; reabertura só com evidência |

Rollback: reverter ADR/docs/scripts do bloqueio guest; bridge E52 e `node/` intactos.

---

## Etapa do roadmap

Etapa 66 — Stack TCP Rede nativa no guest  
Issue: [#66](https://github.com/eriksonlima/projeto-ia-livre/issues/66) (ex-B61)  
Status roadmap: _(promover / `em_andamento` — agente principal)_  
Pronto quando: sessão Rede no caminho B + marcadores; `verify-node` host intacto (ADR 0001).  
Spec: `specs/tcp-rede-guest/`
