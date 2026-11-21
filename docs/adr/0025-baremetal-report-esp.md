# ADR 0025 — Canal padrão bare-metal: relatório na ESP (sem COM1)

- Status: aceita
- Data: 2026-11-21

## Contexto

`METAL_OK` e coletas bare-metal dependiam de UART COM1. Notebooks sem serial não fechavam o pilar 2 nem tinham canal verificável de marcadores/métricas após boot USB. Vídeo prova boot humano, mas não é input de gate.

## Decisão

1. **Canal canônico bare-metal (operador / PC real):** arquivo texto `\IA_LIVRE\baremetal-report.txt` escrito pelo kernel via SimpleFileSystem **antes** de `ExitBootServices`.
2. **Formato:** `IA_LIVRE_BAREMETAL_REPORT_V1` + marcadores/`KEY=value` no namespace `IA_LIVRE_*`.
3. **UART COM1** permanece válido (QEMU / lab); **não** é obrigatório para o operador notebook.
4. **ConOut/GOP** = observação humana; **vídeo/foto** nunca entram no gate.
5. Pós-ExitBoot sem SFS: na Etapa 73 métricas pós-exit não persistiam; **Etapa 74** adiciona slot BlockIO (`IALVPST1`) no mesmo arquivo → `REPORT_POST_OK` (best-effort).

## Rejeitado

- Exigir USB-UART para `METAL_OK`
- Aceitar MP4/screenshot como evidência automatizada
- Tratar log QEMU como metal
- Inventar `COMPROVA` / tokens no path metal

## Consequências

- Contrato: [`docs/baremetal-report.md`](../baremetal-report.md)
- Gate: `make verify-baremetal` com `SKIP=0` + report ESP
- Serial continua nos gates QEMU (`make verify`)
