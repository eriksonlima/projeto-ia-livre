# Plan — GPU manager / multi-GPU (protótipo mínimo)

## Abordagem

Protótipo **host-side** que materializa o contrato mínimo do ADR 0006 sem tocar o kernel e sem fingir diferencial Linha B.

1. **Contrato + stub (Task 1)** — Doc curta do protótipo (fronteira host vs nativo, o que é stub vs futuro nativo). Superfície mínima no host (`runtime/` preferido): emitir enum (`IA_LIVRE_GPU_DEVICES=…`) e placement/afinidade hint; identidade `IA_LIVRE_GPU_MGR=host_stub` (ou equivalente). Shard pipeline/layer só documentado. **Não** alterar semântica de `IA_LIVRE_ACCEL` / `--n-gpu-layers`. **Não** editar `kernel/`.
2. **Gate honesto (Task 2)** — Preferência: script separado `scripts/verify-gpu-manager.sh` + alvo `make verify-gpu-manager` que (a) reutiliza detecção/skip da Etapa 8 ou espelha política equivalente, (b) exige marcadores do stub quando há GPU, (c) imprime skip canônico e exit 0 sem GPU — **sem** exigir ≥2 GPUs nem fingir multi-GPU. Alternativa aceitável: extensão mínima e **não regressiva** de `verify-runtime-gpu.sh` (marcadores extras opcionais / seção documentada). Preservar `make verify-runtime-gpu` intacto em comportamento Etapa 8.
3. **Pontes (Task 3)** — `AGENTS.md` (Como rodar / verificar / estrutura); ponte no desenho ADR 0006 / `desenho-gpu-manager-multi-gpu.md` (“primeiro item de implementação = stub host”); `architecture.md` se necessário; README avaliado.

Ordem: 1 → 2 → 3. Cada fatia vertical e verificável sozinha; Task 1 compilável/documentável sem GPU.

## Arquivos prováveis

- `docs/gpu-manager-prototipo-host.md` (novo — contrato do stub)
- `docs/desenho-gpu-manager-multi-gpu.md` / `docs/adr/0006-…` (ponte “stub host entregue; nativo futuro”)
- `runtime/src/…` (emissão de marcadores / CLI leve — **sem** quebrar CPU default)
- `scripts/verify-gpu-manager.sh` (preferido) **ou** ajuste cauteloso em `scripts/verify-runtime-gpu.sh`
- `Makefile` (alvo novo se script separado)
- `AGENTS.md`, opcionalmente `docs/architecture.md`, `README.md` (avaliar)
- **Proibido nesta etapa:** `kernel/`, `node/`, `agent/`, `memory-bank/AGENT_CLAIM.md`

## Dependências

- ADR 0006 + desenho (Etapa 16) — já feitos.
- Etapa 8 / ADR 0002 — gate GPU e skip existentes; não regressir.
- Etapa 19 em paralelo — **não** compartilhar arquivos de `kernel/`; worktree `projeto-ia-livre-b19`, branch `etapa-b19-gpu-manager`.
- GGUF / GPU real: só necessários se o gate do stub exigir corrida com offload; enum stub pode ser verificável com N=0 + skip, ou com detecção `nvidia-smi -L` sem inferência — preferir o caminho mais barato que ainda seja honesto.

## Verificação

- Gate Etapa 8 intacto: `make verify-runtime-gpu` (com GPU ou `IA_LIVRE_GPU_SKIP`).
- Gate/stub novo: `make verify-gpu-manager` (ou equivalente documentado) — sucesso com marcadores **ou** skip honesto.
- Checks de docs: existência do doc do protótipo; pontes ADR/desenho; grep de marcadores no código host.
- Negativo: sem diffs em `kernel/`; sem `HARNESS` fingindo prova multi-GPU; sem clusters/RDMA.
- Checklist `AGENTS.md` → Como verificar atualizado na Task 3.
