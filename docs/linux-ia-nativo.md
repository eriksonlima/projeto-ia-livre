# Linux IA-nativo (produto — ADR 0027)

SO canônico do Projeto IA Livre: **Debian mínimo TTY-first** + stack do repo, afinado para LLM.  
Linha B UEFI = lab arquivado.

## Layout

| Path | Papel |
|------|--------|
| `/etc/ia-livre/ia-livre.conf` | Config (`IA_LIVRE_MODEL`, `n_predict`, GPU layers) |
| `/etc/sysctl.d/99-ia-livre-native.conf` | Tuning default (swappiness, cache) |
| `/var/lib/ia-livre/models/` | **Qualquer** `.gguf` |
| `/opt/ia-livre/bin/` | runtime, agent, node, wrappers |

Overlay no repo: [`distro/overlay/`](../distro/overlay/).

## Trocar modelo (qualquer GGUF)

```bash
make stage-distro
cp /caminho/outro-modelo.gguf distro/overlay/var/lib/ia-livre/models/
./distro/overlay/opt/ia-livre/bin/ia-livre model list
./distro/overlay/opt/ia-livre/bin/ia-livre model set outro-modelo.gguf
./distro/overlay/opt/ia-livre/bin/ia-livre infer
```

No SO instalado: mesmos comandos com paths `/var/lib/...` e `/opt/...`.

## Tuning nativo

```bash
./distro/overlay/opt/ia-livre/bin/ia-livre-native-tune
# Com root no SO: aplica governor performance + sysctl (best-effort; SKIP se sem permissão)
```

Alinhado ao espírito do harness `A_otimizada` (threads/governor) — **≠** prova A/B.

## Stage e smoke

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
./scripts/fetch-model.sh
make stage-distro
make verify-distro-scaffold
make verify-distro-config-models
make verify-distro-native-tune
make verify-distro-smoke
```

## USB Linux

Ver [`docs/guia-ia-livre-linux-usb.md`](guia-ia-livre-linux-usb.md) (imagem/rootfs — distinto do ESP UEFI).
