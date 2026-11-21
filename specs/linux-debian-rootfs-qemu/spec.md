# Spec — Rootfs Debian mínimo bootável em QEMU (Etapa 82 / B77)

## Resultado visível

Imagem **Debian mínima** (rootfs) com o overlay `distro/` injetado, **bootável em QEMU** até prompt serial **ou** evidência de `ia-livre conf` no guest; gate documentado (`make verify-distro-debian-qemu` ou nome alinhado).

Contraste explícito com o smoke atual (Etapa 80): **≠** Alpine netboot best-effort/`DISTRO_QEMU_SKIP`. Quando as tools existem, o caminho preferido **prova boot Debian + overlay**; skip só se faltar ferramenta/rede (`need_mmdebstrap` / `need_net` / `need_qemu`) — honesto, sem fingir guest.

## Contexto fixo (não reinventar)

- Produto = Linux IA-nativo (ADR [`0027`](../../docs/adr/0027-produto-linux-ia-nativo.md)); Linha B UEFI arquivada.
- Já existe: `distro/overlay/`, `scripts/stage-distro-overlay.sh`, `scripts/pack-distro-rootfs.sh` (tar do overlay), `scripts/run-distro-smoke.sh` (userspace + Alpine QEMU best-effort).
- Contrato produto: [`docs/linux-ia-nativo.md`](../../docs/linux-ia-nativo.md).
- Sem meta `COMPROVA` A/B; sem `METAL_OK`; sem ISO/live USB (B80).
- B78 (smoke que **exige** boot da imagem) depende desta etapa; não antecipar o aperto do `verify-distro-smoke` Alpine nesta fatia.

## Decisão de desenho (única)

### Avaliação

| Opção | Resumo | Veredito |
|-------|--------|----------|
| **A** | `mmdebstrap` (preferido) ou `debootstrap` → rootfs Debian mínimo + inject overlay → disco/imagem QEMU + kernel/initrd do próprio rootfs (ou caminho documentado equivalente) → serial getty → gate com marcadores; skip `need_*` se tools/rede ausentes | **Escolhida** |
| **B** | Continuar só com Alpine netboot e declarar “QEMU OK” | **Rejeitada** — ≠ requisito B77 |
| **C** | Exigir ISO live/híbrida nesta etapa | **Rejeitada** — B80 |
| **D** | Boot obrigatório no CI sem mmdebstrap/rede (fail hard) | **Rejeitada** — não portátil; skip honesto permitido |
| **E** | Embutir GGUF ~638 MiB na imagem default do gate | **Rejeitada** — fetch documentado depois (B79); gate não exige inferência GGUF |

### Escolhida: **A**

| Peça | Escolha |
|------|---------|
| Base | Debian **stable** (ou suite documentada, ex. `bookworm`) **mínima** (sem desktop) |
| Build | Preferir **`mmdebstrap`**; fallback documentado `debootstrap` se o script detectar só este |
| Overlay | Stage + cópia/merge de `distro/overlay/` em `/` do rootfs (`/opt/ia-livre`, `/etc/ia-livre`, sysctl, etc.) |
| PATH guest | `ia-livre` utilizável (symlink em `/usr/local/bin` ou `PATH` de login/getty) |
| Console | QEMU `-nographic` + `console=ttyS0` + **getty serial** (systemd ou busybox/agetty no ttyS0) |
| Boot | Kernel+initrd do rootfs Debian **ou** `-kernel`/`-append` + root virtio/ext4 — documentar o modo escolhido |
| Artefato | Sob `build/` (ex. `build/distro-debian/` rootfs e/ou `.img`/qcow) — gitignored via `build/` |
| Gate | `make verify-distro-debian-qemu` → script verify que chama build (ou cache) + QEMU e exige marcadores de sucesso **ou** skip `need_*` |
| Sucesso | `IA_LIVRE_DISTRO_DEBIAN_QEMU_OK` (e artefato `…_ROOTFS_OK` / equivalente) + evidência de prompt **ou** saída de `ia-livre conf` no log serial |
| Skip | `IA_LIVRE_DISTRO_DEBIAN_SKIP=need_mmdebstrap\|need_net\|need_qemu` (exit 0); **proibido** reutilizar Alpine como sucesso desta etapa |
| Docs | Atualizar [`docs/linux-ia-nativo.md`](../../docs/linux-ia-nativo.md); pontes curtas em AGENTS se o gate entrar na superfície de verificação |

### Rejeitado (explícito)

- Contar Alpine netboot / `DISTRO_QEMU_SKIP` como prova desta etapa.
- ISO híbrida, live USB, writer B80/B81.
- `COMPROVA` / `METAL_OK` / harness A vs B.
- First-boot MOTD rico / fetch GGUF embutido (B79).
- Exigir GPU, multi-GPU ou inferência completa no guest para fechar o gate.
- Alterar `verify-distro-smoke` para falhar sem Debian (isso é B78).

## Fora de escopo

- ISO / live USB bootável (B80) e writer (B81).
- Aperto do smoke userspace para **exigir** `DISTRO_QEMU_OK` Debian (B78).
- First-boot TTY polish / MOTD / hints (B79).
- Unidades systemd de produto além do mínimo para getty/serial (B83).
- Custom kernel Linux / patches (etapas futuras).
- COMPROVA, METAL, Linha B como produto.

## Critérios de aceite

- [ ] Script(s) constroem rootfs Debian mínimo e injetam o overlay IA Livre.
- [ ] QEMU sobe a imagem com console serial; evidência de prompt **ou** `ia-livre conf` no guest.
- [ ] `ia-livre` no PATH do guest (ou caminho documentado equivalente no log).
- [ ] `make verify-distro-debian-qemu` (nome alinhado) documentado; sucesso emite `IA_LIVRE_DISTRO_DEBIAN_QEMU_OK` (e marcadores de artefato).
- [ ] Sem tools/rede: skip `need_mmdebstrap` / `need_net` / `need_qemu` — **sem** fingir boot; com tools: caminho preferido prova boot.
- [ ] `docs/linux-ia-nativo.md` descreve build + QEMU + gate; ≠ Alpine como prova.
- [ ] Sem ISO USB; sem COMPROVA/METAL.

## Riscos e rollback

| Risco | Mitigação |
|-------|-----------|
| mmdebstrap/rede ausentes no CI | Skip `need_*` exit 0; doc deixa claro que prova completa é local/com tools |
| Build lento / grande | Suite mínima; cache em `build/`; timeout documentado no verify |
| Getty serial não aparece | Pacotes `systemd`/`util-linux` + append `console=ttyS0`; timeout QEMU generoso o bastante |
| Overlay quebra PATH | Symlink explícito `/usr/local/bin/ia-livre` → `/opt/ia-livre/bin/ia-livre` |
| Confusão com Alpine smoke | Marcadores e gate **novos**; docs dizem que E80 Alpine ≠ E82 |

Rollback: remover scripts/gate novos; `verify-distro-smoke` permanece intacto.

## Etapa do roadmap

- Etapa **82** — Rootfs Debian mínimo bootável em QEMU  
- Issue: [#83](https://github.com/eriksonlima/projeto-ia-livre/issues/83) (B77)  
- Spec: `specs/linux-debian-rootfs-qemu/`  
- Pronto quando: boot QEMU até prompt ou `ia-livre conf` no guest; gate documentado; ≠ Alpine netboot skip.
