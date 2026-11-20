# Spec — Evolução do harness (Linha A otimizada / perfil GPU)

## Resultado visível

Existe **metodologia documentada** que evolui o harness v1 (Etapas 9/12) em duas frentes, **sem** fingir prova da hipótese:

1. **Perfil «Linux otimizado» na Linha A** — o que conta como A «otimizada» além da referência pragmática atual (Ubuntu + `ia-livre-runtime` CPU sem campanha de tuning): checklist de tuning/isolamento, carga canônica preservada, marcadores/namespace e como reportar baseline vs A-otimizada.
2. **Perfil GPU espelhado A/B** — quando e como medir offload GPU no harness (espelhando carga canônica), fronteira vs métricas do protótipo Etapa 8 / ADR 0002, e o que **ainda não** é espelhável em B (proxy pós-ExitBoot ≠ GGUF; sem inventar números B).

**Gate novo só se houver execução real** nesta etapa (script + corrida verificável dos perfis). Caso contrário: documentar que o gate permanece `make verify-harness` (A CPU + B proxy) e que os perfis são **metodologia / roadmap de medição**.

## Contexto fixo (não reinventar)

- Harness v1: [`docs/harness-linha-a-b.md`](../../docs/harness-linha-a-b.md) — A = host CPU GGUF **sem** tuning; GPU **fora** do v1; joules/p95 fora; hipótese **não** comprovada; A e B **não** lado a lado comparáveis (`TOKENS_PER_S` vs `PROXY_*`).
- Linha B mínima: [`docs/runtime-nativo-linha-b.md`](../../docs/runtime-nativo-linha-b.md) — proxy pós-ExitBoot; **não** TinyLlama.
- GPU host (prova de caminho, não harness): [`docs/runtime-inferencia-gpu-metricas.md`](../../docs/runtime-inferencia-gpu-metricas.md) + ADR [`0002`](../../docs/adr/0002-aceleracao-gpu-host-llama-cpp.md).
- Hipótese: [`docs/architecture.md`](../../docs/architecture.md) — «Linux otimizado» na Linha A vs IA Livre na B; integração CPU–GPU nativa = diferencial **candidato** de B (não implementado).
- GPU manager / multi-GPU: já desenhados na Etapa 16 (ADR 0006) — **fora** desta etapa (não implementar).
- Scripts atuais: `scripts/run-harness-line-a.sh` (CPU, `n-gpu-layers` default 0), `scripts/verify-harness.sh` (A + B proxy).
- Nomenclatura: Projeto IA Livre / IA Livre / Rede IA Livre.
- Rule `readme-por-fatia`: cada fatia avalia `README.md`; se não precisar, registrar.

## Decisão de desenho (única — obrigatória)

| Peça | Escolha nesta etapa |
|------|---------------------|
| Forma | **Principalmente documental** — metodologia + pontes; código/scripts **só** se a etapa incluir execução real dos novos perfis |
| Linha A «otimizada» | Documentar checklist mínimo de «Linux otimizado» (ex.: governor, isolamento de CPU/`isolcpus` ou afinidade, mitigação de ruído de SO, flags de runtime se houver) como **perfil de medição nomeado**, distinto da baseline A pragmática já publicada |
| Perfil GPU harness | Documentar perfil espelhado: mesma carga canônica (TinyLlama Q4_K_M, prompt, `n-predict=32`) + offload (`--n-gpu-layers` > 0, CUDA canônico / Vulkan alternativa per ADR 0002) **na Linha A**; em B, espelho GPU **só** quando B tiver caminho de inferência GGUF/acelerador real — até lá, perfil GPU-B = **futuro explícito**, sem inventar `TOKENS_PER_S` / load GGUF |
| Relação com E5/E8 | Métricas `IA_LIVRE_INFER_*` / docs de protótipo **não** substituem marcadores `IA_LIVRE_HARNESS_*`; perfil GPU do harness reutiliza o motor host mas sob namespace/metodologia do harness |
| Gate | **Default desta etapa:** gate permanece `make verify-harness` (A CPU + B proxy). Gate/script novo **somente** se Task de execução real fechar com corrida verificável; senão, doc afirma «metodologia sem gate novo» |
| Hipótese | **Não** comprovada; não declarar A≻B nem B≻A; não inventar números de B GGUF |
| GPU manager | **Não** implementar (Etapa 16 / ADR 0006 permanece desenho) |
| Doc canônico | Estender [`docs/harness-linha-a-b.md`](../../docs/harness-linha-a-b.md) **e/ou** doc dedicado (ex.: `docs/harness-perfis-a-otimizada-gpu.md`) fixado na Task 1/2; pontes em `architecture.md` |

