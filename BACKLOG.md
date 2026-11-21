# Backlog

Fila de demandas **ainda não** comprometidas no roadmap. Ordem = prioridade (topo primeiro).

Fonte: ideias do usuário, lacunas de `docs/architecture.md` / `docs/product-context.md`, ou pedidos fora da etapa atual.
Este arquivo é **canônico**. Espelho GitHub é **best-effort** (label `backlog`); se `gh` falhar, o item permanece só aqui e a fatia não trava.
Promoção para `ROADMAP.md` é **autônoma** (topo das Abertas quando o roadmap esvazia / etapa fecha / “continuar”) — ver `.cursor/rules/backlog-do-projeto.mdc` / skill `atualizar-backlog`. Com agentes em paralelo: sync + claim check antes de promover (`.cursor/rules/agentes-em-paralelo.mdc`). Não inventar etapa fora deste arquivo.

## Abertas

### B28 — Boot UEFI em hardware real (evidência serial)

- Issue: [#34](https://github.com/eriksonlima/projeto-ia-livre/issues/34)
- Origem: E30 = artefato; metal ainda `BAREMETAL_SKIP`
- Pronto quando: evidência em PC real com ≥ `BOOT_OK` (ideal `EXIT_BOOT_OK`) via serial; sem fingir CI de metal

### B29 — GGUF canônico completo em mídia bare-metal (+ path I/O)

- Issue: [#35](https://github.com/eriksonlima/projeto-ia-livre/issues/35)
- Origem: ESP de gate só `gguf.hdr` 4 KiB; BlockIO QEMU ≠ PC
- Pronto quando: modelo/path documentado na mídia/metal com loader verificável
- Deps: B28 (ou checklist metal)

### B30 — Observabilidade mínima no SO (além de UART-only)

- Issue: [#36](https://github.com/eriksonlima/projeto-ia-livre/issues/36)
- Origem: sem framebuffer/teclado o SO é só EFI+serial
- Pronto quando: caminho mínimo (GOP text ou input) + marcador de prova; sem desktop

### B31 — GPU manager nativo (mecanismos kernel ↔ runtime)

- Issue: [#37](https://github.com/eriksonlima/projeto-ia-livre/issues/37)
- Origem: ADR 0006 / E25 stub host ≠ nativo
- Pronto quando: enum/afinidade/placement mínimo pós-ExitBoot verificável; sem fingir multi-GPU completo
- Deps: preferível após B25

### B32 — Rede IA Livre além de v1 (descoberta WAN mínima)

- Issue: [#38](https://github.com/eriksonlima/projeto-ia-livre/issues/38)
- Origem: v1 sem mDNS/DHT/NAT/relay
- Pronto quando: descoberta além de `--peer`/HELLO LAN + gate; sem exigir SO

### B33 — Autonomia além de v1 (REPL ou tool sandboxed)

- Issue: [#39](https://github.com/eriksonlima/projeto-ia-livre/issues/39)
- Origem: v1 = one-shot + note/recall/help
- Pronto quando: REPL ou ≥1 tool nova sandboxed + gate; sem shell/HTTP irrestrito

### B34 — Shard multi-GPU host executado (além do stub)

- Issue: [#40](https://github.com/eriksonlima/projeto-ia-livre/issues/40)
- Origem: E25 só `SHARD_DOC`
- Pronto quando: placement/shard mínimo real no host com evidência ou skip honesto; ≠ manager nativo

### B35 — Sincronizar architecture/product + glossário pós-E30

- Issue: [#41](https://github.com/eriksonlima/projeto-ia-livre/issues/41)
- Origem: pontes desatualizadas (`no_gguf_forward`, metal vs QEMU)
- Pronto quando: `architecture.md` / README-AGENTS refletem estado atual sem ambiguidade

## Promovidas / arquivadas

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
