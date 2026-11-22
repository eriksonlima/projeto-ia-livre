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

Gere a ISO **sem** sudo; só o `dd` precisa de root (`sudo` limpa o PATH e quebra o `cargo`):

```bash
./scripts/build-distro-debian-iso.sh   # ou: ./scripts/prepare-linux-release.sh
sudo ./scripts/write-linux-usb.sh --mode iso --device /dev/sdX --confirm /dev/sdX --yes
```

Se a ISO já existir (`build/distro-debian/ia-livre-linux.iso`), o writer só faz `dd` — não rebuilda.

Boot UEFI no PC. **≠** pendrive ESP da Linha B.

## 3. Primeira sessão

**Login:** usuário `ialivre` · senha `ialivre` (autologin no TTY1). `sudo` sem senha.

1. Modelo: a ISO **não** traz GGUF. Com rede: `ia-livre model fetch` (TinyLlama ~638 MiB) ou `curl` de qualquer `.gguf` + `ia-livre model set …`
2. `ia-livre infer`
3. Opcional: `sudo ia-livre-native-tune`
4. Rede: `ia-livre node …` ou `sudo systemctl enable --now ia-livre-node`
5. Agente: `ia-livre agent --prompt "…"`

## 4. Gates de confiança

`make verify-produto-linux` — checklist das métricas de produto.
