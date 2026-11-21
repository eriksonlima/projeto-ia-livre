# Guia do usuário — IA Livre Linux

Produto final (ADR 0027): SO TTY-first com runtime, agente e Rede.

## 1. QEMU (rápido)

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
./scripts/fetch-model.sh          # pesos no host (opcional para ISO)
make stage-distro
./scripts/build-distro-debian-iso.sh
./scripts/run-distro-iso-qemu.sh  # UEFI/OVMF -cdrom
```

No guest: `ia-livre conf` / veja MOTD e `/etc/ia-livre/FIRST_BOOT.md`.

## 2. USB live

```bash
./scripts/prepare-linux-release.sh
./scripts/write-linux-usb.sh --mode iso --device /dev/sdX --confirm /dev/sdX --yes
```

Boot UEFI no PC. **≠** pendrive ESP da Linha B.

## 3. Primeira sessão

1. `ia-livre model list` — copie um `.gguf` para `/var/lib/ia-livre/models/`
2. `ia-livre model set …` / `ia-livre infer`
3. Opcional: `ia-livre-native-tune` (root para aplicar)
4. Rede: `ia-livre node …` ou `systemctl enable --now ia-livre-node` (opcional)
5. Agente: `ia-livre agent --prompt "…"`

## 4. Gates de confiança

`make verify-produto-linux` — checklist das métricas de produto.