### Rejeitado (explícito)

- Prova ou refutação da hipótese A vs B.
- TinyLlama / GGUF nativo na Linha B nesta etapa.
- Inventar throughput/load/GPU para B proxy.
- Tratar métricas Etapa 8 como se já fossem o perfil GPU do harness A/B.
- Implementar GPU manager, multi-GPU real, joules, p95 multi-request (fora do mínimo; só nomear se necessário).
- Trocar a carga canônica do harness v1 (modelo/prompt/`n-predict`) sem ADR.
- Invalidar ADR 0002 ou o gate CPU/proxy existente.
- Gate que «passa» sem execução real dos perfis novos (skip disfarçado de sucesso de perfil otimizado/GPU).

## Conteúdo obrigatório

### 1. Metodologia «Linux otimizado» (Linha A)

- Distinção: **A pragmática** (harness v1 atual) vs **A otimizada** (perfil nomeado).
- Checklist mínimo de tuning/isolamento (itens concretos o bastante para repetir; sem exigir campanha científica completa).
- Carga canônica inalterada; marcadores esperados; como rotular baseline vs otimizada no relatório.
- Honestidade: otimizar A **não** prova a hipótese; só melhora a referência.

### 2. Metodologia perfil GPU espelhado A/B

- Quando o perfil GPU entra no harness (A host com feature CUDA/Vulkan + `n-gpu-layers` > 0).
- Espelho A/B: pré-condições para B (GGUF/acelerador nativo) — **ausentes hoje** → GPU-B = roadmap de medição.
- Fronteira vs `runtime-inferencia-gpu-metricas.md` / ADR 0002 / ADR 0006.
- Marcadores sugeridos (`HARNESS_ACCEL=cuda|vulkan`, etc.) sem obrigar implementação se não houver execução.

### 3. Gate e pontes

- Decisão explícita: gate novo **sim/não** nesta etapa, com critério («só se execução real»).
- Atualizar `harness-linha-a-b.md` (limitação A + «GPU fora do v1» → apontar perfis documentados).
- Ponte em `architecture.md` (harness evoluiu metodologia; prova continua aberta).
- `AGENTS.md` / README: só se a superfície pública precisar (readme-por-fatia).

## Fora de escopo

- Prova da hipótese; TinyLlama nativo em B
- Multi-GPU real; GPU manager (código)
- Joules, p95, VRAM multi-tenant como critério desta etapa
- Mudança do modelo canônico; marketplace / P2P
- Invalidar Etapas 9/12 ou gates kernel/runtime/node/agent

## Critérios de aceite

- [ ] Metodologia «Linux otimizado» Linha A documentada (checklist + distinção vs A pragmática)
- [ ] Metodologia perfil GPU espelhado A/B documentada (A host possível; B futuro sem números inventados)
- [ ] Gate: ou (a) script/gate novo com execução real verificável, **ou** (b) doc afirma que gate permanece `make verify-harness` e perfis são só metodologia
- [ ] `harness-linha-a-b.md` (e/ou doc dedicado) + ponte em `architecture.md` atualizados
- [ ] Hipótese **não** declarada comprovada; B GGUF **não** inventado
- [ ] Sem implementação de GPU manager
- [ ] README avaliado (`readme-por-fatia`)
- [ ] Etapa 18 não marcada `feita` nesta spec (só após revisão pelo agente principal)

## Riscos e rollback

- **Risco:** leitor achar que A otimizada ou GPU host = prova A vs B → avisos explícitos.
- **Risco:** gate novo sem corrida real → proibido; preferir (b) documental.
- **Risco:** misturar métricas E8 com `HARNESS_*` → namespace e docs separados.
- **Rollback:** reverter docs/pontes/scripts novos; etapa continua `em_andamento`.

## Etapa do roadmap

- Etapa 18 — Evolução do harness (Linha A otimizada / perfil GPU) (`em_andamento`, Issue [#18](https://github.com/eriksonlima/projeto-ia-livre/issues/18))
- Spec: `specs/evolucao-harness-linha-a-gpu/`
- Pronto quando (roadmap): metodologia documentada para «Linux otimizado» na Linha A e/ou perfil GPU espelhado A/B; gate só se houver execução real.
