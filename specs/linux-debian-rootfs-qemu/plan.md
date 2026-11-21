# Plan — Rootfs Debian mínimo bootável em QEMU (Etapa 82)

## Abordagem

1. **Build rootfs Debian** com `mmdebstrap` (preferido) ou `debootstrap` fallback: suite estável mínima, pacotes para boot serial (kernel/image se empacotado no rootfs, `systemd`/`util-linux` para getty em `ttyS0`). Saída sob `build/distro-debian/` (rootfs dir e/ou imagem de bloco).
2. **Inject overlay**: rodar `stage-distro-overlay` (ou reutilizar artefato) e copiar `distro/overlay/` para o rootfs; garantir `ia-livre` no PATH (`/usr/local/bin` → `/opt/ia-livre/bin/ia-livre`).
3. **Boot QEMU**: runner que sobe a imagem com `-nographic`, serial, root virtio/ext4 (ou modo documentado); captura log; busca prompt **ou** executa/observa `ia-livre conf` (expect/`-serial`/`-smbios`/init one-shot — escolher o mais simples e estável).
4. **Gate**: `scripts/verify-distro-debian-qemu.sh` + alvo Make; sucesso → `IA_LIVRE_DISTRO_DEBIAN_QEMU_OK`; faltando tool/rede → `IA_LIVRE_DISTRO_DEBIAN_SKIP=need_*` exit 0. **Não** alterar o critério Alpine do `verify-distro-smoke`.
5. **Docs**: seção em `docs/linux-ia-nativo.md`; pontes AGENTS/README só se a superfície pública exigir o novo gate.

## Arquivos prováveis

- `scripts/build-distro-debian-rootfs.sh` — mmdebstrap/debootstrap + inject overlay + artefato
- `scripts/run-distro-debian-qemu.sh` — QEMU serial + prova prompt/`ia-livre conf`
- `scripts/verify-distro-debian-qemu.sh` — gate
- `Makefile` — alvo `verify-distro-debian-qemu` (+ opcional `distro-debian` / `build-distro-debian`)
- `docs/linux-ia-nativo.md` — build, boot, gate, skip
- `AGENTS.md` — entrada curta do gate (se couber na superfície de verificação)
- `build/distro-debian/` — artefatos (já gitignored via `build/`)
- Reuso: `scripts/stage-distro-overlay.sh`, `distro/overlay/`

## Dependências

- Host: `mmdebstrap` **ou** `debootstrap`; `qemu-system-x86_64`; rede na 1ª build (espelho Debian)
- Etapas feitas: E77–E81 (overlay, pack, smoke userspace, USB artefato)
- ADR 0027
- **Não** depende de B78–B80 (sucessores)

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
# Com tools:
make verify-distro-debian-qemu
# Esperado: IA_LIVRE_DISTRO_DEBIAN_QEMU_OK (+ marcador de rootfs/artefato)
# Sem mmdebstrap/rede/qemu:
# IA_LIVRE_DISTRO_DEBIAN_SKIP=need_mmdebstrap|need_net|need_qemu  (exit 0)
```

Checks específicos:

- Log QEMU **não** conta Alpine netboot como sucesso.
- Guest: prompt serial **ou** linha compatível com `ia-livre conf` / `MODEL=` (ou marcador `IA_LIVRE_DISTRO_DEBIAN_CONF_OK`).
- `verify-distro-smoke` permanece independente (regressão: não quebrar).

## Ordem das fatias

Ver `tasks.md`: (1) build+inject → (2) QEMU runner prova → (3) gate+docs.
