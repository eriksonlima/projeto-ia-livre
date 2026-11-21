#!/usr/bin/env bash
# Gate Etapa 93–94 / B88–B89 — ADR + defconfig doc; boot custom deferred honesto.
set -euo pipefail
cd "$(dirname "$0")/.."

test -f docs/adr/0028-kernel-linux-ia-nativo.md
test -f docs/kernel-linux-ia-nativo.md
grep -q 'CONFIG_HUGETLBFS' docs/kernel-linux-ia-nativo.md
grep -q 'stock Debian\|deferred\|OUTCOME' docs/adr/0028-kernel-linux-ia-nativo.md \
  || grep -q 'stock' docs/kernel-linux-ia-nativo.md

# Boot custom: não exigido no CI — outcome honesto
echo "IA_LIVRE_KERNEL_LINUX_OUTCOME=adr_0028_deferred_stock_kernel"
echo "IA_LIVRE_KERNEL_LINUX_OK"
echo "GATE_OK: kernel Linux IA — ADR 0028 + defconfig doc (boot custom deferred)"
exit 0
