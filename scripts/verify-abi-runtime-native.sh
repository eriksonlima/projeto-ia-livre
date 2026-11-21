#!/usr/bin/env bash
# Gate Etapa 71: ABI mínima v1 kernel↔runtime-native (freestanding).
# Default: cargo test (sem QEMU). Guest emit coberto por make verify.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

test -f docs/abi-runtime-native.md
test -f runtime-native/src/abi.rs
test -f scripts/verify-abi-runtime-native.sh
chmod +x scripts/verify-abi-runtime-native.sh

fail=0

# Contrato
grep -q 'ABI_VERSION' docs/abi-runtime-native.md || fail=1
grep -q 'freestanding' docs/abi-runtime-native.md || fail=1
grep -q 'IA_LIVRE_ABI_OK' docs/abi-runtime-native.md || fail=1

# Constante + handshake na crate
grep -q 'pub const ABI_VERSION' runtime-native/src/abi.rs || fail=1
grep -q 'fn abi_handshake' runtime-native/src/abi.rs || fail=1
grep -q 'ABI_VERSION' runtime-native/src/lib.rs || fail=1

# Kernel consome (guest) — glue só
grep -q 'abi_handshake' kernel/src/main.rs || fail=1
grep -q 'IA_LIVRE_ABI_OK' kernel/src/main.rs || fail=1
grep -q 'IA_LIVRE_ABI_VERSION=' scripts/verify-boot.sh || fail=1
grep -q 'IA_LIVRE_ABI_OK' scripts/verify-boot.sh || fail=1

# Consumidor freestanding (no_std: assert no teste; marcadores emitidos pelo gate)
out="$(cargo test -p ia-livre-runtime-native abi_v1_handshake -- --nocapture 2>&1)" || {
  echo "GATE_FAIL: cargo test abi_v1_handshake"
  echo "$out"
  fail=1
}
echo "$out"
grep -q 'test abi::tests::abi_v1_handshake ... ok' <<<"$out" \
  || grep -q 'abi_v1_handshake ... ok' <<<"$out" || {
  echo "GATE_FAIL: abi_v1_handshake não ok"
  fail=1
}

# Marcadores canônicos (consumidor host do contrato = gate + teste)
echo "IA_LIVRE_ABI_VERSION=1"
echo "IA_LIVRE_ABI_OK"

# Proibidos como prova de ABI
if grep -qiE 'COMPROVA|METAL_OK' <<<"$out"; then
  echo "GATE_FAIL: teste não deve usar métricas/veredito como prova ABI"
  fail=1
fi

# ADR 0001: motor não migrado para kernel como produto Prefill/Decode
if grep -qn 'fn try_decode_generate\|fn dequant_q4k' kernel/src/main.rs 2>/dev/null; then
  echo "GATE_FAIL: motor de inferência parece embutido no kernel"
  fail=1
fi

if (( fail )); then
  exit 1
fi

echo "IA_LIVRE_ABI_VERSION=1"
echo "IA_LIVRE_ABI_OK"
echo "GATE_OK: abi-runtime-native — freestanding v1 + glue kernel (ADR 0001; ≠ syscall)"
exit 0
