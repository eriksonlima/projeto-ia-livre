# Plan — GPU manager nativo (mecanismos kernel ↔ runtime)

Etapa 38 · Spec: `specs/gpu-manager-nativo/`

---

## Abordagem

Três fatias verticais: contrato → kernel (mecanismos) → gate. Entrega = **enum + afinidade + placement** pós-ExitBoot na serial COM1, identidade **`IA_LIVRE_GPU_MGR=native`**, integração conceptual com Weights/KvCache/Prefill/Decode da E19. **Sem** CUDA real no QEMU; **sem** `TOKENS_PER_S`; **sem** alterar stub host E25.

### Desenho fixo (não reabrir na implementação)

**Fase pós-ExitBoot (UART COM1):**

1. Manter demo E19 até `IA_LIVRE_MEM_SCHED_OK`.
2. **GPU manager nativo** (novo bloco):
   - Emitir `IA_LIVRE_GPU_MGR=native`.
   - Enumerar devices (`IA_LIVRE_GPU_DEVICES=` + linhas `DEV*_KIND=`); default QEMU = tabela sintética (ex. N=0 ou N=1 — valor fixado no doc da Fatia 1).
   - Registrar afinidade: classes `weights` e `kvcache` → `IA_LIVRE_GPU_AFFIN_*`.
   - Placement por fase: reutilizar ordem Prefill→Decode da demo E19 com hints `IA_LIVRE_GPU_PLACE_*`.
   - `IA_LIVRE_GPU_SHARD_DOC=pipeline_layer` (espelho honesto do stub host).
   - `IA_LIVRE_GPU_MGR_OK`.
3. Continuar proxy `NATIVE_BENCH_*` sem mudar contrato Linha B.

**Ponte runtime-native (opcional, mesma etapa):** se o proxy já reemite contrato, acrescentar no máximo `IA_LIVRE_GPU_NATIVE_BRIDGE_OK` após ler estado do kernel ou eco idêntico dos marcadores — **proibido** inventar offload ou tokens.

### Fatia 1 — Contrato documental + marcadores canônicos

1. Criar `docs/gpu-manager-nativo.md`: objetivo ADR 0006; tabela host (E25) vs nativo (E38); sequência serial; marcadores; enum sintética no QEMU; limites multi-GPU.
2. Atualizar `docs/desenho-gpu-manager-multi-gpu.md` (seção Implementação → item 2 = E38 feito).
3. Atualizar `docs/gpu-manager-prototipo-host.md` (uma linha: stub não substitui nativo).
4. Ponte em `docs/memoria-scheduler-impl-minima.md` (GPU placement complementa MEM_SCHED).
5. `AGENTS.md`: menção parcial (doc + marcadores previstos).
6. `readme-por-fatia`: avaliar README.

Critério parcial: implementador sabe ordem pós-`MEM_SCHED_OK`, nomes estáveis dos marcadores e que `host_stub` é proibido no kernel.

### Fatia 2 — Mecanismos no `kernel/` (+ ponte opcional `runtime-native/`)

1. Novo módulo `kernel/src/gpu_mgr.rs` (ou equivalente): enum sintética, registro de afinidade sobre handles/regiões da demo E19, placement Prefill/Decode, emissão UART.
2. Integrar em `kernel/src/main.rs` após `mem_sched_demo` / `MEM_SCHED_OK`; falha do bloco GPU **não** deve corromper `EXIT_BOOT_OK` já ocorrido — preferir degradar com marcador de falha explícito **só** se spec/gate aceitarem; default = caminho feliz sempre no QEMU de referência.
3. (Opcional) `runtime-native/`: eco/bridge documentado no doc da Fatia 1.
4. Atualizar doc com exemplo de trecho serial COM1 contendo `GPU_MGR=native` … `GPU_MGR_OK`.
5. `readme-por-fatia`: reavaliar.

Critério parcial: `make run` mostra marcadores GPU na serial **entre** `MEM_SCHED_OK` e `NATIVE_BENCH_BEGIN`.

### Fatia 3 — Gate estendido + AGENTS completo

