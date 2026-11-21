# Plan — E83

1. `run-distro-smoke.sh`: após userspace, chamar `run-distro-debian-qemu.sh`; emitir `DISTRO_QEMU_OK` ou skip.
2. Remover Alpine como prova de QEMU (opcional: manter só como nota histórica removida).
3. `verify-distro-smoke.sh`: exigir `DISTRO_QEMU_OK` **ou** `DISTRO_QEMU_SKIP=need_*`.
4. Docs + ROADMAP.
