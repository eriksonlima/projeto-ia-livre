#!/usr/bin/env bash
# Gate Etapa 75: TOKENS medidos no caminho pós-exit do report (≠ COMPROVA).
set -euo pipefail
cd "$(dirname "$0")/.."

test -f docs/baremetal-report.md
grep -q 'TOKENS_PER_S_MILLI' docs/baremetal-report.md
grep -q '0026' docs/baremetal-report.md
grep -q 'post_push' kernel/src/baremetal_report.rs
grep -q 'TOKENS_PER_S_MILLI' kernel/src/main.rs
grep -q 'IA_LIVRE_BAREMETAL_REPORT_POST_OK' scripts/verify-boot.sh
# verify-boot já exige o numérico TOKENS no serial (pós-exit → entra no post buffer)
grep -q 'IA_LIVRE_RUNTIME_NATIVE_TOKENS_PER_S_MILLI=' scripts/verify-boot.sh

echo "IA_LIVRE_BAREMETAL_REPORT_TOKENS_OK"
echo "GATE_OK: report tokens — documentado no pós-exit; ≠ COMPROVA / comparable"
