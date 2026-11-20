#!/usr/bin/env bash
# Harness Linha B (Etapa 9): stub até existir runtime nativo no IA Livre.
# Não inventa números; não usa ia-livre-runtime no host (isso seria Linha A).
set -euo pipefail
cd "$(dirname "$0")/.."

echo "IA_LIVRE_HARNESS_LINE=B"
echo "IA_LIVRE_HARNESS_B_SKIP"
echo "motivo: runtime nativo no IA Livre ainda não existe; boot UEFI sem inferência não conta como Linha B."
echo "contrato: docs/harness-linha-a-b.md — quando B existir, emitir IA_LIVRE_HARNESS_* com LINE=B + HARNESS_OK na mesma carga canônica."
exit 0
