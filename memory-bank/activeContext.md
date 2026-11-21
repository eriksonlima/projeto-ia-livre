# Active context

## Foco atual

- Etapa 26 **feita** — loader GGUF ESP (`esp_header`); `B_BLOCK=no_gguf_infer`
- Métricas CPU serial atualizadas (~13,4 tok/s mediana)
- Backlog Abertas: B21 (inferência B), B22 (re-corrida quieta)
- Lease: livre

## Mudanças recentes

- Remediação métricas CPU sem contenção
- B20–B22 capturados; B20 → Etapa 26 feita
- ADR 0008; prefixo `IA_LIVRE/gguf.hdr` no ESP; gates atualizados

## Próximo passo

- Promover B21 → Etapa 27 (inferência mínima / TOKENS_PER_S em B) ao continuar
- Hipótese A vs B ainda **INCONCLUSIVO**

## Notas

- README considerado; operacional em AGENTS.md
- Medições T/s: um gate por vez; host 4 threads
