#!/usr/bin/env bash
# Gate Etapa 96 / B91 — aceite produto Linux (métricas ADR 0027).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"

test -f docs/produto-linux-checklist.md
test -f docs/guia-usuario-ia-livre-linux.md
test -f docs/adr/0027-produto-linux-ia-nativo.md

# Subgates (já existentes) — falha se script ausente
need_make() { grep -q "^$1:" Makefile || { echo "GATE_FAIL: falta target $1"; exit 1; }; }
need_make verify-distro-debian-qemu
need_make verify-distro-iso
need_make verify-linux-usb-artifact
need_make verify-distro-net
need_make verify-distro-agent
need_make verify-distro-tune-advanced
need_make verify-kernel-linux-ia
need_make verify-distro-first-boot

# Rodar subgates leves + os que podem skip
chmod +x scripts/verify-distro-first-boot.sh scripts/verify-distro-systemd.sh \
  scripts/verify-distro-gpu-optional.sh scripts/verify-distro-tune-advanced.sh \
  scripts/verify-kernel-linux-ia.sh scripts/verify-distro-net.sh \
  scripts/verify-distro-agent.sh 2>/dev/null || true

./scripts/verify-distro-first-boot.sh
./scripts/verify-distro-systemd.sh
./scripts/verify-distro-gpu-optional.sh
./scripts/verify-distro-tune-advanced.sh
./scripts/verify-kernel-linux-ia.sh
./scripts/verify-distro-net.sh
./scripts/verify-distro-agent.sh

# ISO/QEMU/debian: caros — aceitar se já passaram nesta máquina ou rodar
if [[ "${VERIFY_PRODUTO_LINUX_SKIP_HEAVY:-0}" == "1" ]]; then
  echo "IA_LIVRE_PRODUTO_LINUX_HEAVY=skipped"
  test -f scripts/verify-distro-iso.sh
  test -f scripts/verify-distro-debian-qemu.sh
else
  make verify-linux-usb-artifact
  # Reusa caches; QEMU ~3–4 min cada
  make verify-distro-debian-qemu
  make verify-distro-iso
fi

grep -q 'B84\|smoke Rede\|guia-usuario\|PRODUTO_LINUX' docs/product-context.md \
  || grep -q 'guia-usuario-ia-livre-linux\|produto-linux-checklist' docs/product-context.md

echo "IA_LIVRE_PRODUTO_LINUX_OK"
echo "GATE_OK: produto Linux — checklist 4 métricas + subgates"
exit 0
