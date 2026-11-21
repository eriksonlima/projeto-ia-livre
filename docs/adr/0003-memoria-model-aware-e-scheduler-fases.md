# ADR 0003 — Memória model-aware e scheduler por fases (desenho candidato)

- Status: aceita (nível **desenho**; implementação = etapas futuras)
- Data: 2026-11-20

## Contexto

A hipótese de pesquisa do Projeto IA Livre exige mecanismos nativos que diferenciem a Linha B (IA Livre) da Linha A (Linux + runtime). Em `docs/architecture.md` restava aberta a lacuna «desenho fino de memória model-aware e do scheduler de inferência».

As Etapas 10–12 entregaram mapa/bump, ExitBoot e um **proxy** Linha B (microbenchmark) — **sem** tipagem de memória de modelo nem consciência de prefill/decode. Sem um contrato candidato, o risco do ADR 0001 materializa-se: «só Linux + runtime» com kernel vazio de diferencial.

ADR 0001 permanece: inferência **fora** do kernel.

## Decisão

1. **Interface kernel ↔ runtime** (desenho): o runtime declara **classe de memória** e **fase de inferência**; o kernel aplica políticas de mecanismo — **não** executa o modelo.
2. **Classes de memória mínimas:**
   - `Weights` — região de pesos; candidata a somente-leitura após load; vida longa.
   - `KvCache` — região quente de KV; leitura/escrita no decode; redimensionável no futuro.
3. **Hints de scheduler (fase):**
   - `Load` | `Prefill` | `Decode` | `Idle` (mínimo obrigatório no desenho: `Prefill` e `Decode`).
   - O kernel usa o hint para prioridade / quantum / afinidade **candidatas** — sem embutir tensores ou sampling.
4. **Fronteira:** GGUF, tensores, sampling e lógica de KV ficam no **runtime**; páginas/regiões tipadas e escala por hint ficam no **kernel**.
5. **Fora desta decisão (na data da ADR):** ABI/syscalls estáveis, implementação no `kernel/`, GPU manager, multi-tenant completo, prova da hipótese, cópia de SLM-OS/TensorOS/AgentOS como blueprint.  
   **Atualização E71:** ABI mínima freestanding versionada (≠ syscall) — [`abi-runtime-native.md`](../abi-runtime-native.md).

Doc de desenho: [`docs/desenho-memoria-scheduler-nativo.md`](../desenho-memoria-scheduler-nativo.md).

## Consequências

### Positivas

- Fecha a lacuna de architecture no nível desenho com **uma** proposta clara
- Alinha o diferencial B vs A ao manifesto (mecanismos nativos, kernel auditável)
- Dá horizonte às etapas de implementação sem fingir que o proxy E12 já é o contrato

### Negativas

- Contrato ainda não implementado nem medido no harness
- Risco de over-design se a ABI for congelada cedo demais — por isso ABI fica **fora** desta ADR
- Exige disciplina para não puxar inferência para dentro do kernel

## Relação com etapas

| Etapa | Papel |
|-------|--------|
| 10–11 | Memória física / ExitBoot — base, sem classes de modelo |
| 12 | Proxy B — **não** implementa este contrato |
| Futuro | Allocator tipado + hints reais + (depois) carga GGUF em B |
