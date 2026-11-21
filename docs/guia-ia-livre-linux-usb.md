# Guia — USB do SO Linux IA Livre

**Distinto** do pendrive ESP UEFI (Linha B arquivada). Este guia é o caminho de **produto** (ADR 0027).

## Estado atual (honesto)

1. Scaffold + rootfs overlay empacotável: `make stage-distro` / `./scripts/pack-distro-rootfs.sh` → `build/ia-livre-distro-rootfs.tar.gz`
2. Smoke: `make verify-distro-smoke` (userspace + QEMU Alpine best-effort)
3. **Imagem live/instalável Debian completa** ainda evolui — o writer abaixo prepara um pendrive com o **tarball + README** para extrair numa instalação Debian mínima, ou documenta o fluxo até haver ISO.

## Preparar artefato

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
./scripts/fetch-model.sh   # opcional mas recomendado
./scripts/pack-distro-rootfs.sh
./scripts/prepare-linux-usb-artifact.sh
# → build/linux-usb/ com tar + README + SHA256SUMS
```

## Gravar pendrive (operador)

```bash
./scripts/write-linux-usb.sh --list
./scripts/write-linux-usb.sh --device /dev/sdX --confirm /dev/sdX --yes
```

Isso formata uma partição FAT/ext4 **só com confirmação explícita** e copia o artefato (não é o writer ESP UEFI).

## No PC alvo

1. Instale Debian mínimo TTY (ou use live Debian).
2. Monte o pendrive; extraira `ia-livre-distro-rootfs.tar.gz` em `/` (ou mescle `/opt/ia-livre`, `/etc/ia-livre`, `/var/lib/ia-livre`).
3. `ia-livre model list` / `ia-livre infer` / `ia-livre-native-tune`

## Gates

| Gate | O quê |
|------|--------|
| `make verify-distro-scaffold` | Overlay + infer |
| `make verify-distro-config-models` | model set/list |
| `make verify-distro-native-tune` | tuning |
| `make verify-distro-smoke` | rootfs + smoke |
| `make verify-linux-usb-artifact` | artefato USB (sem device) |
