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
make verify-distro-smoke   # userspace + QEMU Debian (E83; ≠ Alpine)
```

## Debian rootfs bootável em QEMU (Etapa 82)


Prova de produto: **Debian mínimo** + overlay, boot QEMU (9p) — **≠** Alpine netboot do smoke E80.

```bash
# Requer mmdebstrap no PATH **ou** Docker; + qemu-system-x86_64
./scripts/build-distro-debian-rootfs.sh   # → build/distro-debian/rootfs + ROOTFS_OK
./scripts/run-distro-debian-qemu.sh       # → DISTRO_DEBIAN_QEMU_OK (ou SKIP need_*)
make verify-distro-debian-qemu
```

Skip honesto: `need_mmdebstrap` / `need_net` / `need_qemu` / `boot_fail` / `no_console` (exit 0).  
Sucesso: `IA_LIVRE_DISTRO_DEBIAN_QEMU_OK` + conf guest ou prompt Debian.

## First-boot TTY (Etapa 84)

- MOTD: `/etc/motd`
- PATH: `/etc/profile.d/ia-livre.sh`
- Guia: `/etc/ia-livre/FIRST_BOOT.md` (fetch de **qualquer** GGUF; artefato default **sem** pesos)
- Build Debian sem GGUF: default; lab com pesos: `IA_LIVRE_DEBIAN_INCLUDE_GGUF=1`
- Gate: `make verify-distro-first-boot`

## ISO híbrida / live (Etapa 85)

Artefato **bootável** (≠ tarball E81; ≠ ESP UEFI):

```bash
./scripts/build-distro-debian-iso.sh   # → build/distro-debian/ia-livre-linux.iso
./scripts/run-distro-iso-qemu.sh       # QEMU -cdrom
make verify-distro-iso
```

Requer `mksquashfs`, `grub-mkrescue`, `xorriso`, `mformat` (mtools) (+ Docker para `live-boot` se preciso).  
QEMU prova com **UEFI/OVMF** (`-cdrom`); SeaBIOS costuma falhar El Torito nesta ISO. Skip `need_*` / `boot_fail` honesto.

## Systemd opcional (Etapa 88)

Units `ia-livre-node.service` / `ia-livre-agent.service` no overlay — **disabled** por default.  
Ver `/etc/ia-livre/SYSTEMD.md`. Gate: `make verify-distro-systemd`.

## Release packaging (Etapa 87)

```bash
./scripts/prepare-linux-release.sh   # → build/release-linux/ + SHA256SUMS
make verify-linux-release
```

ISO no pacote **sem** GGUF default (`IA_LIVRE_DEBIAN_INCLUDE_GGUF=0`). ≠ `prepare-baremetal-release` (ESP).

## USB Linux

Ver [`docs/guia-ia-livre-linux-usb.md`](guia-ia-livre-linux-usb.md) (tarball E81 + ISO E85 — distinto do ESP UEFI).
