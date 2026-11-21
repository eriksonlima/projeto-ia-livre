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
| **`B_BLOCK`** | Bloqueio honesto em B; com Decode+métricas E44 **omitido**; histórico: … → `no_gguf_prefill_22l` (E43) | [`runtime-nativo-linha-b.md`](runtime-nativo-linha-b.md) / ADR [`0015`](adr/0015-decode-tokens-linha-b.md) |
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
| **Protótipo objetivo atingido** | Checklist dos 3 pilares (hipótese A/B; USB/metal; Rede+autonomia host); celebrar só com evidência | [`prototipo-objetivo-atingido.md`](prototipo-objetivo-atingido.md) |
| **Passo intermediário (espécie B)** | N≥8 layers e/ou `n_predict`≥8 — progresso E59 antes da espécie canônica 22L×32 | [`runtime-native-perf-especie.md`](runtime-native-perf-especie.md) |
| **ADR 0020** | Passo intermediário inviável no guest pós-otimização E59 (teto 2L×1 permanece) | [`adr/0020-runtime-native-passo-intermediario-inviavel.md`](adr/0020-runtime-native-passo-intermediario-inviavel.md) |
| **ADR 0021** | Espécie canônica 22L×32 inviável no gate atual (E60) | [`adr/0021-especie-canonica-linha-b-inviavel.md`](adr/0021-especie-canonica-linha-b-inviavel.md) |
| **ADR 0022 / BLOQUEIO_FINAL** | Bloqueio **terminal** do pilar 1 (hipótese A/B) no protótipo/gate atuais; critérios de reabertura | [`adr/0022-bloqueio-final-hipotese-ab.md`](adr/0022-bloqueio-final-hipotese-ab.md) |
| **`esp_sfs` / path metal** | GGUF via SimpleFileSystem/ESP — **≠** BlockIO | ADR [`0017`](adr/0017-path-metal-sfs-vs-blockio.md) |
| **`esp_sfs_full`** | Loader SFS full (E63); ≠ `blockio_full` / ≠ só `esp_header` | [`gguf-path-metal-io.md`](gguf-path-metal-io.md) |
| **`B_BLOCK_METAL`** | Bloqueio honesto no path metal (ex. `no_gguf_metal_io` E48) | [`gguf-path-metal-io.md`](gguf-path-metal-io.md) / E48 |
| **`sym_cpu`** | Harness A+B com `ACCEL=cpu` (mesmo perfil; E64) | [`harness-perfis-a-otimizada-gpu.md`](harness-perfis-a-otimizada-gpu.md) / ADR [`0023`](adr/0023-simetria-gpu-harness-inviavel.md) |
| **ADR 0023** | Simetria GPU A/B inviável até passthrough (B60); E56 = assimétrico | [`adr/0023-simetria-gpu-harness-inviavel.md`](adr/0023-simetria-gpu-harness-inviavel.md) |
| **`NET_GUEST_BLOCK`** | Bloqueio TCP Rede no guest (E66: `no_tcp_post_exit`) | [`rede-tcp-guest.md`](rede-tcp-guest.md) / ADR [`0024`](adr/0024-tcp-rede-guest-inviavel.md) |
| **ADR 0024** | TCP Rede guest pós-Exit inviável (UART-only); bridge E52 canônica | [`adr/0024-tcp-rede-guest-inviavel.md`](adr/0024-tcp-rede-guest-inviavel.md) |
