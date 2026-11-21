# Observabilidade mínima no SO (Etapa 37)

Caminho mínimo de observação **além** da UART COM1: **GOP** (fill + texto bitmap) **ou** fallback **Simple Text Input**, com prova na **serial**. Sem desktop, sem janelas, sem `TOKENS_PER_S`.

Spec: [`specs/observabilidade-minima-so/`](../specs/observabilidade-minima-so/).  
Pré-requisitos: [`kernel-alem-do-boot.md`](kernel-alem-do-boot.md), [`kernel-pos-boot-services.md`](kernel-pos-boot-services.md).

## Decisão

| Peça | Escolha |
|------|---------|
| Primário | `GraphicsOutput`: `Blt(VideoFill)` + texto ASCII `IA Livre` (bitmap 8×8) |
| Fallback | `SimpleTextInput`: open + poll curto (não bloqueia o boot) |
| Momento | **Antes** de `IA_LIVRE_EXIT_BOOT_BEGIN` (Boot Services ativos) |
| Prova | Marcadores na serial UEFI; gate **não** exige screenshot |
| Pós-exit | UART COM1 continua canônica; framebuffer **não** é mantido |

**Rejeitado:** desktop, TTF, driver VGA pós-exit, mouse, substituir UART pelo GOP no gate.

## Sequência no boot

1. Marcadores E10 (`BOOT_OK` … `ALLOC_OK`) + loader GGUF (se houver).
2. Bloco observabilidade (esta etapa).
3. `IA_LIVRE_EXIT_BOOT_BEGIN` → ExitBoot → `EXIT_*` na COM1 (inalterados).

## Marcadores

| Marcador | Significado |
|----------|-------------|
| `IA_LIVRE_GOP_OK` | Fill + texto mínimo aplicados via GOP |
| `IA_LIVRE_GOP_MODE=<W>x<H>` | Resolução do modo atual (opcional mas emitido no sucesso) |
| `IA_LIVRE_GOP_PIXEL_FORMAT=` | `rgb` / `bgr` / `bitmask` / `blt_only` |
| `IA_LIVRE_INPUT_OK` | Protocolo SimpleTextInput aberto e poll concluído (tecla opcional) |
| `IA_LIVRE_OBS_MODE=` | `gop` \| `input` \| `skip` |
| `IA_LIVRE_OBS_OK` | Resumo: modo declarado **e** marcador correspondente (`GOP_OK` ou `INPUT_OK`) |

Anti-fraude: **não** emitir `OBS_OK` com `OBS_MODE=skip`. Falha total de observabilidade **não** impede `EXIT_BOOT_OK`.

### Valores de prova (fill)

| Item | Valor |
|------|--------|
| Cor fill | RGB `(0x12, 0x24, 0x48)` (azul escuro) |
| Texto | `IA Livre` (ASCII) |
| Timeout input | poll + `stall` até ~2 s (não bloqueia além disso) |

## QEMU vs metal

| Ambiente | Esperado |
|----------|----------|
| QEMU do projeto (`-display none`) | GOP virtual ainda exposto pelo OVMF → tipicamente `OBS_MODE=gop` |
| Headless sem GOP | Fallback `input` se o protocolo existir; senão `OBS_MODE=skip` (gate kernel falha sem `OBS_OK`) |
| PC real (E35) | Serial continua evidência; GOP na tela é bônus operacional |

## Exemplo de trecho serial (pré-exit)

Host de referência (QEMU `-display none`, OVMF):

```
IA_LIVRE_ALLOC_OK
… (GGUF opcional) …
IA_LIVRE_GOP_MODE=1280x800
IA_LIVRE_GOP_PIXEL_FORMAT=bgr
IA_LIVRE_GOP_OK
IA_LIVRE_OBS_MODE=gop
IA_LIVRE_OBS_OK
IA_LIVRE_EXIT_BOOT_BEGIN
```

## Limites

- Sem compositor, scroll, Unicode complexo, layout de teclado i18n.
- Observação visual **não** entra no harness A vs B.
- Hipótese Linha A/B e `TOKENS_PER_S` intocados.

## Como observar

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
make build && make run   # serial: … GOP_OK/OBS_OK … EXIT_BOOT_BEGIN …
make verify              # exige OBS_OK + (GOP_OK|INPUT_OK) alinhado ao modo
```
