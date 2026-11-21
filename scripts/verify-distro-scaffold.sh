#!/usr/bin/env bash
# Gate scaffold Linux IA-nativo (Etapa 77 / B72). Sem imagem QEMU completa (B75).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
if [[ -z "${BINDGEN_EXTRA_CLANG_ARGS:-}" ]]; then
  export BINDGEN_EXTRA_CLANG_ARGS="-I/usr/lib/gcc/x86_64-linux-gnu/13/include -I/usr/include"
fi

fail=0
for f in \
  docs/adr/0027-produto-linux-ia-nativo.md \
  docs/linux-ia-nativo.md \
  distro/README.md \
  distro/overlay/etc/ia-livre/ia-livre.conf \
  distro/overlay/opt/ia-livre/bin/ia-livre \
  scripts/stage-distro-overlay.sh
do
  if [[ ! -f "$f" ]]; then
    echo "GATE_FAIL: ausente $f"
    fail=1
  fi
done

grep -q 'Linux IA-nativo' docs/adr/0027-produto-linux-ia-nativo.md || fail=1
grep -q 'arquivada' docs/adr/0027-produto-linux-ia-nativo.md || fail=1
grep -q 'IA_LIVRE_MODEL' distro/overlay/etc/ia-livre/ia-livre.conf || fail=1
grep -q '0027' docs/product-context.md || fail=1
grep -q '0027' docs/architecture.md || fail=1

chmod +x distro/overlay/opt/ia-livre/bin/ia-livre scripts/stage-distro-overlay.sh

./scripts/stage-distro-overlay.sh

test -x distro/overlay/opt/ia-livre/bin/ia-livre-runtime || fail=1
test -x distro/overlay/opt/ia-livre/bin/ia-livre-agent || fail=1
test -x distro/overlay/opt/ia-livre/bin/ia-livre-node || fail=1

out="$(./distro/overlay/opt/ia-livre/bin/ia-livre conf 2>&1)" || fail=1
echo "$out" | grep -q 'MODEL=' || fail=1

# Infer smoke se GGUF estiver no overlay
MODEL_OVERLAY=distro/overlay/var/lib/ia-livre/models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
if [[ -f "$MODEL_OVERLAY" ]]; then
  if ./distro/overlay/opt/ia-livre/bin/ia-livre infer --n-predict 8 \
    > /tmp/ia-livre-distro-infer.log 2>&1 \
    && grep -q 'IA_LIVRE_INFER_OK' /tmp/ia-livre-distro-infer.log; then
    echo "IA_LIVRE_DISTRO_INFER_OK"
  else
    echo "GATE_FAIL: infer no overlay sem IA_LIVRE_INFER_OK"
    tail -n 30 /tmp/ia-livre-distro-infer.log || true
    fail=1
  fi
else
  echo "IA_LIVRE_DISTRO_INFER_SKIP=no_gguf"
fi

if (( fail )); then
  exit 1
fi

echo "IA_LIVRE_DISTRO_SCAFFOLD_OK"
echo "GATE_OK: distro scaffold — ADR 0027 + overlay + binários (≠ ISO live; ≠ UEFI)"
exit 0
