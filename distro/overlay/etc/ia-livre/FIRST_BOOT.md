# First-boot — IA Livre Linux

## Login (live / USB)

| Campo | Valor |
|-------|--------|
| Usuário | `ialivre` |
| Senha | `ialivre` |
| Hostname | `ialivre` |

Autologin no TTY1 (e na serial) costuma entrar sozinho. Se pedir login, use a tabela acima.  
`sudo` sem senha para este usuário (lab TTY-first). Root também usa a senha `ialivre`.

Editores no TTY: `nano` e `vi` (vim-tiny).

## Rede / Wi‑Fi

`model fetch` e `apt` precisam de internet.

```bash
sudo ia-livre wifi status          # iface down? rfkill?
sudo ia-livre wifi up              # rfkill unblock + ip link set up
sudo ia-livre wifi scan
sudo ia-livre wifi connect "SSID"  # pede senha; DHCP
```

Se a interface wireless **não aparece**: driver/firmware do chip (a imagem inclui firmwares comuns Intel/Realtek/Atheros/Broadcom). Veja `dmesg | grep -i firmware`.

Ethernet: `sudo dhclient eth0` (ou o nome em `ip -br link`).

## Modelos

A ISO **default não traz** GGUF (~638 MiB) — economiza espaço no pendrive.

Com rede no live:

```bash
ia-livre model catalog
ia-livre model fetch tinyllama   # ou: phi2 | qwen25-05b | smollm2-360 | …
ia-livre infer
```

Sem rede no live: copie um `.gguf` de outro PC (pendrive/scp) para `/var/lib/ia-livre/models/` e:

```bash
ia-livre model set meu.gguf
ia-livre infer
```

Lab com pesos já na ISO: `IA_LIVRE_DEBIAN_INCLUDE_GGUF=1` no build do host.
