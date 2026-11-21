# GPU opcional — Linux IA Livre

A imagem default é **CPU**. GPU é opt-in no host/imagem:

1. Build runtime com feature: `cargo build -p ia-livre-runtime --release --features cuda` (ou `vulkan`)
2. Stage: substitua `ia-livre-runtime` no overlay e regenere ISO se desejar
3. Config: `IA_LIVRE_N_GPU_LAYERS=99` em `/etc/ia-livre/ia-livre.conf`

Sem GPU / CI: skip honesto (`IA_LIVRE_DISTRO_GPU_SKIP=need_gpu`) — **não** finge aceleração.

Gate: `make verify-distro-gpu-optional`.