1. Estender `scripts/verify-boot.sh`: exigir `IA_LIVRE_GPU_MGR=native`, `IA_LIVRE_GPU_DEVICES=`, afinidade mínima (`AFFIN`), placement (`PLACE_PHASE`), `IA_LIVRE_GPU_MGR_OK`.
2. Greps aditivos em `AGENTS.md` → Como verificar (Etapa 38 / gate kernel).
3. Confirmar `make verify-gpu-manager`, `make verify-runtime-gpu`, `verify-harness*` inalterados.
4. Não marcar roadmap `feita` nesta task — agente principal após gate + revisor.

### Valores canônicos (orientação)

| Item | Valor |
|------|--------|
| Target | `x86_64-unknown-uefi` |
| I/O | UART COM1 pós-exit |
| Identidade | `IA_LIVRE_GPU_MGR=native` |
| Devices QEMU ref. | `IA_LIVRE_GPU_DEVICES=1` + `IA_LIVRE_GPU_DEV0_KIND=synthetic` (ajustável na doc se N=0 for escolhido — gate e doc **alinhados**) |
| Afinidade | `weights` → device0; `kvcache` → device0 (exemplo) |
| Placement | prefill: `device0\|weights`; decode: `device0\|kvcache` (exemplo — fixar na Fatia 1) |
| Shard | `IA_LIVRE_GPU_SHARD_DOC=pipeline_layer` |
| Make | `verify` (estendido) |

### Notas de implementação (orientação, não código aqui)

- Reutilizar helpers UART existentes (`uart_write`, `uart_emit_kv`).
- Não alterar ordem pré-exit nem obs E37.
- Não tocar `scripts/gpu-manager-stub.sh`, `runtime/src/main.rs` (Etapa 8), `node/`, `agent/`.
- Greps E19 (`MEM_SCHED_OK`, `TYPED_*`, `PHASE=`) permanecem obrigatórios.

---

## Arquivos prováveis

| Arquivo | Ação |
|---------|------|
| `docs/gpu-manager-nativo.md` | criar (Fatia 1) |
| `docs/desenho-gpu-manager-multi-gpu.md` | ponte implementação (Fatia 1) |
| `docs/gpu-manager-prototipo-host.md` | nota fronteira (Fatia 1) |
| `docs/memoria-scheduler-impl-minima.md` | ponte complementar (Fatia 1) |
| `kernel/src/gpu_mgr.rs` | enum + afinidade + placement (Fatia 2) |
| `kernel/src/main.rs` | chamada pós MEM_SCHED (Fatia 2) |
| `runtime-native/src/…` | bridge opcional (Fatia 2) |
| `scripts/verify-boot.sh` | gate (Fatia 3) |
| `AGENTS.md` | Como verificar (Fatias 1/3) |
| `Makefile` | só se novo target explicitamente necessário (improvável) |
| `README.md` | só se `readme-por-fatia` exigir |

**Fora de toque (salvo menção em doc):**

- `scripts/gpu-manager-stub.sh`, `scripts/verify-gpu-manager.sh`
- `scripts/verify-runtime-gpu.sh`, `runtime/` inferência
- `scripts/verify-harness*.sh`, harness comparable
- `node/`, `agent/`

---

## Dependências

- E11 feita (`EXIT_BOOT_OK`, COM1).
- E19 feita (`MEM_SCHED_OK`, demo tipada).
- E25 feita (referência de marcadores — **não** copiar `host_stub`).
- `make verify` estável antes da Fatia 3.

---

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Estrutura doc
test -f docs/gpu-manager-nativo.md
test -f specs/gpu-manager-nativo/spec.md

# Gate kernel estendido (após Fatia 3)
make verify
grep -q 'IA_LIVRE_GPU_MGR=native' scripts/verify-boot.sh
grep -q 'IA_LIVRE_GPU_MGR_OK' scripts/verify-boot.sh

# Kernel emite marcadores (após Fatia 2)
grep -q 'IA_LIVRE_GPU_MGR_OK' kernel/src/gpu_mgr.rs || grep -q 'IA_LIVRE_GPU_MGR' kernel/src/

# Stub host preservado
make verify-gpu-manager

# AGENTS
grep -q 'gpu-manager-nativo' AGENTS.md || grep -q 'IA_LIVRE_GPU_MGR=native' AGENTS.md
```