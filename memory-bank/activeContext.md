# Active context

## Foco atual

- Etapa do roadmap: Etapa 6 — Protótipo do nó Rede IA Livre (**feita**)
- Spec ativa: specs/no-rede-ia-livre/ (Tasks 1–3 feitas)
- Fatia / task: Task 3 concluída (MSG/ACK + `make verify-node`)

## Mudanças recentes

- Task 3: sessão TCP com `MSG ola-rede-ia-livre` / `ACK` + `IA_LIVRE_MSG_OK`
- `scripts/verify-node.sh` + alvo `make verify-node`; gate em AGENTS.md → Como verificar
- Doc do protocolo fechada com defaults e exemplo de stdout
- Etapa 6 marcada `feita` (Pronto quando do roadmap cumprido)

## Próximo passo

- Aguardar pedido do usuário: não há etapa `em_andamento` no ROADMAP (1–6 feitas). Não inventar etapa sem gravar no roadmap + issue.

## Notas

- Nó independente do SO / kernel / runtime
- Defaults: TCP 7400/7401, UDP 7410, msg `ola-rede-ia-livre`, timeout gate 45s (`VERIFY_NODE_TIMEOUT`)
- Gate: `make verify-node` (fallback `--peer`; não exige QEMU/GGUF)
