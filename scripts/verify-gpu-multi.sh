#!/usr/bin/env bash
# Gate Etapa 69: host_multi dual place OU skip need_2_devices. ≠ E41 shard.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

test -f docs/multi-gpu-completo-host.md
test -f scripts/run-gpu-multi-host.sh
chmod +x scripts/run-gpu-multi-host.sh

out="$(./scripts/run-gpu-multi-host.sh 2>&1)" || {
  echo "GATE_FAIL: runner exit ≠ 0"
  echo "$out"
  exit 1
}
echo "$out"

fail=0
grep -q 'IA_LIVRE_GPU_MGR=host_multi' <<<"$out" || fail=1

if grep -q 'IA_LIVRE_GPU_MULTI_EXEC_OK' <<<"$out"; then
  grep -q 'IA_LIVRE_GPU_MULTI_MODE=weights_kv_place' <<<"$out" || fail=1
  grep -q 'IA_LIVRE_GPU_MULTI_PLAN=W:0,K:1' <<<"$out" || fail=1
  grep -q 'IA_LIVRE_GPU_MULTI_PLACE=Weights' <<<"$out" || fail=1
  grep -q 'IA_LIVRE_GPU_MULTI_PLACE=KvCache' <<<"$out" || fail=1
  # Anti-fraude: não aceitar EXEC_OK com skip
  if grep -q 'IA_LIVRE_GPU_MULTI_SKIP' <<<"$out"; then
    echo "GATE_FAIL: EXEC_OK + SKIP"
    fail=1
  fi
  devices="$(grep -oE 'IA_LIVRE_GPU_DEVICES=[0-9]+' <<<"$out" | head -1 | cut -d= -f2 || echo 0)"
  if [[ "${devices:-0}" -lt 2 ]]; then
    echo "GATE_FAIL: EXEC_OK com DEVICES<2 (fraude)"
    fail=1
  fi
  if (( fail == 0 )); then
    echo "GATE_OK: gpu-multi — host_multi Weights+Kv EXEC_OK (E69; ≠ shard E41)"
    exit 0
  fi
else
  grep -q 'IA_LIVRE_GPU_MULTI_SKIP' <<<"$out" || fail=1
  grep -qE 'IA_LIVRE_GPU_MULTI_SKIP_REASON=(need_2_devices|no_gpu|forced)' <<<"$out" || fail=1
  if (( fail == 0 )); then
    echo "GATE_OK: gpu-multi — skip honesto (E69; ≠ MULTI_EXEC_OK fingido)"
    exit 0
  fi
fi

exit 1
