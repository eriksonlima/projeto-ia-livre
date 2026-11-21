# Backlog

Fila de demandas **ainda não** comprometidas no roadmap. Ordem = prioridade (topo primeiro).

Fonte: ideias do usuário, lacunas de `docs/architecture.md` / `docs/product-context.md`, ou pedidos fora da etapa atual.
Este arquivo é **canônico**. Espelho GitHub é **best-effort** (label `backlog`); se `gh` falhar, o item permanece só aqui e a fatia não trava.
Promoção para `ROADMAP.md` é **autônoma** (topo das Abertas quando o roadmap esvazia / etapa fecha / “continuar”) — ver `.cursor/rules/backlog-do-projeto.mdc` / skill `atualizar-backlog`. Com agentes em paralelo: sync + claim check antes de promover (`.cursor/rules/agentes-em-paralelo.mdc`). Não inventar etapa fora deste arquivo.

## Abertas

> **Produto (ADR 0027):** **Linux IA-nativo** (TTY, shell, qualquer GGUF, tuning/kernel Linux). Linha B UEFI **arquivada**. Ordem = prioridade (topo primeiro). Fila até o **produto final** (métricas em `docs/product-context.md`).

### B83 — Unidades systemd opcionais
- Issue: [#89](https://github.com/eriksonlima/projeto-ia-livre/issues/89)
- Origem: plano backlog produto final / ADR 0027
- Pronto quando: units runtime/agent/node no overlay + docs enable/disable (default não força)
- Deps: B77

### B84 — Smoke Rede no SO
- Issue: [#90](https://github.com/eriksonlima/projeto-ia-livre/issues/90)
- Origem: plano backlog produto final / ADR 0027
- Pronto quando: `ia-livre node` na imagem/QEMU com net; gate/smoke; ≠ guest UEFI
- Deps: B78

### B85 — Smoke autonomia no SO
- Issue: [#91](https://github.com/eriksonlima/projeto-ia-livre/issues/91)
- Origem: plano backlog produto final / ADR 0027
- Pronto quando: agent one-shot/REPL na imagem; gate/smoke
- Deps: B78

### B86 — GPU opcional na imagem
- Issue: [#92](https://github.com/eriksonlima/projeto-ia-livre/issues/92)
- Origem: plano backlog produto final / ADR 0027
- Pronto quando: docs + pacotes/features; skip honesto sem GPU
- Deps: B77

### B87 — Tuning avançado na imagem
- Issue: [#93](https://github.com/eriksonlima/projeto-ia-livre/issues/93)
- Origem: plano backlog produto final / ADR 0027
- Pronto quando: isolcpus/cgroups/hugepages com evidência no guest (evolui E79)
- Deps: B77

### B88 — ADR + defconfig/patches kernel Linux IA-nativo
- Issue: [#94](https://github.com/eriksonlima/projeto-ia-livre/issues/94)
- Origem: plano backlog produto final / ADR 0027
- Pronto quando: ADR aceita + defconfig/patches mínimos documentados (após imagem bootável)
- Deps: B78

### B89 — Gate boot com kernel custom
- Issue: [#95](https://github.com/eriksonlima/projeto-ia-livre/issues/95)
- Origem: plano backlog produto final / ADR 0027
- Pronto quando: gate com boot custom **ou** inviável honesto documentado
- Deps: B88

### B90 — Guia usuário final
- Issue: [#96](https://github.com/eriksonlima/projeto-ia-livre/issues/96)
- Origem: plano backlog produto final / ADR 0027
- Pronto quando: guia QEMU + USB + primeira sessão; product-context alinhado
- Deps: B78, B81

### B91 — Checklist + gate verify-produto-linux
- Issue: [#97](https://github.com/eriksonlima/projeto-ia-livre/issues/97)
- Origem: plano backlog produto final / ADR 0027
- Pronto quando: checklist das 4 métricas + `make verify-produto-linux` (completo: B78+B81+B84+B85 mínimos)
- Deps: B78, B81, B84, B85, B90

## Promovidas / arquivadas

### B82 — Release packaging produto
- Issue: [#88](https://github.com/eriksonlima/projeto-ia-livre/issues/88)
- Origem: plano backlog produto final / ADR 0027
- Pronto quando: SHA256SUMS + artefato sem GGUF default + guia release
- Promovido para Etapa 87.
- Etapa: [Etapa 87 — Release packaging](ROADMAP.md)

### B81 — Writer USB grava imagem bootável
- Issue: [#87](https://github.com/eriksonlima/projeto-ia-livre/issues/87)
- Origem: plano backlog produto final / ADR 0027
- Pronto quando: writer grava ISO com confirm; gate artefato; ≠ ESP
- Promovido para Etapa 86.
- Etapa: [Etapa 86 — Writer USB ISO](ROADMAP.md)

### B80 — ISO híbrida / live USB bootável
- Issue: [#86](https://github.com/eriksonlima/projeto-ia-livre/issues/86)
- Origem: plano backlog produto final / ADR 0027
- Pronto quando: artefato bootável (live/híbrido); distinto do tarball E81
- Promovido para Etapa 85.
- Etapa: [Etapa 85 — ISO híbrida](ROADMAP.md)

### B79 — First-boot TTY
- Issue: [#85](https://github.com/eriksonlima/projeto-ia-livre/issues/85)
- Origem: plano backlog produto final / ADR 0027
- Pronto quando: MOTD/PATH/hints; fetch GGUF documentado; sem GGUF default
- Promovido para Etapa 84.
- Etapa: [Etapa 84 — First-boot TTY](ROADMAP.md)

### B78 — Gate smoke QEMU da imagem IA Livre
- Issue: [#84](https://github.com/eriksonlima/projeto-ia-livre/issues/84)
- Origem: plano backlog produto final / ADR 0027
- Pronto quando: smoke exige boot Debian (`DISTRO_QEMU_OK`) ou skip need_*
- Promovido para Etapa 83.
- Etapa: [Etapa 83 — smoke QEMU Debian](ROADMAP.md)

### B77 — Rootfs Debian mínimo bootável em QEMU
- Issue: [#83](https://github.com/eriksonlima/projeto-ia-livre/issues/83)
- Origem: plano backlog produto final / ADR 0027
- Pronto quando: boot QEMU até prompt/`ia-livre conf`; gate documentado; ≠ Alpine netboot skip
- Promovido para Etapa 82.
- Etapa: [Etapa 82 — Rootfs Debian QEMU](ROADMAP.md)

### B76 — USB Linux de uso (writer + guia)
- Issue: [#82](https://github.com/eriksonlima/projeto-ia-livre/issues/82)
- Origem: plano Linux IA-nativo
- Pronto quando: gravador/guia imagem Linux (≠ ESP freestanding)
- Promovido para Etapa 81.
- Etapa: [Etapa 81 — USB Linux](ROADMAP.md)

### B75 — Gate verify-distro-smoke (QEMU)
- Issue: [#81](https://github.com/eriksonlima/projeto-ia-livre/issues/81)
- Origem: plano Linux IA-nativo
- Pronto quando: smoke QEMU da imagem/rootfs; ≠ metal UEFI
- Promovido para Etapa 80.
- Etapa: [Etapa 80 — verify-distro-smoke](ROADMAP.md)

### B74 — Perfil nativo default (tuning A_otimizada)
- Issue: [#80](https://github.com/eriksonlima/projeto-ia-livre/issues/80)
- Origem: plano Linux IA-nativo
- Pronto quando: sysctl/isolcpus (ou equiv.) default documentado
- Promovido para Etapa 79.
- Etapa: [Etapa 79 — Perfil nativo](ROADMAP.md)

### B73 — Layout config/modelos (qualquer GGUF)
- Issue: [#79](https://github.com/eriksonlima/projeto-ia-livre/issues/79)
- Origem: plano Linux IA-nativo
- Pronto quando: `/etc/ia-livre` + models path; troca de GGUF documentada
- Promovido para Etapa 78.
- Etapa: [Etapa 78 — config/modelos](ROADMAP.md)

### B72 — Fundação Linux IA-nativo (ADR 0027 + scaffold distro)
- Issue: [#78](https://github.com/eriksonlima/projeto-ia-livre/issues/78)
- Origem: plano abandonar Linha B; SO utilizável shell Linux
- Pronto quando: ADR 0027 + docs; scaffold `distro/`; gate estrutura; B arquivada como produto
- Promovido para Etapa 77.
- Etapa: [Etapa 77 — Fundação Linux IA-nativo](ROADMAP.md)

### B71 — Script collect-baremetal-report.sh
- Issue: [#77](https://github.com/eriksonlima/projeto-ia-livre/issues/77)
- Origem: DX operador (mount IALIVRE → evidence)
- Pronto quando: script copia report (+ post); opcional `verify-baremetal SKIP=0`; doc no guia
- Deps: B69 preferível
- Promovido para Etapa 76.
- Etapa: [Etapa 76 — collect-baremetal-report](ROADMAP.md)

### B70 — Inferência mínima path metal no baremetal-report
- Issue: [#76](https://github.com/eriksonlima/projeto-ia-livre/issues/76)
- Origem: plano evolução Linha B
- Pronto quando: geração subset + `TOKENS_PER_S` medidos **no report** (honesto); **não** alimenta comparable/`COMPROVA`
- Deps: B69 preferível
- Promovido para Etapa 75.
- Etapa: [Etapa 75 — tokens no baremetal-report](ROADMAP.md)

### B69 — Persistência pós-ExitBoot no baremetal-report (BlockIO)
- Issue: [#75](https://github.com/eriksonlima/projeto-ia-livre/issues/75)
- Origem: plano evolução Linha B; E73 só pré-exit (SFS)
- Pronto quando: append pós-ExitBoot (`EXIT_*` / `MEM_SCHED` / métricas subset) via BlockIO/slot; formato V1+; sem UART obrigatório; sem `COMPROVA`
- Deps: E73 / ADR 0025
- Promovido para Etapa 74.
- Etapa: [Etapa 74 — baremetal-report pós-ExitBoot](ROADMAP.md)

### B55 — Re-corrida harness A/B quieta pós-espécie canônica
- Issue: [#61](https://github.com/eriksonlima/projeto-ia-livre/issues/61)
- Origem: instrumento E22/E28
- **Arquivada (2026-11-21)** — produto sem `COMPROVA` (ADR 0026); não “adiada aguardando reabertura”
- Nota: reabertura só com pedido explícito + critérios ADR 0022

### B68 — Canal padrão bare-metal: relatório na ESP (sem COM1)
- Issue: [#74](https://github.com/eriksonlima/projeto-ia-livre/issues/74)
- Origem: operador sem UART; canal ESP para evidências/métricas bare-metal
- Pronto quando: `\\IA_LIVRE\\baremetal-report.txt` pré-ExitBoot + METAL_OK via report; ADR canal padrão; serial secundário
- Deps: E30/E35/E62; SFS E63
- Promovido para Etapa 73.
- Etapa: [Etapa 73 — Baremetal report ESP](ROADMAP.md)


### B67 — Sincronizar architecture/product pós-E58
- Issue: [#72](https://github.com/eriksonlima/projeto-ia-livre/issues/72)
- Origem: `architecture.md` ainda lista REPL/GPU harness como abertos; mapa pós-E41 defasado
- Pronto quando: architecture + product-context + glossário refletem E42–E58 e decisões abertas reais
- Deps: E58
- Promovido para Etapa 72.
- Etapa: [Etapa 72 — Sync architecture/product](ROADMAP.md)


### B66 — ABI mínima estável kernel↔runtime-native
- Issue: [#71](https://github.com/eriksonlima/projeto-ia-livre/issues/71)
- Origem: ADR 0003 — ABI fora; glue/serial ad hoc na Linha B
- Pronto quando: contrato versionado documentado + consumidor nativo; sem puxar inferência pro kernel
- Deps: E19/E20; `runtime-native`
- Promovido para Etapa 71.
- Etapa: [Etapa 71 — ABI runtime-native](ROADMAP.md)


### B65 — Autonomia consumindo runtime/evidência nativa
- Issue: [#70](https://github.com/eriksonlima/projeto-ia-livre/issues/70)
- Origem: E49 bridge só valida log; sem loop usando nativo/metal
- Pronto quando: one-shot que consome fonte nativa **ou** contrato “bridge = máximo até X”; ADR 0001
- Deps: E49; B56/B57 preferíveis
- Promovido para Etapa 70.
- Etapa: [Etapa 70 — Autonomia nativa](ROADMAP.md)


### B64 — Multi-GPU completo além do shard host
- Issue: [#69](https://github.com/eriksonlima/projeto-ia-livre/issues/69)
- Origem: architecture — multi-GPU completo aberto; E41 = pipeline host/skip
- Pronto quando: placement/execução multi-device real com evidência; sem fingir
- Deps: E41; ADR 0006
- Promovido para Etapa 69; desfecho `host_multi` + skip `need_2_devices` neste host.
- Etapa: [Etapa 69 — Multi-GPU host](ROADMAP.md)

### B63 — Mensagem KNOW na Rede
- Issue: [#68](https://github.com/eriksonlima/projeto-ia-livre/issues/68)
- Origem: manifesto — conhecimento; E51 só `TASK`
- Pronto quando: `KNOW`(+ACK) + gate dois nós; sem marketplace; sem exigir SO
- Deps: E51
- Promovido para Etapa 68; desfecho `KNOW_OK` no verify-node.
- Etapa: [Etapa 68 — KNOW](ROADMAP.md)

### B62 — Descoberta WAN (NAT/DHT/relay)
- Issue: [#67](https://github.com/eriksonlima/projeto-ia-livre/issues/67)
- Origem: ADR 0004 — bootstrap/mDNS não cobrem WAN
- Pronto quando: DHT **ou** relay verificável + gate/skip; sem libp2p monólito sem ADR
- Deps: E39/E50
- Promovido para Etapa 67; desfecho relay intro + `verify-node-relay`.
- Etapa: [Etapa 67 — Descoberta WAN](ROADMAP.md)

### B61 — Stack TCP Rede nativa no guest
- Issue: [#66](https://github.com/eriksonlima/projeto-ia-livre/issues/66)
- Origem: E52 = bridge only; ADR 0019 adia TCP pós-Exit
- Pronto quando: sessão Rede no caminho B + marcadores; `verify-node` host intacto (ADR 0001)
- Deps: E11; E52
- Promovido para Etapa 66; desfecho ADR 0024 + `NET_GUEST_BLOCK`.
- Etapa: [Etapa 66 — TCP Rede guest](ROADMAP.md)

### B60 — GPU real no guest (PCI/pass-through)
- Issue: [#65](https://github.com/eriksonlima/projeto-ia-livre/issues/65)
- Origem: E55 = `SRC=host`; QEMU ainda `KIND=synthetic`
- Pronto quando: `GPU_REAL_SRC=pci_passthrough` (ou equiv.) + `GPU_REAL_OK` **ou** skip `need_gpu`; ≠ só enum host
- Deps: E38/E55
- Promovido para Etapa 65 (após E64); desfecho skip `need_vfio` neste host.
- Etapa: [Etapa 65 — GPU guest passthrough](ROADMAP.md)

### B59 — Accel GPU simétrica A/B no harness
- Issue: [#73](https://github.com/eriksonlima/projeto-ia-livre/issues/73)
- Origem: E56 — `INCONCLUSIVO` por assimetria A GPU vs B CPU
- Pronto quando: corrida mesmo perfil accel; skip sem GPU; **proibido** ACCEL fingido em B
- Deps: B54 (ou subset simétrico); E8/E56
- Promovido para Etapa 64 do roadmap (promoção autônoma após E63).
- Etapa: [Etapa 64 — Accel GPU simétrica A/B](ROADMAP.md)

### B57 — I/O GGUF no path metal (além de no_gguf_metal_io)
- Issue: [#63](https://github.com/eriksonlima/projeto-ia-livre/issues/63)
- Origem: E48/ADR 0017 — path metal ainda é bloqueio SFS
- Pronto quando: geração mínima ou loader full no PC/ESP + marcadores; sem `TOKENS` fingidos; ≠ BlockIO como metal
- Deps: E36; E48; B56 preferível
- Promovido para Etapa 63 do roadmap (promoção autônoma — “continuar”).
- Etapa: [Etapa 63 — I/O GGUF path metal](ROADMAP.md)

### B56 — Evidência METAL_OK em PC real
- Issue: [#62](https://github.com/eriksonlima/projeto-ia-livre/issues/62)
- Origem: pilar 2 — `docs/evidence/boot-metal/` só `STATUS-SKIP`
- Pronto quando: log real + `IA_LIVRE_BAREMETAL_SKIP=0` → `METAL_OK` (≥ `BOOT_OK`, sem QEMU/OVMF)
- Deps: E35/E46/E47/E57
- Promovido para Etapa 62 do roadmap (promoção autônoma após E61).
- Etapa: [Etapa 62 — METAL_OK](ROADMAP.md)

### B58 — Bloqueio final documentado da hipótese A/B
- Issue: [#64](https://github.com/eriksonlima/projeto-ia-livre/issues/64)
- Origem: alternativa E58 se espécie canônica continuar inviável após B53; reforçado por ADR 0020/0021
- Pronto quando: ADR/doc declara espécie **terminalmente** inviável (ou caminho reaberto); instrumento honesto; sem fingir `COMPROVA`; espelho checklist E58 pilar 1
- Deps: E59/E60; ADR 0020/0021; E58
- Promovido para Etapa 61 do roadmap (promoção autônoma após E60/ADR 0021).
- Etapa: [Etapa 61 — bloqueio final hipótese A/B](ROADMAP.md)

### B54 — Espécie canônica Linha B (22L × n_predict=32)
- Issue: [#60](https://github.com/eriksonlima/projeto-ia-livre/issues/60)
- Origem: pilar 1 E58 — `COMPROVA`/`REFUTA` só com espécie = A
- Pronto quando: `verify-harness-comparable` com B 22L×32 + veredito ∈ {COMPROVA,REFUTA,INCONCLUSIVO} **sem** reason de teto/subset
- Deps: B53 preferível; ADR 0014–0016
- Promovido para Etapa 60 do roadmap (promoção autônoma após E59).
- Etapa: [Etapa 60 — espécie canônica Linha B](ROADMAP.md)

### B53 — Otimizar runtime-native (SIMD/teto) para espécie canônica
- Issue: [#59](https://github.com/eriksonlima/projeto-ia-livre/issues/59)
- Origem: ADR 0016 — 22L×32 inviável no gate sem ganho de ordem de magnitude
- Pronto quando: medição documentada (passo N≥8 / n_predict≥8 ou 22L×32 no timeout) **ou** ADR nova pós-otimização com inviável evidenciado
- Deps: `runtime-native`; E44/E45
- Promovido para Etapa 59 do roadmap (promoção autônoma — “continuar”).
- Etapa: [Etapa 59 — otimizar runtime-native](ROADMAP.md)

### B52 — Definição verificável de “protótipo objetivo atingido”
- Issue: [#58](https://github.com/eriksonlima/projeto-ia-livre/issues/58)

- Origem: este pedido — fechar o que conta como meta
- Pronto quando: checklist em `docs/` (hipótese A/B decidível **ou** bloqueio honesto final; USB metal com boot+IA mínima; Rede+autonomia host verdes) + espelho no ROADMAP/Memory Bank; celebrar só com evidência
- Deps: B39 + B40 + B42 (mínimo sugerido)

- Promovido para Etapa 58 do roadmap (promoção + spec).
- Etapa: [Etapa 58 — protótipo objetivo atingido](ROADMAP.md)

### B51 — Guia “primeiro boot USB” + release de artefato
- Issue: [#57](https://github.com/eriksonlima/projeto-ia-livre/issues/57)

- Origem: onboarding comunitário / sustentabilidade humana do manifesto
- Pronto quando: guia passo a passo (Secure Boot, serial, o que esperar) + tag/release com ESP/tar/checksums; sem declarar hipótese comprovada
- Deps: B40; B41

- Promovido para Etapa 57 do roadmap (promoção + spec).
- Etapa: [Etapa 57 — guia primeiro boot USB + release](ROADMAP.md)

### B50 — Perfil harness GPU espelhado A/B (quando B gerar)
- Issue: [#56](https://github.com/eriksonlima/projeto-ia-livre/issues/56)

- Origem: E18 metodologia; prova hipótese com aceleração
- Pronto quando: corrida A/B com perfil GPU documentado e métricas honestas; skip se sem GPU; deps geração em B
- Deps: B39; E8/E18

- Promovido para Etapa 56 do roadmap (promoção autônoma após E55).
- Etapa: [Etapa 56 — harness GPU](ROADMAP.md)

### B49 — GPU real no caminho nativo (além de `synthetic`)
- Issue: [#55](https://github.com/eriksonlima/projeto-ia-livre/issues/55)

- Origem: E38 enum sintética no QEMU
- Pronto quando: detecção/placement com GPU real (PCI/pass-through ou host path documentado) **ou** skip `need_gpu` honesto; ≠ stub E25; sem fingir multi-GPU
- Deps: E38

- Promovido para Etapa 55 do roadmap (promoção autônoma após E54).
- Etapa: [Etapa 55 — GPU real nativo](ROADMAP.md)

### B48 — Tool `read_local` allowlisted
- Issue: [#54](https://github.com/eriksonlima/projeto-ia-livre/issues/54)

- Origem: E40 adioud FS
- Pronto quando: leitura só sob allowlist de paths; rejeição honesta fora; gate; sem write arbitrário
- Deps: E40

- Promovido para Etapa 54 do roadmap (promoção autônoma após E53).
- Etapa: [Etapa 54 — read_local](ROADMAP.md)

### B47 — REPL sandboxed no agente (host)
- Issue: [#53](https://github.com/eriksonlima/projeto-ia-livre/issues/53)

- Origem: E40 adioud REPL
- Pronto quando: `--repl` com allowlist; modo scripted para `verify-agent`; sem shell/HTTP
- Deps: E40

- Promovido para Etapa 53 do roadmap (promoção autônoma após E52).
- Etapa: [Etapa 53 — REPL sandboxed](ROADMAP.md)

### B46 — Nó Rede no SO nativo (pós-ExitBoot ou bridge)
- Issue: [#52](https://github.com/eriksonlima/projeto-ia-livre/issues/52)

- Origem: nó nativo de referência (hoje só host `std`)
- Pronto quando: stack TCP mínima no kernel/runtime-native **ou** bridge documentada UEFI↔host com marcadores; participação na Rede a partir do caminho B; ADR 0001 (host continua válido)
- Deps: E11; B45 preferível

- Promovido para Etapa 52 do roadmap (promoção autônoma após E51).
- Etapa: [Etapa 52 — Nó Rede no SO](ROADMAP.md)

### B45 — Tarefa/conhecimento mínimo na Rede (além de PING)
- Issue: [#51](https://github.com/eriksonlima/projeto-ia-livre/issues/51)

- Origem: manifesto — colaborar recursos/conhecimento
- Pronto quando: tipo de mensagem v1 (ex. `TASK`/`KNOW` ou equivalente) + ACK + gate de dois nós; sem marketplace; sem exigir SO
- Deps: E23

- Promovido para Etapa 51 do roadmap (promoção autônoma após E50).
- Etapa: [Etapa 51 — TASK na Rede](ROADMAP.md)

### B44 — mDNS real na Rede IA Livre (além do skip)
- Issue: [#50](https://github.com/eriksonlima/projeto-ia-livre/issues/50)

- Origem: E39 adiou mDNS (`VERIFY_NODE_MDNS_SKIP`)
- Pronto quando: `--disc-mdns` anuncia/resolve `_ia-livre._tcp` em LAN com gate opt-in; skip honesto se multicast indisponível
- Deps: E39

- Promovido para Etapa 50 do roadmap (promoção autônoma após E49).
- Etapa: [Etapa 50 — mDNS real](ROADMAP.md)

### B43 — Autonomia mínima no caminho nativo (ou bridge SO↔host documentada)
- Issue: [#49](https://github.com/eriksonlima/projeto-ia-livre/issues/49)

- Origem: camada 3 no ecossistema do SO, não só Linux host
- Pronto quando: agente one-shot (ou bridge verificável) consome runtime nativo/metal **ou** contrato explícito host↔nativo com gate; sem shell irrestrito; ADR 0001 preservada
- Deps: B38 ou runtime host + metal estável

- Promovido para Etapa 49 do roadmap (promoção autônoma após E48).
- Etapa: [Etapa 49 — Autonomia mínima no caminho nativo](ROADMAP.md)

### B42 — Inferência mínima no metal (GGUF ESP → geração ou bloqueio honesto)
- Issue: [#48](https://github.com/eriksonlima/projeto-ia-livre/issues/48)

- Origem: protótipo SO usável além de marcadores de boot
- Pronto quando: no PC (ou QEMU espelhando path metal), após boot USB/ESP com `model.gguf`, caminho nativo emite geração mínima **ou** `B_BLOCK`/`metal` honesto documentado; sem `TOKENS_PER_S` fingido
- Deps: B40 preferível; E36 FULL_GGUF; caminho B37/B38 se aplicável

- Promovido para Etapa 48 do roadmap (promoção autônoma após E47).
- Etapa: [Etapa 48 — Inferência mínima no metal](ROADMAP.md)

### B41 — One-shot gravar pendrive UEFI (script + doc contribuidores)
- Issue: [#47](https://github.com/eriksonlima/projeto-ia-livre/issues/47)

- Origem: “colocar SO no pendrive” — hoje manual/`dd`
- Pronto quando: script ou procedimento único (detecta device com confirmação, grava ESP/FAT ou `.img`) + README/AGENTS; **sem** gravar `/dev/sdX` sem confirmação explícita
- Deps: E30

- Promovido para Etapa 47 do roadmap (promoção autônoma após “continuar”).
- Etapa: [Etapa 47 — One-shot gravar pendrive UEFI](ROADMAP.md)

### B40 — Evidência de boot metal real (serial ≥ `BOOT_OK` em PC)
- Issue: [#46](https://github.com/eriksonlima/projeto-ia-livre/issues/46)

- Origem: USB/pendrive; E35 ficou SKIP neste host
- Pronto quando: log serial de PC real em `docs/evidence/boot-metal/` + `IA_LIVRE_BAREMETAL_METAL_OK` no gate; Secure Boot/checklist documentados
- Deps: E30/E35 artefato

- Promovido para Etapa 46 do roadmap (promoção autônoma após E45).
- Etapa: [Etapa 46 — Evidência de boot metal real](ROADMAP.md)

### B39 — Re-corrida harness A vs B com geração real (veredito limpo)
- Issue: [#45](https://github.com/eriksonlima/projeto-ia-livre/issues/45)

- Origem: Etapa 22 ainda INCONCLUSIVO com B parcial
- Pronto quando: `make verify-harness-comparable` com B gerando; veredito ∈ {COMPROVA, REFUTA, INCONCLUSIVO} **sem** reason de proxy/`no_gguf_full_prefill`; metodologia quieta preservada
- Deps: B38

- Promovido para Etapa 45 do roadmap (promoção autônoma após E44).
- Etapa: [Etapa 45 — Re-corrida harness A vs B com geração real (veredito limpo)](ROADMAP.md)

### B38 — Decode + sampling + `TOKENS_PER_S` canônico na Linha B
- Issue: [#44](https://github.com/eriksonlima/projeto-ia-livre/issues/44)

- Origem: hipótese de pesquisa / ADR 0013
- Pronto quando: geração canônica em B emite `TOKENS_PER_S` (e marcadores Decode/sampling) honestos; `B_BLOCK` removido ou substituído; gate harness B atualizado
- Deps: B37

- Promovido para Etapa 44 do roadmap (promoção autônoma após E43).
- Etapa: [Etapa 44 — Decode + sampling + TOKENS_PER_S canônico na Linha B](ROADMAP.md)

### B37 — Prefill completo 22L + KV cache viável na Linha B

- Promovido para Etapa 43 do roadmap (promoção autônoma — ordem sensata hipótese A/B).
- Issue: [#43](https://github.com/eriksonlima/projeto-ia-livre/issues/43)

### B35 — Sincronizar architecture/product + glossário pós-E30

- Promovido para Etapa 42 do roadmap (promoção autônoma após Etapa 41).
- Issue: [#41](https://github.com/eriksonlima/projeto-ia-livre/issues/41)

### B34 — Shard multi-GPU host executado (além do stub)

- Promovido para Etapa 41 do roadmap (promoção autônoma após Etapa 40).
- Issue: [#40](https://github.com/eriksonlima/projeto-ia-livre/issues/40)

### B33 — Autonomia além de v1 (REPL ou tool sandboxed)

- Promovido para Etapa 40 do roadmap (promoção autônoma após Etapa 39).
- Issue: [#39](https://github.com/eriksonlima/projeto-ia-livre/issues/39)

### B32 — Rede IA Livre além de v1 (descoberta WAN mínima)

- Promovido para Etapa 39 do roadmap (promoção autônoma após Etapa 38).
- Issue: [#38](https://github.com/eriksonlima/projeto-ia-livre/issues/38)

### B31 — GPU manager nativo (mecanismos kernel ↔ runtime)

- Promovido para Etapa 38 do roadmap (promoção autônoma após Etapa 37).
- Issue: [#37](https://github.com/eriksonlima/projeto-ia-livre/issues/37)

### B30 — Observabilidade mínima no SO (além de UART-only)

- Promovido para Etapa 37 do roadmap (promoção autônoma após Etapa 36).
- Issue: [#36](https://github.com/eriksonlima/projeto-ia-livre/issues/36)

### B29 — GGUF canônico completo em mídia bare-metal (+ path I/O)

- Promovido para Etapa 36 do roadmap (promoção autônoma após Etapa 35).
- Issue: [#35](https://github.com/eriksonlima/projeto-ia-livre/issues/35)

### B28 — Boot UEFI em hardware real (evidência serial)

- Promovido para Etapa 35 do roadmap (promoção autônoma após Etapa 34).
- Issue: [#34](https://github.com/eriksonlima/projeto-ia-livre/issues/34)

### B27 — Baseline Linha A otimizada (CPU) no gate comparável

- Promovido para Etapa 34 do roadmap (promoção autônoma após Etapa 33).
- Issue: [#33](https://github.com/eriksonlima/projeto-ia-livre/issues/33)

### B26 — Re-corrida harness A vs B com geração real em B

- Promovido para Etapa 33 do roadmap (promoção autônoma após Etapa 32).
- Issue: [#32](https://github.com/eriksonlima/projeto-ia-livre/issues/32)

### B36 — Geração canônica Prefill+Decode+sampling na Linha B (TOKENS_PER_S)

- Promovido para Etapa 32 do roadmap (promoção autônoma após Etapa 31).
- Issue: [#42](https://github.com/eriksonlima/projeto-ia-livre/issues/42)
- Etapa: [Etapa 32 — Geração canônica na Linha B](ROADMAP.md)

### B25 — Forward GGUF mínimo em runtime-native (TOKENS_PER_S na Linha B)

- Promovido para Etapa 31 do roadmap (promoção autônoma — “continuar”).
- Issue: [#31](https://github.com/eriksonlima/projeto-ia-livre/issues/31)
- Etapa: [Etapa 31 — Forward GGUF mínimo em runtime-native](ROADMAP.md)

### B24 — Boot/imagem IA Livre em hardware real (USB/ESP)

- Promovido para Etapa 30 do roadmap (promoção autônoma — “vamos seguir”).
- Issue: [#30](https://github.com/eriksonlima/projeto-ia-livre/issues/30)
- Etapa: [Etapa 30 — Boot/imagem IA Livre em hardware real](ROADMAP.md)

### B23 — Motor de inferência GGUF mínimo na Linha B

- Promovido para Etapa 29 do roadmap (promoção autônoma — plano caminho à frente).
- Issue: [#29](https://github.com/eriksonlima/projeto-ia-livre/issues/29)
- Etapa: [Etapa 29 — Motor de inferência GGUF mínimo na Linha B](ROADMAP.md)

### B22 — Re-corrida harness A vs B quieta (COMPROVA/REFUTA ou INCONCLUSIVO limpo)

- Promovido para Etapa 28 do roadmap (promoção autônoma após Etapa 27).
- Issue: [#28](https://github.com/eriksonlima/projeto-ia-livre/issues/28)
- Etapa: [Etapa 28 — Re-corrida harness A vs B quieta](ROADMAP.md)

### B21 — Inferência mínima / TOKENS_PER_S na Linha B (após loader)

- Promovido para Etapa 27 do roadmap (promoção autônoma após Etapa 26).
- Issue: [#27](https://github.com/eriksonlima/projeto-ia-livre/issues/27)
- Etapa: [Etapa 27 — Inferência mínima / TOKENS_PER_S na Linha B](ROADMAP.md)

### B20 — Loader GGUF nativo mínimo na Linha B (desbloquear no_gguf_path)

- Promovido para Etapa 26 do roadmap — **feita**.
- Issue: [#26](https://github.com/eriksonlima/projeto-ia-livre/issues/26)
- Etapa: [Etapa 26 — Loader GGUF nativo mínimo na Linha B](ROADMAP.md)

### B15 — Carga GGUF canônica na Linha B (mínimo honesto)

- Promovido para Etapa 21 do roadmap — **feita** (Tasks 1–4; bloqueio honesto `no_gguf_path`).
- Issue: [#21](https://github.com/eriksonlima/projeto-ia-livre/issues/21)
- Etapa: [Etapa 21 — Carga GGUF canônica na Linha B (mínimo honesto)](ROADMAP.md)

### B16 — Harness A vs B comparável (prova ou refutação da hipótese)

- Promovido para Etapa 22 do roadmap — **feita** (VERDICT=INCONCLUSIVO; B=proxy/no_gguf_path).
- Issue: [#22](https://github.com/eriksonlima/projeto-ia-livre/issues/22)
- Etapa: [Etapa 22 — Harness A vs B comparável (prova ou refutação da hipótese)](ROADMAP.md)

### B17 — Protocolo Rede IA Livre v1 (impl. em node/)

- Promovido para Etapa 23 do roadmap — **feita** (Tasks 1–3; IDENT/PING; `verify-node` estendido).
- Issue: [#23](https://github.com/eriksonlima/projeto-ia-livre/issues/23)
- Etapa: [Etapa 23 — Protocolo Rede IA Livre v1 (impl. em node/)](ROADMAP.md)

### B18 — Autonomia v1 utilizável (impl. em agent/)

- Promovido para Etapa 24 do roadmap — **feita** (Tasks 1–3; MEMORY_POLICY + ≥2 tools; `verify-agent` estendido).
- Issue: [#24](https://github.com/eriksonlima/projeto-ia-livre/issues/24)
- Etapa: [Etapa 24 — Autonomia v1 utilizável (impl. em agent/)](ROADMAP.md)

### B19 — GPU manager / multi-GPU (protótipo mínimo)

- Promovido para Etapa 25 do roadmap — **feita** (Tasks 1–3; stub host + `verify-gpu-manager`).
- Issue: [#25](https://github.com/eriksonlima/projeto-ia-livre/issues/25)
- Etapa: [Etapa 25 — GPU manager / multi-GPU (protótipo mínimo)](ROADMAP.md)

### B14 — Runtime falando o contrato nativo (além do proxy Linha B)

- Promovido para Etapa 20 do roadmap — **feita** (Tasks 1–4; harness B + shim host).
- Issue: [#20](https://github.com/eriksonlima/projeto-ia-livre/issues/20)
- Etapa: [Etapa 20 — Runtime falando o contrato nativo (além do proxy Linha B)](ROADMAP.md)

### B13 — Memória model-aware + scheduler por fases (impl. mínima)

- Promovido para Etapa 19 do roadmap (promoção autônoma após “continuar”; etapas 1–18 feitas).
- Issue: [#19](https://github.com/eriksonlima/projeto-ia-livre/issues/19)
- Etapa: [Etapa 19 — Memória model-aware + scheduler por fases (impl. mínima)](ROADMAP.md)

### B12 — Evolução do harness (Linha A otimizada / perfil GPU)

- Promovido para Etapa 18 do roadmap (promoção autônoma após Etapa 17).
- Issue: [#18](https://github.com/eriksonlima/projeto-ia-livre/issues/18)
- Etapa: [Etapa 18 — Evolução do harness (Linha A otimizada / perfil GPU)](ROADMAP.md)

### B11 — Licenças definitivas por componente

- Promovido para Etapa 17 do roadmap (promoção autônoma após Etapa 16).
- Issue: [#17](https://github.com/eriksonlima/projeto-ia-livre/issues/17)
- Etapa: [Etapa 17 — Licenças definitivas por componente](ROADMAP.md)

### B10 — GPU manager no kernel / multi-GPU (desenho)

- Promovido para Etapa 16 do roadmap (promoção autônoma após “continuar”).
- Issue: [#16](https://github.com/eriksonlima/projeto-ia-livre/issues/16)
- Etapa: [Etapa 16 — GPU manager no kernel / multi-GPU (desenho)](ROADMAP.md)

### B9 — Ambiente de autonomia além do protótipo (v1 utilizável)

- Promovido para Etapa 15 do roadmap (promoção autônoma após Etapa 14).
- Issue: [#15](https://github.com/eriksonlima/projeto-ia-livre/issues/15)
- Etapa: [Etapa 15 — Ambiente de autonomia além do protótipo (v1 utilizável)](ROADMAP.md)

### B8 — Protocolo P2P além do protótipo (stack / identidade)

- Promovido para Etapa 14 do roadmap (promoção autônoma).
- Issue: [#14](https://github.com/eriksonlima/projeto-ia-livre/issues/14)
- Etapa: [Etapa 14 — Protocolo P2P além do protótipo (stack / identidade)](ROADMAP.md)

### B6 — Lacunas de arquitetura (scheduler / memória model-aware)

- Promovido para Etapa 13 do roadmap com confirmação explícita.
- Issue: [#12](https://github.com/eriksonlima/projeto-ia-livre/issues/12)
- Etapa: [Etapa 13 — Lacunas de arquitetura (scheduler / memória model-aware)](ROADMAP.md)

### B5 — Runtime nativo / Linha B real (mínimo)

- Promovido para Etapa 12 do roadmap com confirmação explícita.
- Issue: [#11](https://github.com/eriksonlima/projeto-ia-livre/issues/11)
- Etapa: [Etapa 12 — Runtime nativo / Linha B real (mínimo)](ROADMAP.md)

### B7 — Kernel pós-Boot Services (ExitBootServices + base mínima)

- Promovido para Etapa 11 do roadmap com confirmação explícita.
- Issue: [#13](https://github.com/eriksonlima/projeto-ia-livre/issues/13)
- Etapa: [Etapa 11 — Kernel pós-Boot Services](ROADMAP.md)

### B4 — Kernel além do boot

- Promovido para Etapa 10 do roadmap com confirmação explícita.
- Issue: [#10](https://github.com/eriksonlima/projeto-ia-livre/issues/10)
- Etapa: [Etapa 10 — Kernel além do boot](ROADMAP.md)

### B3 — Harness da hipótese Linha A vs Linha B

- Promovido para Etapa 9 do roadmap com confirmação explícita.
- Issue: [#9](https://github.com/eriksonlima/projeto-ia-livre/issues/9)
- Etapa: [Etapa 9 — Harness da hipótese Linha A vs Linha B](ROADMAP.md)

### B2 — Aceleração além de CPU (GPU)

- Promovido para Etapa 8 do roadmap com confirmação explícita.
- Issue: [#8](https://github.com/eriksonlima/projeto-ia-livre/issues/8)
- Etapa: [Etapa 8 — Aceleração além de CPU (GPU)](ROADMAP.md)

### B1 — Ambiente de autonomia (camada 3)

- Promovido para Etapa 7 do roadmap com confirmação explícita.
- Issue: [#7](https://github.com/eriksonlima/projeto-ia-livre/issues/7)
- Etapa: [Etapa 7 — Ambiente de autonomia (camada 3)](ROADMAP.md)
