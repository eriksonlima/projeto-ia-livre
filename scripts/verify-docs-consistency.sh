#!/usr/bin/env bash
# Gate documental Etapa 42 — consistência architecture/product/glossário/README.
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0
need() {
  local f="$1"
  if [[ ! -f "$f" ]]; then
    echo "GATE_FAIL: ausente $f"
    fail=1
  fi
}

need docs/glossario.md
need docs/architecture.md
need docs/product-context.md
need README.md

grep -q 'no_gguf_full_prefill' docs/architecture.md || {
  echo "GATE_FAIL: architecture sem no_gguf_full_prefill"
  fail=1
}
grep -qi 'bare-metal\|bare metal' docs/glossario.md || {
  echo "GATE_FAIL: glossario sem âncora bare-metal"
  fail=1
}
grep -q 'INCONCLUSIVO' docs/glossario.md || {
  echo "GATE_FAIL: glossario sem Veredito/INCONCLUSIVO"
  fail=1
}
grep -q 'runtime-native' docs/glossario.md || {
  echo "GATE_FAIL: glossario sem runtime-native"
  fail=1
}
grep -q 'BAREMETAL_SKIP\|BAREMETAL' docs/glossario.md || {
  echo "GATE_FAIL: glossario sem BAREMETAL_SKIP"
  fail=1
}
grep -q 'glossario.md' README.md || {
  echo "GATE_FAIL: README sem ponte glossario"
  fail=1
}
grep -q 'INCONCLUSIVO' docs/product-context.md || {
  echo "GATE_FAIL: product-context sem INCONCLUSIVO"
  fail=1
}
if grep -q 'Implementação continua aberta' docs/architecture.md; then
  echo "GATE_FAIL: architecture ainda diz Implementação continua aberta"
  fail=1
fi
if grep -q 'Fronteira com Etapas 4+' docs/architecture.md; then
  echo "GATE_FAIL: architecture ainda tem Fronteira Etapa 3/4 obsoleta"
  fail=1
fi

if (( fail )); then
  exit 1
fi

echo "IA_LIVRE_CONSISTENCY_OK"
echo "GATE_OK: docs consistency (architecture/product/glossario/README)"
exit 0
