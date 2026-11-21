# Spec — Nó Rede no SO nativo (pós-ExitBoot ou bridge)

Etapa 52 · Issue [#52](https://github.com/eriksonlima/projeto-ia-livre/issues/52) (ex-B46)  
Depende: E11 (pós-ExitBoot / UART COM1) · E49 (padrão bridge host↔nativo) · E51 (`TASK`/`TASK_ACK` no host — preferível, já feita).  
ADR 0001: [`docs/adr/0001-separacao-camadas-e-p2p.md`](../../docs/adr/0001-separacao-camadas-e-p2p.md).

---

## Resultado visível

Existe um caminho **verificável** em que a **Rede IA Livre** participa a partir do **caminho B** (evidência UEFI/QEMU pós-ExitBoot **ou** contrato bridge UEFI↔host), **sem** tornar o SO obrigatório para o nó host:

| Caminho | Condição | Esperado |
|---------|----------|----------|
| **A — TCP mínimo nativo** | Stack TCP (ou equivalente) no kernel/runtime-native pós-ExitBoot com sessão v1 mínima | Marcadores `IA_LIVRE_NET_NATIVE_*` no serial + gate QEMU |
| **B — Bridge UEFI↔host** | Host consome evidência nativa (serial/log pós-Exit) **e** exercita/ancora o nó host (`ia-livre-node`) com contrato explícito | Marcadores `IA_LIVRE_NET_BRIDGE_*` (ou namespace fixado) + gate; `verify-node` independente |
| **C — Só documentação** | A e B inviáveis após tentativa registrada | Doc de inviabilidade; **não** fecha o Pronto quando sozinho |

**Preferência obrigatória desta etapa:** **B** se A for inviável na fatia (estado atual: freestanding pós-Exit, UART COM1, **sem** NIC/driver/TCP).

---

## Contexto fixo (não reinventar)

- **ADR 0001:** participar da Rede **não exige** o SO IA Livre; `node/` no host `std` continua canônico e válido.
- **E6 / E23 / E39 / E50 / E51:** `ia-livre-node` — v1 (IDENT/MSG/PING/`TASK`), bootstrap, mDNS; gate `make verify-node`.
- **E11:** pós-ExitBoot — mapa preservado, UART COM1; **sem** `std`, **sem** stack de rede completa hoje.
- **E49 / ADR 0018:** bridge autonomia `IA_LIVRE_BRIDGE_*` — padrão análogo (consumidor host + evidência nativa + gate adicional).
- Kernel: **sem** TCP/socket/virtio-net implementados (grep atual vazio).
- Hipótese A vs B / comparable: **fora** desta etapa.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A — Stub TCP pós-ExitBoot** | Driver NIC + TCP mínimo + dial v1 no guest | **Improvável / rejeitada nesta fatia** — sem hardware de rede no runtime atual; custo de virtio-net + IP/TCP freestanding >> fatia; risco de stub teatral |
| **B — Bridge documentada UEFI↔host** | Contrato + consumidor host que prova vínculo com serial/log nativo (caminho B) e ancora participação via `ia-livre-node` (ou subprocesso documentado) | **Escolhida** — honesta, alinhada a E49, fecha Pronto quando |
| **C — Só docs** | Descrever fronteira sem gate | **Rejeitada como desfecho único** — Pronto quando exige marcadores + participação verificável |
| **D — Embutir `ia-livre-node` no kernel** | Portar crate `std` para UEFI | **Rejeitada** — quebra freestanding; contradiz ADR 0001 (SO como pedágio) |
| **E — Fingir rede nativa só com `verify-node`** | Declarar “nó no SO” sem evidência caminho B | **Rejeitada** — fraude de path |
| **F — libp2p / QUIC no guest** | Stack pesada | **Rejeitada** — ADR 0004 / AGENTS |

### Escolha: **B — bridge UEFI↔host (Rede)**

| Peça | Nesta etapa |
|------|-------------|
| Onde vive o nó TCP v1 | Continua no **host** (`ia-livre-node`) — **não** no kernel |
| O que é “participação a partir do caminho B” | Evidência nativa pós-Exit (serial QEMU / log capturado documentado) **validada** pela bridge **e** sessão Rede mínima no host (reusar prova E51: IDENT + preferível `TASK_OK`) amarrada por marcadores de bridge |
| Evidência nativa mínima | Marcadores pós-Exit já existentes (ex. `EXIT_BOOT_OK` / `MEM_SCHED_OK` / corrida Line B) — **não** exige TCP no guest |
| Marcadores (mínimo) | Namespace `IA_LIVRE_NET_BRIDGE_*` (fixados na Task 1), ex.: `NET_BRIDGE_MODE=host_uefi`, `NET_BRIDGE_NATIVE_SRC=…`, `NET_BRIDGE_OK` — **ou** `IA_LIVRE_NET_NATIVE_*` **somente** se A for reabilitada com evidência real |
| Gate | Novo `make verify-…` **adicional**; **não** substitui `make verify-node` |
| ADR | Novo ADR curto **se** a fronteira rede-bridge for estável (recomendado); senão contrato em `docs/` + ponte ADR 0001 / 0004 / 0018 |
| ADR 0001 | Intacta: host sem SO; bridge **não** torna QEMU obrigatório para `verify-node` |
| TCP nativo | Explicitamente **adiado** (backlog futuro); não fingir stub |

### Justificativa

- Fecha B46 com honestidade: caminho B observado + Rede exercitada no host, sem inventar NIC/TCP no freestanding.
- Reusa padrão E49 (bridge) e prova E51 (`TASK`) sem expandir protocolo.
- Preserva independência do nó host (ADR 0001).

### Rejeitado (explícito)

- Stub TCP/`NET_NATIVE_OK` sem stack real.
- Exigir SO/QEMU em `make verify-node`.
- Portar `node/` para o kernel nesta etapa.
- Marketplace / KNOW / libp2p.
- Confundir bridge de autonomia (`BRIDGE_*` E49) com bridge de rede (namespaces distintos).

---

## Conteúdo obrigatório

### 1. Documentação / contrato

- Novo contrato (sugestão): `docs/rede-bridge-nativo.md` — o que a bridge prova e o que **não** prova; relação com caminho B (E11+); marcadores; fluxo; ADR 0001.
- Pontes curtas em `docs/rede-ia-livre-v1.md` e/ou `docs/autonomia-bridge-nativo.md` (distinguir E49 vs E52).
- ADR novo **ou** addendum se a fronteira for estável.
- `AGENTS.md`: Como rodar / Como verificar o gate da bridge de rede.

### 2. Implementação mínima

- Consumidor host (script sob `scripts/` preferível; crate só se necessário) que:
  1. obtém evidência nativa (log serial QEMU / subprocesso documentado do repo — ex. harness B ou `verify-boot`);
  2. valida marcadores mínimos do caminho B;
  3. ancora participação Rede (subprocesso `ia-livre-node` em prova mínima documentada, preferindo ciclo com `TASK_OK` se barato; senão IDENT/`PEER_OK`/`PING_OK` com justificativa);
  4. emite `IA_LIVRE_NET_BRIDGE_*` + sucesso/falha honesta.
- **Não** exigir mDNS no gate default da bridge (E50 opt-in permanece).

### 3. Gate

- `make verify-…` (nome fixado na Task 1, ex. `verify-rede-bridge` / `verify-net-bridge`).
- Exige `NET_BRIDGE_OK` (ou equivalente) + evidência nativa válida + prova Rede host.
- Regressão: `make verify-node` permanece verde e **independente** do SO/QEMU.
- Gates kernel / autonomia-bridge / harness **não** regridem.

---

## Fora de escopo

- Stack TCP/IP completa, virtio-net, DHCP, NAT no guest.
- Nó P2P embutido no kernel / runtime-native.
- Alterar framing v1 além do já feito em E51.
- Marketplace, KNOW, libp2p, QUIC.
- Tornar `verify-node` dependente de QEMU.
- Reimplementar bridge de autonomia E49; confundir marcadores `BRIDGE_*` com `NET_BRIDGE_*`.
- Prefill/Decode / veredito harness; GPU nativa.
- Promover etapa a `feita` (agente principal após gate).

---

## Critérios de aceite

- [ ] Decisão A vs B vs C registrada; desfecho **B** (bridge), com A adiada explicitamente.
- [ ] Contrato UEFI↔host Rede em `docs/` com marcadores, fontes nativas e proibições (fraude host-as-native-TCP; SO obrigatório).
- [ ] Bridge verificável emite `IA_LIVRE_NET_BRIDGE_*` (ou namespace fixado), consome evidência caminho B e ancora participação via nó host.
- [ ] Gate automatizado adicional verde no host de referência; ADR 0001 preservada (`verify-node` sem SO).
- [ ] `AGENTS.md` atualizado; `README.md` avaliado (`readme-por-fatia`).
- [ ] Sem stub TCP teatral; sem libp2p; sem colisão de namespaces com E49.

---

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| Pressão por “TCP nativo” cosmético | Critério escrito: A rejeitada nesta fatia; sem `NET_NATIVE_OK` falso |
| Confundir E49 e E52 | Namespaces distintos (`NET_BRIDGE_*` vs `BRIDGE_*`); docs com tabela |
| Gate acopla `verify-node` a QEMU | Gate **novo**; regressão exige `verify-node` sem QEMU |
| Bridge só valida serial e ignora Rede | Contrato exige âncora `ia-livre-node` + marcador Rede |
| QEMU lento no CI | Reusar log fixture regenerável; timeout documentado |

Rollback: remover gate/scripts da bridge de rede; `node/`, E49 e gates existentes intactos.

---

## Etapa do roadmap

- Etapa 52 `em_andamento` — Nó Rede no SO nativo (pós-ExitBoot ou bridge)
- Pronto quando: stack TCP mínima no kernel/runtime-native **ou** bridge documentada UEFI↔host com marcadores; participação na Rede a partir do caminho B; ADR 0001 (host continua válido).
