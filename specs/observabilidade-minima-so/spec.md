# Spec — Observabilidade mínima no SO (além de UART-only)

Etapa 37 · Issue [#36](https://github.com/eriksonlima/projeto-ia-livre/issues/36) (ex-B30)  
Depende: E4/E10/E11 (boot + UART COM1 pós-ExitBoot), E30/E35 (bare-metal doc — observação ainda serial).

---

## Resultado visível

O kernel IA Livre ganha um **caminho mínimo de observação além da serial UART COM1**: texto ou preenchimento simples na tela via **Graphics Output Protocol (GOP)** **ou**, em fallback documentado, leitura mínima de tecla via **Simple Text Input Protocol**, com **marcadores verificáveis na serial** (`IA_LIVRE_*_OK`). **Sem** ambiente desktop, **sem** janelas, **sem** acoplar observação visual à hipótese Linha A vs B.

A etapa fecha quando:

1. Contrato em `docs/observabilidade-minima-so.md` descreve ordem no boot, marcadores, fallback GOP→input e limites.
2. `make verify` (ou extensão documentada do gate kernel) exige **pelo menos um** caminho comprovado: `IA_LIVRE_GOP_OK` **ou** `IA_LIVRE_INPUT_OK`, mais `IA_LIVRE_OBS_OK` (resumo honesto do modo).
3. Em QEMU/OVMF, a corrida padrão do projeto continua verificável pela **serial** (visual opcional para operador; gate **não** exige screenshot).
4. `AGENTS.md` atualizado; UART COM1 e marcadores E10/E11 **não** regridem.

---

## Contexto fixo (não reinventar)

- **Hoje:** pós-ExitBoot, saída operacional = **UART COM1** (`0x3F8`); contratos [`docs/kernel-pos-boot-services.md`](../../docs/kernel-pos-boot-services.md), [`docs/boot-hardware-real.md`](../../docs/boot-hardware-real.md) (linha «sem framebuffer/teclado» — **esta etapa altera esse limite de forma mínima**).
- **UEFI / `uefi-rs` 0.33:** GOP e SimpleTextInput são protocolos Boot Services; planejamento deve considerar **quando** acionar (tipicamente **antes** de `ExitBootServices`, preservando o pipeline E11).
- **Gates existentes:** `make verify` já exige longa sequência serial (`BOOT_OK` … `NATIVE_BENCH_OK`); extensão **aditiva** apenas.
- **QEMU:** OVMF expõe GOP em modo gráfico padrão; headless sem GOP deve cair no fallback input **ou** `IA_LIVRE_OBS_MODE=uart_only` com skip documentado (ver decisão).
- **Hipótese A vs B:** intocada; **proibido** `TOKENS_PER_S`, `LOAD_KIND=gguf` fingido, alteração de `verify-harness-comparable`.
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`.

---

## Decisão de desenho (única — obrigatória)

### Avaliação das alternativas

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A** | GOP mínimo (fill + texto fixo bitmap/ConOut) **antes** do exit; marcadores na serial UEFI e reconfirmação COM1 se barato | **Escolhida (primária)** |
| **B** | Simple Text Input: aguardar/leitura não bloqueante de uma tecla; `IA_LIVRE_INPUT_OK` | **Escolhida (fallback)** |
| **C** | Desktop / GOP com fonte TTF / compositor | **Rejeitada** — fora do mínimo |
| **D** | Só framebuffer bare-metal pós-exit sem GOP (driver VGA próprio) | **Rejeitada** — escopo e risco altos |
| **E** | Observação só visual sem marcador serial | **Rejeitada** — não verificável no gate |
| **F** | Mouse / USB stack completa / múltiplos modos de vídeo | **Rejeitada** |

### Escolha: **A + B — GOP texto/fill mínimo com fallback SimpleTextInput; prova na serial**

| Peça | Escolha nesta etapa |
|------|---------------------|
| Momento GOP | Após marcadores E10 estáveis e **antes** de `IA_LIVRE_EXIT_BOOT_BEGIN` (Boot Services ativos) |
| Conteúdo GOP | `Blt` com preenchimento sólido (cor fixa documentada) + texto fixo mínimo (ex.: `IA Livre` — fonte bitmap 8×8 ou glyph mínimo; **sem** Unicode complexo) |
| Marcador GOP | `IA_LIVRE_GOP_OK`; opcional `IA_LIVRE_GOP_MODE=<HxW>` / `IA_LIVRE_GOP_PIXEL_FORMAT=` |
| Fallback input | Se `LocateProtocol(GOP)` falhar: `SimpleTextInput` com timeout curto (ex. 2 s) ou poll único; tecla opcional → `IA_LIVRE_INPUT_OK`; sem tecla → `IA_LIVRE_INPUT_OK=skip` **somente** se doc + gate aceitarem skip em headless |
| Marcador resumo | `IA_LIVRE_OBS_OK` + `IA_LIVRE_OBS_MODE=gop\|input\|skip` |
| Pós-ExitBoot | Framebuffer **não** é requisito manter animação; UART COM1 permanece canal canônico pós-exit |
| Anti-fraude | Gate **não** aceita `OBS_OK` sem `GOP_OK` ou `INPUT_OK` correspondente ao modo declarado |
| Metal vs QEMU | Mesmo caminho no EFI; evidência metal continua serial (E35); GOP no PC é bônus operacional |

### Justificativa

- Cumpre roadmap («GOP text **ou** input») com prova automatizável.
- Respeita freestanding: sem desktop, sem novos crates pesados, uso idiomático `uefi::proto::console::gop` / `text::Input`.
- Serial permanece fonte de verdade para CI; visual ajuda operador em hardware real.

### Rejeitado (explícito)

- Shell gráfico, ícones, rede na UI, teclado layout i18n, edição de linha de comando na tela.
- Substituir UART por GOP como único log do `verify`.
- Exigir screenshot ou `-display gtk` no CI.
- `TOKENS_PER_S`, harness comparable, runtime host, `node/`, `agent/`.

---

## Fora de escopo

- Drivers de vídeo pós-ExitBoot (VESA própria, mode switch sem Boot Services).
- Framebuffer double-buffering, scroll, cores ANSI na tela.
- Simple Pointer (mouse), touch, múltiplos monitores.
- Integração da UI com inferência ou status GGUF na tela (só marcadores serial existentes).
- Instalador gráfico, menu de boot customizado além do mínimo GOP.
- Observabilidade remota (rede, IPMI) — Rede IA Livre permanece em `node/` no host.

---

## Critérios de aceite

- [ ] `docs/observabilidade-minima-so.md`: sequência no boot; tabela GOP vs input; marcadores; QEMU vs metal; headless/skip honesto.
- [ ] Ponte em `docs/kernel-alem-do-boot.md` ou `docs/kernel-pos-boot-services.md` apontando para o novo doc.
- [ ] `docs/boot-hardware-real.md` atualizado: deixa de afirmar «sem framebuffer» como permanente; aponta observabilidade mínima E37.
- [ ] `kernel/` implementa caminho GOP mínimo **ou** fallback input conforme spec; **sem** quebrar ordem `EXIT_BOOT_*`.
- [ ] Serial emitida: `IA_LIVRE_GOP_OK` **ou** `IA_LIVRE_INPUT_OK` + `IA_LIVRE_OBS_OK` + `IA_LIVRE_OBS_MODE=`.
- [ ] `scripts/verify-boot.sh` (ou gate documentado) exige marcadores de observabilidade aditivamente.
- [ ] `make verify` verde no ambiente de referência; gates `verify-runtime`, `verify-node`, `verify-agent`, `verify-harness` inalterados.
- [ ] `AGENTS.md` — Como verificar kernel lista novos marcadores e ressalva «sem desktop».
- [ ] Hipótese A vs B / `TOKENS_PER_S` **não** adulterados.
- [ ] README avaliado (`readme-por-fatia`).

### Tabela de canais (referência)

| Canal | Papel | Gate CI |
|-------|--------|---------|
| UART COM1 | Canônico pós-exit; completo | Obrigatório |
| Serial UEFI (pré-exit) | GOP/input + marcadores | Obrigatório |
| Tela GOP | Feedback humano | Não exigido (sem screenshot) |
| Teclado UEFI | Fallback input | Marcador serial obrigatório se modo=input |

---

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| QEMU headless sem GOP | Fallback input ou `OBS_MODE=skip` documentado + gate só em ambiente com GOP default |
| GOP invalida após ExitBoot | Não depender de GOP pós-exit; pintar antes de `EXIT_BOOT_BEGIN` |
| Regressão serial / timeout verify | Marcadores aditivos no fim da fase pré-exit; `VERIFY_TIMEOUT` ajustável |
| Fonte bitmap incorreta em resolução alta | Texto opcional; fill sólido basta para `GOP_OK` |

Rollback: remover extensão do verify e trecho GOP/input no kernel; docs revertem ponte; E11 permanece válida.

---

## Etapa do roadmap

Etapa 37 — Observabilidade mínima no SO (além de UART-only)  
Issue: [#36](https://github.com/eriksonlima/projeto-ia-livre/issues/36)  
Status roadmap: `em_andamento`  
Pronto quando: caminho mínimo (GOP text ou input) + marcador de prova; sem desktop.