# Glossário — Projeto IA Livre

Termos estáveis usados em `architecture.md`, `AGENTS.md` e contratos. Links apontam para a fonte canônica.

Princípios: [`manifesto.md`](manifesto.md).

| Termo | Significado curto | Fonte |
|-------|-------------------|--------|
| **Projeto IA Livre** | Ecossistema (SO + runtime + autonomia + rede) | [`manifesto.md`](manifesto.md) |
| **IA Livre** | SO / kernel UEFI do projeto | ADR [`0001`](adr/0001-separacao-camadas-e-p2p.md) |
| **Rede IA Livre** | Protocolo P2P; **não** exige o SO | [`rede-ia-livre-v1.md`](rede-ia-livre-v1.md) |
| **Linha A** | Host Linux + runtime GGUF (referência) | [`harness-linha-a-b.md`](harness-linha-a-b.md) |
| **Linha B** | Caminho nativo QEMU pós-ExitBoot (proxy + contrato + loader) | [`runtime-nativo-linha-b.md`](runtime-nativo-linha-b.md) |
| **Proxy Linha B** | Microbench pós-exit (`NATIVE_BENCH_*`); **≠** geração GGUF | [`runtime-nativo-linha-b.md`](runtime-nativo-linha-b.md) |
| **`runtime/` (host)** | Inferência llama.cpp no Linux (`std`) | ADR 0002 / `AGENTS.md` |
| **`runtime-native/`** | Runtime freestanding Linha B (layout/forward parcial) | Etapa 29+ / crate `runtime-native/` |
| **`TOKENS_PER_S`** | Métrica de geração medida — **proibida** fingida em B | harness / ADR [`0013`](adr/0013-geracao-canonica-fatiada-linha-b.md) |
| **`B_BLOCK`** | Bloqueio honesto em B; evolução: `no_gguf_path` → `no_gguf_generate` → `no_gguf_decode` → **`no_gguf_full_prefill`** (atual) | [`runtime-nativo-linha-b.md`](runtime-nativo-linha-b.md) |
| **Veredito** | `COMPROVA` / `REFUTA` / `INCONCLUSIVO` no harness comparável | [`harness-a-b-comparavel.md`](harness-a-b-comparavel.md) |
| **bare-metal** | Boot/imagem em PC real ou artefato ESP/USB — **≠** QEMU | [`boot-hardware-real.md`](boot-hardware-real.md) |
| **QEMU ≠ metal** | `make verify` (QEMU) ≠ evidência de PC físico | [`boot-hardware-real.md`](boot-hardware-real.md) |
| **`BAREMETAL_SKIP`** | Skip honesto de prova metal no gate de artefato | [`boot-hardware-real.md`](boot-hardware-real.md) |
| **`METAL_OK`** | Evidência serial de PC real aceita pelo gate | Etapa 35 / `verify-baremetal` |
| **`*_SKIP`** | Skip honesto em gates (GPU, shard, metal, mDNS) — exit 0 **sem** fingir sucesso | `AGENTS.md` (vários gates) |
| **`host_stub`** | Stub GPU manager host (E25) | [`gpu-manager-prototipo-host.md`](gpu-manager-prototipo-host.md) |
| **`native` (GPU_MGR)** | Mecanismos GPU no kernel (E38) | [`gpu-manager-nativo.md`](gpu-manager-nativo.md) |
| **`host_shard_exec`** | Shard multi-GPU host executado (E41) | [`shard-multi-gpu-host.md`](shard-multi-gpu-host.md) |
| **Bootstrap (rede)** | Lista `--bootstrap` além de `--peer`/HELLO (E39) | [`rede-descoberta-wan.md`](rede-descoberta-wan.md) |
| **`calc`** | Tool sandboxed do agente (E40) | [`autonomia-alem-v1.md`](autonomia-alem-v1.md) |
| **GOP / OBS** | Observabilidade mínima pré-exit (E37) | [`observabilidade-minima-so.md`](observabilidade-minima-so.md) |
| **PeerId** | Fingerprint ed25519 (âncora de confiança do nó) | [`rede-ia-livre-v1.md`](rede-ia-livre-v1.md) |
