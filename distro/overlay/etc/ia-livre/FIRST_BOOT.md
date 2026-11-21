# First-boot — IA Livre Linux

1. PATH já inclui `/opt/ia-livre/bin` (via `/etc/profile.d/ia-livre.sh`).
2. **Não** há GGUF embutido no artefato default (~638 MiB). Obtenha um modelo:
   - No host de build: `./scripts/fetch-model.sh` e copie para `/var/lib/ia-livre/models/`
   - Ou baixe qualquer `.gguf` e: `ia-livre model set meu-modelo.gguf`
3. Comandos:
   - `ia-livre model list`
   - `ia-livre infer`
   - `ia-livre-native-tune` (sysctl/governor; root para aplicar)
4. Incluir GGUF na imagem Debian de lab: `IA_LIVRE_DEBIAN_INCLUDE_GGUF=1 ./scripts/build-distro-debian-rootfs.sh`
