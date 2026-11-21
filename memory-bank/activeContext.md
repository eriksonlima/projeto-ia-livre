# Active context

## Foco atual

- Etapa 20 **feita** — runtime/shim + harness B com evidência `MEM_SCHED` / `HARNESS_CONTRACT_*`
- Lease liberado
- Branches paralelas B15–B19 podem já ter etapas `pendente` — **não** duplicar promoções

## Mudanças recentes

- Etapa 20 Tasks 1–4: shim host + gate host + QEMU observa contrato E19 no harness B
- Proxy E12 preservado; hipótese **não** comprovada

## Próximo passo

- Sync `main`; se houver etapa `pendente` coerente (topo) sem conflito de lease/merge em massa, claim e continuar; senão relatar estado das pendentes

## Notas

- Sem `TOKENS_PER_S` em B; B ≠ GGUF canônico (B15+)
