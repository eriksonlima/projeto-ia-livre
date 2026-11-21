#!/usr/bin/env bash
# Gate Etapa 58: checklist "protótipo objetivo atingido" presente e honesto.
# Não exige COMPROVA, USB, QEMU nem GGUF.
set -euo pipefail
cd "$(dirname "$0")/.."

DOC=docs/prototipo-objetivo-atingido.md
test -f "$DOC"

fail=0
for needle in \
  'Hipótese A vs B' \
  'INCONCLUSIVO' \
  'verify-node' \
  'verify-agent' \
  'METAL_OK' \
  'Celebrar só com evidência' \
  'ADR 0001'
do
  if ! grep -q "$needle" "$DOC"; then
    echo "GATE_FAIL: checklist sem: $needle"
    fail=1
  fi
done

# Três pilares nomeados
grep -q 'Pilar 1' "$DOC" || fail=1
grep -q 'Pilar 2' "$DOC" || fail=1
grep -q 'Pilar 3' "$DOC" || fail=1

# Não fingir COMPROVA como estado atual
if grep -qiE 'Estado atual.*COMPROVA|hipótese.*(comprovada|COMPROVA)' "$DOC" \
  && ! grep -q 'INCONCLUSIVO' "$DOC"; then
  echo "GATE_FAIL: checklist não deve fingir COMPROVA sem INCONCLUSIVO"
  fail=1
fi

# Glossário
if [[ -f docs/glossario.md ]]; then
  grep -qi 'protótipo objetivo' docs/glossario.md \
    || grep -qi 'prototipo-objetivo' docs/glossario.md \
    || { echo "GATE_FAIL: glossário sem entrada protótipo objetivo"; fail=1; }
fi

if (( fail )); then
  exit 1
fi

echo "IA_LIVRE_PROTOTIPO_OBJETIVO_OK"
echo "GATE_OK: prototipo-objetivo — checklist canônico presente (Etapa 58; sem fingir COMPROVA)"
exit 0
