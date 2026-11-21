# Linux IA-nativo (produto — ADR 0027)

SO canônico do Projeto IA Livre: **Debian mínimo TTY-first** + stack do repo, afinado para LLM.  
Linha B UEFI = lab arquivado.

## Layout (scaffold)

| Path | Papel |
|------|--------|
| `/etc/ia-livre/ia-livre.conf` | Config (modelo, n_predict, accel) |
| `/var/lib/ia-livre/models/` | GGUF (qualquer arquivo; default TinyLlama se presente) |
| `/opt/ia-livre/bin/` | `ia-livre-runtime`, `ia-livre-agent`, `ia-livre-node` |
| `/opt/ia-livre/bin/ia-livre` | Wrapper que lê a config |

No repo, o overlay vive em [`distro/overlay/`](../distro/overlay/).

## Stage (host de desenvolvimento)

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
./scripts/stage-distro-overlay.sh
# Opcional: copiar GGUF
./scripts/fetch-model.sh
cp -n models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf distro/overlay/var/lib/ia-livre/models/
```

## Uso rápido no overlay (sem imagem completa ainda)

```bash
./distro/overlay/opt/ia-livre/bin/ia-livre infer
./distro/overlay/opt/ia-livre/bin/ia-livre agent --prompt "olá"
```

Gate do scaffold: `make verify-distro-scaffold` → `IA_LIVRE_DISTRO_SCAFFOLD_OK`.

Imagem live QEMU / USB: etapas seguintes (B75/B76).
