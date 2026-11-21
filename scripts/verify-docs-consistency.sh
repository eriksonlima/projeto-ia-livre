#!/usr/bin/env bash
# Gate documental: consistência architecture/product/glossário/README (E42 + E72).
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

# Âncoras históricas + pós-E58
grep -q 'no_gguf_full_prefill\|BLOQUEIO_FINAL' docs/architecture.md || {
  echo "GATE_FAIL: architecture sem âncora hipótese/bloqueio"
  fail=1
}
grep -q 'BLOQUEIO_FINAL' docs/architecture.md || {
  echo "GATE_FAIL: architecture sem BLOQUEIO_FINAL"
  fail=1
}
grep -q 'pós-E71\|pos-E71\|pós-E7' docs/architecture.md || {
  echo "GATE_FAIL: architecture mapa ainda não pós-E71"
  fail=1
}
# Não listar REPL como aberto
if grep -E 'REPL.*aberto|REPL/\`read_local\` \*\*abertos\*\*|REPL/\`read_local\` \*\*abertos' docs/architecture.md; then
  echo "GATE_FAIL: architecture ainda marca REPL/read_local como abertos"
  fail=1
fi
if grep -q 'DHT/NAT/relay \*\*abertos\*\*' docs/architecture.md; then
  echo "GATE_FAIL: architecture ainda marca relay como aberto genérico"
  fail=1
fi
if grep -q 'Estado do mapa (pós-E41)' docs/architecture.md; then
  echo "GATE_FAIL: architecture ainda diz mapa pós-E41"
  fail=1
fi

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
grep -q 'REPL' docs/glossario.md || {
  echo "GATE_FAIL: glossario sem REPL"
  fail=1
}
grep -q 'read_local' docs/glossario.md || {
  echo "GATE_FAIL: glossario sem read_local"
  fail=1
}
grep -q 'mDNS' docs/glossario.md || {
  echo "GATE_FAIL: glossario sem mDNS"
  fail=1
}
grep -q 'KNOW' docs/glossario.md || {
  echo "GATE_FAIL: glossario sem KNOW"
  fail=1
}
grep -q 'host_multi' docs/glossario.md || {
  echo "GATE_FAIL: glossario sem host_multi"
  fail=1
}
grep -q 'ABI_VERSION\|ABI_OK' docs/glossario.md || {
  echo "GATE_FAIL: glossario sem ABI"
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
grep -q 'BLOQUEIO_FINAL' docs/product-context.md || {
  echo "GATE_FAIL: product-context sem BLOQUEIO_FINAL"
  fail=1
}
grep -q 'REPL\|read_local' docs/product-context.md || {
  echo "GATE_FAIL: product-context sem REPL/read_local"
  fail=1
}
grep -q 'NATIVE_CONSUME\|ABI' docs/product-context.md || {
  echo "GATE_FAIL: product-context sem NATIVE_CONSUME/ABI"
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
echo "GATE_OK: docs consistency (architecture/product/glossário/README; pós-E71)"
exit 0
