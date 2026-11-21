# Plan — Observabilidade mínima no SO (além de UART-only)

Etapa 37 · Spec: `specs/observabilidade-minima-so/`

---

## Abordagem

Três fatias verticais, da menor dependência para a maior. Entrega = **GOP fill+texto mínimo** (primário) **ou** **SimpleTextInput** (fallback) + **marcadores serial** verificáveis, **sem** desktop. **Sem** inferência, **sem** `TOKENS_PER_S`, **sem** alterar harness comparable.

### Desenho fixo (não reabrir na implementação)

**Fase pré-ExitBoot (Boot Services ativos):**

1. Manter fluxo E10/E11 até alocação/mapas estáveis (`IA_LIVRE_ALLOC_OK` …).
2. **Observabilidade mínima** (novo bloco):
   - Tentar `GraphicsOutput` → `SetMode` (se necessário) → `Blt` fill + texto fixo mínimo.
   - Sucesso → `IA_LIVRE_GOP_OK` (+ métricas opcionais) na serial UEFI.
   - Falha GOP → tentar `SimpleTextInput` (timeout curto) → `IA_LIVRE_INPUT_OK` ou skip documentado.
   - Fechar com `IA_LIVRE_OBS_OK` + `IA_LIVRE_OBS_MODE=gop|input|skip`.
3. Continuar `IA_LIVRE_EXIT_BOOT_BEGIN` → ExitBoot → marcadores COM1 inalterados em ordem.

### Fatia 1 — Contrato documental + marcadores canônicos

1. Criar `docs/observabilidade-minima-so.md`: objetivo; decisão GOP primário / input fallback; sequência no boot; tabela de marcadores; limites (sem desktop); QEMU vs metal; headless.
2. Atualizar `docs/boot-hardware-real.md` (limite «só serial» → ponte E37).
3. Ponte mínima em `docs/kernel-pos-boot-services.md` ou `docs/kernel-alem-do-boot.md`.
4. `AGENTS.md`: menção parcial (doc + intenção dos marcadores `GOP_OK` / `OBS_OK`).
5. `readme-por-fatia`: avaliar README.

Critério parcial: implementador sabe **quando** chamar GOP, quais marcadores o gate exigirá e que UART COM1 pós-exit permanece.

### Fatia 2 — GOP mínimo + fallback input no `kernel/`

1. Módulo ou bloco em `kernel/src/main.rs` (ou `kernel/src/obs.rs` se couber): localizar GOP, fill, texto bitmap mínimo; emitir marcadores na serial UEFI (`uefi::println!` / Serial protocol).
2. Fallback: `SimpleTextInput` com timeout; não bloquear boot indefinidamente.
3. Garantir que falha de observabilidade **não** impeça `EXIT_BOOT_OK` (caminho degradado com `OBS_MODE=skip` só se spec/gate permitirem — preferir falha explícita em corrida `-display` padrão do projeto).
4. Atualizar doc com exemplo de trecho serial (pré-exit) contendo `GOP_OK` / `OBS_OK`.
5. `readme-por-fatia`: reavaliar.

Critério parcial: `make run` mostra marcadores de observabilidade na serial **antes** de `EXIT_BOOT_BEGIN`; visual no QEMU é sanidade manual opcional.

### Fatia 3 — Gate estendido + AGENTS completo

1. Estender `scripts/verify-boot.sh`: exigir `IA_LIVRE_OBS_OK` e (`IA_LIVRE_GOP_OK` **ou** `IA_LIVRE_INPUT_OK` alinhado a `IA_LIVRE_OBS_MODE=`).
2. Manter `make verify`; ajustar `VERIFY_TIMEOUT` só se documentado (poll input).
3. Completar `AGENTS.md` → Como verificar (Etapa 37 / gate do kernel).
4. Confirmar que `verify-runtime`, `verify-node`, `verify-agent`, `verify-harness`, `verify-baremetal` não regridem.
5. Não marcar roadmap `feita` nesta task — agente principal após gate + revisor.

### Valores canônicos (orientação)

| Item | Valor |
|------|--------|
| Target | `x86_64-unknown-uefi` |
| uefi-rs | 0.33 (`proto::console::gop`, `proto::console::text::Input`) |
| Janela GOP | Antes de `IA_LIVRE_EXIT_BOOT_BEGIN` |
| Texto sugerido | `IA Livre` (ASCII) |
| Cor fill sugerida | Azul escuro ou cinza documentado (valor RGB fixo) |
| Timeout input fallback | 2 s (ajustável; documentar) |
| Marcadores | `IA_LIVRE_GOP_OK`, `IA_LIVRE_INPUT_OK`, `IA_LIVRE_OBS_OK`, `IA_LIVRE_OBS_MODE=` |
| Make | `verify` (estendido) |

### Notas de implementação (orientação, não código aqui)

- Não usar ConOut/GOP após `exit_boot_services` nesta etapa.
- Preferir `Blt(VideoFill, …)` para fill; texto via buffer próprio ou helper mínimo (sem deps externas).
- Preservar todos os greps/marcadores E4/E10/E11/E19/E12.
- Não tocar `runtime/`, `runtime-native/` (exceto se já acoplado — improvável), `node/`, `agent/`.

---

## Arquivos prováveis

| Arquivo | Ação |
|---------|------|
| `docs/observabilidade-minima-so.md` | criar (Fatia 1) |
| `docs/boot-hardware-real.md` | atualizar ponte E37 (Fatia 1) |
| `docs/kernel-pos-boot-services.md` ou `kernel-alem-do-boot.md` | ponte (Fatia 1) |
| `kernel/src/main.rs` / `kernel/src/obs.rs` | GOP + input (Fatia 2) |
| `kernel/Cargo.toml` | só se feature uefi precisar ajuste (improvável) |
| `scripts/verify-boot.sh` | gate (Fatia 3) |
| `AGENTS.md` | Como verificar (Fatias 1/3) |
| `README.md` | só se `readme-por-fatia` exigir |

**Fora de toque nas fatias (salvo menção em doc):**

- `runtime/`, `runtime-native/`, `node/`, `agent/`
- `scripts/verify-harness*.sh`, harness comparable
- Modelos `models/`

---

## Dependências

- Etapas 10/11 feitas (`EXIT_BOOT_OK`, UART COM1).
- `make verify` e `make run` estáveis.
- QEMU/OVMF do projeto (`Makefile` / `scripts/run-qemu.sh`).

---

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Estrutura doc
test -f docs/observabilidade-minima-so.md
test -f specs/observabilidade-minima-so/spec.md

# Gate kernel estendido (após Fatia 3)
make verify
grep -q 'IA_LIVRE_OBS_OK' scripts/verify-boot.sh
grep -q 'IA_LIVRE_GOP_OK' scripts/verify-boot.sh

# Kernel emite marcadores (após Fatia 2)
grep -q 'IA_LIVRE_OBS_OK' kernel/src/main.rs || grep -q 'IA_LIVRE_OBS_OK' kernel/src/obs.rs

# AGENTS
grep -q 'observabilidade-minima-so' AGENTS.md || grep -q 'IA_LIVRE_OBS_OK' AGENTS.md

# Regressão: outros gates não obrigatórios nesta etapa, mas smoke:
make verify-node
```