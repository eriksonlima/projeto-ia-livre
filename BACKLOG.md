# Backlog

Fila de demandas **ainda não** comprometidas no roadmap. Ordem = prioridade (topo primeiro).

Fonte: ideias do usuário, lacunas de `docs/architecture.md` / `docs/product-context.md`, ou pedidos fora da etapa atual.
Este arquivo é **canônico**. Espelho GitHub é **best-effort** (label `backlog`); se `gh` falhar, o item permanece só aqui e a fatia não trava.
Promoção para `ROADMAP.md` é **autônoma** (topo das Abertas quando o roadmap esvazia / etapa fecha / “continuar”) — ver `.cursor/rules/backlog-do-projeto.mdc` / skill `atualizar-backlog`. Com agentes em paralelo: sync + claim check antes de promover (`.cursor/rules/agentes-em-paralelo.mdc`). Não inventar etapa fora deste arquivo.

## Abertas

> **Meta do protótipo (objetivo do projeto):** um ecossistema verificável em que (1) a **hipótese A vs B** possa ser comprovada ou refutada com geração real na Linha B (`TOKENS_PER_S`), (2) o **SO IA Livre** boote de USB/ESP em hardware real com caminho de IA nativo mínimo honesto, (3) a **Rede** e a **autonomia** continuem utilizáveis **sem** exigir o SO. Ordem abaixo = prioridade sugerida (topo primeiro).










### B52 — Definição verificável de “protótipo objetivo atingido”
- Issue: [#58](https://github.com/eriksonlima/projeto-ia-livre/issues/58)

- Origem: este pedido — fechar o que conta como meta
- Pronto quando: checklist em `docs/` (hipótese A/B decidível **ou** bloqueio honesto final; USB metal com boot+IA mínima; Rede+autonomia host verdes) + espelho no ROADMAP/Memory Bank; celebrar só com evidência
- Deps: B39 + B40 + B42 (mínimo sugerido)

## Promovidas / arquivadas

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
