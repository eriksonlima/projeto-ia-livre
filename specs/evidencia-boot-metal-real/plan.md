# Plan — Evidência de boot metal real (Etapa 46)

## Abordagem

Reutilizar a infra E35 (contrato, pasta de evidência, gate). Esta etapa **não** redesenha o validador: fecha com **log real** ou **bloqueio honesto**.

1. **Checklist / procedimento** — consolidar Secure Boot, gravação USB/ESP, captura serial e anti-padrões (QEMU) em docs já existentes; deixar explícitos caminhos A (evidência) e B (bloqueio).
2. **Evidência ou bloqueio** — se o operador fornecer log de PC: validar formato V1, anexar em `docs/evidence/boot-metal/`, rodar gate com `SKIP=0`. Se não houver PC nem log: **não inventar**; documentar SKIP na issue #46 + README da pasta.
3. **Fecho** — pontes AGENTS/README se necessário; `make verify-baremetal` verde no modo aplicável; atualizar Memory Bank / desfecho na issue.

Ordem: Task 1 → Task 2 → Task 3. Task 2 decide o ramo A vs B; Task 3 só confirma gate + pontes do ramo escolhido.

## Arquivos prováveis

| Arquivo | Ação |
|---------|------|
| `docs/boot-hardware-real.md` | atualizar — seção Etapa 46 / caminhos A–B; reforço Secure Boot |
| `docs/evidence/boot-metal/README.md` | atualizar — estado (log anexado **ou** SKIP) |
| `docs/evidence/boot-metal/YYYY-MM-DD-<host>.txt` | **só se** log real fornecido (caminho A) |
| `docs/evidence/boot-metal/TEMPLATE.txt` | tocar só se formato precisar de campo novo |
| `scripts/verify-baremetal.sh` | só se anti-fraude/checklist exigir ajuste mínimo |
| `AGENTS.md` | ponte curta Etapa 46 / desfecho se capa operacional ficar enganosa |
| `README.md` | avaliar (`readme-por-fatia`); tipicamente sem mudança |
| `ROADMAP.md` / issue #46 | desfecho A ou B |
| `docs/adr/0011-…` | **evitar**; só aditivo se decisão nova (improvável) |

**Não tocar (salvo regressão):** `kernel/`, `runtime/`, harness A/B, node, agent.

## Dependências

- E30: `make baremetal-esp` / `IMAGE_OK`
- E35: formato `EVIDENCE_V1`, `METAL_OK`/`SKIP` em `verify-baremetal.sh`
- Operador: PC UEFI + USB-UART **ou** arquivo de log — **fora do controle do agente**

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Sempre (artefato)
make baremetal-esp
make verify-baremetal   # default SKIP=1 → IMAGE_OK

# Caminho A (só com log real)
IA_LIVRE_BAREMETAL_SKIP=0 \
IA_LIVRE_BAREMETAL_EVIDENCE=docs/evidence/boot-metal/<arquivo>.txt \
make verify-baremetal
# Esperado: IA_LIVRE_BAREMETAL_METAL_OK

# Caminho B: SKIP=1 + nota na issue #46; ausência de arquivo fingindo metal
test ! -f docs/evidence/boot-metal/*qemu* 2>/dev/null || true
grep -q 'IA_LIVRE_BAREMETAL_METAL_OK' scripts/verify-baremetal.sh
grep -qi 'Secure Boot' docs/boot-hardware-real.md
```

Gate documental opcional: `make verify-docs-consistency` se pontes mudarem.
